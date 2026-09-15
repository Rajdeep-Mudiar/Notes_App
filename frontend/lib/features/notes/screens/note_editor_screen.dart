import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/notes/models/note_model.dart';
import 'package:frontend/features/notes/providers/notes_provider.dart';
import 'package:frontend/features/notes/widgets/block_item_view.dart';
import 'package:frontend/features/notes/widgets/slash_command_palette.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String? initialSubjectId;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.initialSubjectId,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _tagInputController = TextEditingController();
  String? _selectedSubjectId;
  List<String> _tags = [];
  List<NoteBlockModel> _blocks = [];
  bool _isFavorite = false;
  bool _isPinned = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _noteId;

  @override
  void initState() {
    super.initState();
    _noteId = widget.noteId;
    _selectedSubjectId = widget.initialSubjectId;

    if (_noteId != null && _noteId != 'new') {
      _loadExistingNote(_noteId!);
    } else {
      // Start with a clean initial paragraph block ready for writing
      _blocks = [
        NoteBlockModel(
          id: 'b_${DateTime.now().millisecondsSinceEpoch}_0',
          type: BlockType.paragraph,
          content: '',
          properties: {},
          order: 0,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingNote(String id) async {
    setState(() => _isLoading = true);
    try {
      final note = await ref.read(singleNoteProvider(id).future);
      setState(() {
        _titleController.text = note.title;
        _selectedSubjectId = note.subjectId;
        _tags = List.from(note.tags);
        _blocks = note.blocks.isNotEmpty
            ? List.from(note.blocks)
            : [
                NoteBlockModel(
                  id: 'b_${DateTime.now().millisecondsSinceEpoch}_0',
                  type: BlockType.paragraph,
                  content: '',
                  properties: {},
                  order: 0,
                ),
              ];
        _isFavorite = note.isFavorite;
        _isPinned = note.isPinned;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load note: $e')),
        );
      }
    }
  }

  void _addBlock(BlockType type, [int? insertIndex]) {
    final newBlock = NoteBlockModel(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}_${_blocks.length}',
      type: type,
      content: '',
      properties: type == BlockType.callout
          ? {'type': 'info', 'icon': 'info'}
          : (type == BlockType.code ? {'language': 'python'} : {}),
      order: insertIndex ?? _blocks.length,
    );
    setState(() {
      if (insertIndex != null && insertIndex >= 0 && insertIndex <= _blocks.length) {
        _blocks.insert(insertIndex, newBlock);
      } else {
        _blocks.add(newBlock);
      }
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _handleSlashCommand(int index, String query) async {
    final selectedType = await SlashCommandPalette.show(context, initialQuery: query);
    if (selectedType != null && mounted) {
      setState(() {
        final current = _blocks[index];
        // Clean out slash command trigger from content
        final cleanContent = current.content.replaceAll(RegExp(r'/[a-zA-Z0-9_-]*$'), '').trim();
        _blocks[index] = current.copyWith(
          type: selectedType,
          content: cleanContent,
          properties: selectedType == BlockType.callout
              ? {'type': 'info', 'icon': 'info'}
              : (selectedType == BlockType.code ? {'language': 'python'} : {}),
        );
        _hasUnsavedChanges = true;
      });
    }
  }

  void _moveBlock(int oldIndex, int newIndex) {
    if (newIndex < 0 || newIndex >= _blocks.length) return;
    setState(() {
      final block = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, block);
      _hasUnsavedChanges = true;
    });
  }

  void _deleteBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  void _addTag(String tag) {
    final clean = tag.trim().replaceAll('#', '').toLowerCase();
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() {
        _tags.add(clean);
        _hasUnsavedChanges = true;
      });
      _tagInputController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim().isEmpty ? 'Untitled Note' : _titleController.text.trim();

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(noteRepositoryProvider);
      if (_noteId != null && _noteId != 'new') {
        await repo.updateNote(
          _noteId!,
          title: title,
          subjectId: _selectedSubjectId,
          tags: _tags,
          blocks: _blocks,
          isFavorite: _isFavorite,
          isPinned: _isPinned,
        );
      } else {
        final created = await repo.createNote(
          title: title,
          subjectId: _selectedSubjectId,
          tags: _tags,
          blocks: _blocks,
          isFavorite: _isFavorite,
          isPinned: _isPinned,
        );
        _noteId = created.id;
      }

      ref.invalidate(recentNotesProvider);
      ref.invalidate(notesListProvider);
      ref.read(subjectsProvider.notifier).loadSubjects();

      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_hasUnsavedChanges) {
              _saveNote();
            }
            context.pop();
          },
        ),
        title: Text(
          _noteId != null && _noteId != 'new' ? 'Edit Note' : 'New Note',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Unstar Note' : 'Star Note',
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: _isFavorite ? AppColors.warning : null,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
                _hasUnsavedChanges = true;
              });
            },
          ),
          IconButton(
            tooltip: _isPinned ? 'Unpin' : 'Pin to Top',
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? AppColors.primary : null,
            ),
            onPressed: () {
              setState(() {
                _isPinned = !_isPinned;
                _hasUnsavedChanges = true;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(80, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isSaving ? null : _saveNote,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Note Document
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metadata Controls (Subject & Tags)
                        Row(
                          children: [
                            // Subject Selector
                            Expanded(
                              child: subjectsAsync.when(
                                data: (subjects) {
                                  return DropdownButtonFormField<String?>(
                                    initialValue: _selectedSubjectId,
                                    decoration: InputDecoration(
                                      labelText: 'Subject / Course',
                                      prefixIcon: const Icon(Icons.menu_book_rounded, size: 18),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('No Subject (General Note)'),
                                      ),
                                      ...subjects.map((s) => DropdownMenuItem(
                                            value: s.id,
                                            child: Text('${s.code} — ${s.name}'),
                                          )),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedSubjectId = val;
                                        _hasUnsavedChanges = true;
                                      });
                                    },
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tags Input & Chips
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _tagInputController,
                                decoration: InputDecoration(
                                  hintText: 'Add tag (e.g. #exam, #trees) and press Enter',
                                  prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onSubmitted: _addTag,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_rounded),
                              onPressed: () => _addTag(_tagInputController.text),
                            ),
                          ],
                        ),
                        if (_tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _tags.map((tag) {
                              return Chip(
                                label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                                onDeleted: () => _removeTag(tag),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Note Title Field
                        TextFormField(
                          controller: _titleController,
                          onChanged: (_) => setState(() => _hasUnsavedChanges = true),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Note Title...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const Divider(thickness: 1, color: AppColors.lightBorder),
                        const SizedBox(height: 12),

                        // Ordered Blocks
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: _blocks.length,
                          onReorder: (oldIndex, newIndex) {
                            if (oldIndex < newIndex) newIndex -= 1;
                            _moveBlock(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final block = _blocks[index];
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey(block.id),
                              index: index,
                              child: BlockItemView(
                                block: block,
                                index: index,
                                totalBlocks: _blocks.length,
                                onContentChanged: (newContent) {
                                  _blocks[index] = block.copyWith(content: newContent);
                                  _hasUnsavedChanges = true;
                                },
                                onSlashCommand: (query) => _handleSlashCommand(index, query),
                                onPropertiesChanged: (newProps) {
                                  _blocks[index] = block.copyWith(properties: newProps);
                                  _hasUnsavedChanges = true;
                                },
                                onMoveUp: () => _moveBlock(index, index - 1),
                                onMoveDown: () => _moveBlock(index, index + 1),
                                onDelete: () => _deleteBlock(index),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Subtle Slash Hint
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              'Type  /  anywhere to search and insert components',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Quick Insertion Floating Bottom Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : AppColors.lightBorder,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Slash Menu Trigger
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          '/ Components',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        backgroundColor: AppColors.primary,
                        onPressed: () async {
                          final lastIdx = _blocks.isEmpty ? 0 : _blocks.length - 1;
                          final selectedType = await SlashCommandPalette.show(context);
                          if (selectedType != null) {
                            if (_blocks.isEmpty) {
                              _addBlock(selectedType);
                            } else {
                              _handleSlashCommand(lastIdx, '');
                            }
                          }
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    _buildQuickAddChip(Icons.notes_rounded, 'Text', BlockType.paragraph, isDark),
                    _buildQuickAddChip(Icons.format_size_rounded, 'H1', BlockType.heading1, isDark),
                    _buildQuickAddChip(Icons.title_rounded, 'H2', BlockType.heading2, isDark),
                    _buildQuickAddChip(Icons.check_box_outlined, 'Checklist', BlockType.checklist, isDark),
                    _buildQuickAddChip(Icons.format_list_bulleted_rounded, 'Bullets', BlockType.bulletList, isDark),
                    _buildQuickAddChip(Icons.code_rounded, 'Code', BlockType.code, isDark),
                    _buildQuickAddChip(Icons.lightbulb_outline_rounded, 'Callout', BlockType.callout, isDark),
                    _buildQuickAddChip(Icons.functions_rounded, 'Equation', BlockType.equation, isDark),
                    _buildQuickAddChip(Icons.horizontal_rule_rounded, 'Divider', BlockType.divider, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddChip(IconData icon, String label, BlockType type, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: isDark ? const Color(0xFF93C5FD) : AppColors.primary),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        onPressed: () => _addBlock(type),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
