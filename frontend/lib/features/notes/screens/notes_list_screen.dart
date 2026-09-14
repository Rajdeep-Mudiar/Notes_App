import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/text_styles.dart';
import 'package:frontend/features/notes/models/note_model.dart';
import 'package:frontend/features/notes/providers/notes_provider.dart';
import 'package:frontend/features/notes/widgets/note_card.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;

  const NotesListScreen({super.key, this.initialSubjectId});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSubjectId != null) {
      Future.microtask(() {
        ref.read(noteSubjectFilterProvider.notifier).state = widget.initialSubjectId;
        ref.read(notesListProvider.notifier).loadNotes();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesListProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final selectedSubject = ref.watch(noteSubjectFilterProvider);
    final onlyFavorites = ref.watch(noteOnlyFavoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & Notebooks', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Create Note',
            icon: const Icon(Icons.note_add_rounded),
            onPressed: () => context.push('/notes/new'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(noteSearchQueryProvider.notifier).state = val.trim();
                  ref.read(notesListProvider.notifier).loadNotes();
                },
                decoration: InputDecoration(
                  hintText: 'Search notes by keyword, tags, or content...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(noteSearchQueryProvider.notifier).state = '';
                            ref.read(notesListProvider.notifier).loadNotes();
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Subject & Favorites Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                        SizedBox(width: 4),
                        Text('Favorites'),
                      ],
                    ),
                    selected: onlyFavorites,
                    onSelected: (val) {
                      ref.read(noteOnlyFavoritesProvider.notifier).state = val;
                      ref.read(notesListProvider.notifier).loadNotes();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('All Courses'),
                    selected: selectedSubject == null,
                    onSelected: (val) {
                      if (val) {
                        ref.read(noteSubjectFilterProvider.notifier).state = null;
                        ref.read(notesListProvider.notifier).loadNotes();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  subjectsAsync.when(
                    data: (subjects) => Row(
                      children: subjects.map((s) {
                        final isSelected = selectedSubject == s.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(s.iconData, size: 14, color: s.color),
                            label: Text(s.code),
                            selected: isSelected,
                            onSelected: (val) {
                              ref.read(noteSubjectFilterProvider.notifier).state = val ? s.id : null;
                              ref.read(notesListProvider.notifier).loadNotes();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Notes Grid
            Expanded(
              child: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(notesListProvider.notifier).loadNotes(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 175,
                          ),
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            return NoteCard(
                              note: note,
                              onTap: () => context.push('/notes/${note.id}'),
                              onDelete: () => _confirmDelete(context, note),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Error loading notes: $err'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(notesListProvider.notifier).loadNotes(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/notes/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('New Note'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.article_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No notes found',
              style: AppTextStyles.headlineMedium(context),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start writing structured lecture notes, code snippets, checklists, and LaTeX formulas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/notes/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Your First Note'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, NoteSummaryModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note?'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notesListProvider.notifier).deleteNote(note.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
