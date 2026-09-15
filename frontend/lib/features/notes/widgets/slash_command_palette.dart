import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/notes/models/note_model.dart';

class SlashCommandItem {
  final BlockType type;
  final String title;
  final String description;
  final IconData icon;
  final List<String> keywords;

  const SlashCommandItem({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.keywords,
  });
}

const List<SlashCommandItem> kSlashCommands = [
  SlashCommandItem(
    type: BlockType.paragraph,
    title: 'Text / Paragraph',
    description: 'Plain body text for general note taking',
    icon: Icons.notes_rounded,
    keywords: ['text', 'paragraph', 'p', 'plain', 'body'],
  ),
  SlashCommandItem(
    type: BlockType.heading1,
    title: 'Heading 1',
    description: 'Large top-level section header',
    icon: Icons.format_size_rounded,
    keywords: ['heading 1', 'h1', 'title', 'header 1', 'large'],
  ),
  SlashCommandItem(
    type: BlockType.heading2,
    title: 'Heading 2',
    description: 'Medium subsection header',
    icon: Icons.title_rounded,
    keywords: ['heading 2', 'h2', 'subheading', 'header 2', 'medium'],
  ),
  SlashCommandItem(
    type: BlockType.bulletList,
    title: 'Bulleted List',
    description: 'Simple bulleted list items',
    icon: Icons.format_list_bulleted_rounded,
    keywords: ['bullet', 'list', 'bullets', 'ul', 'points'],
  ),
  SlashCommandItem(
    type: BlockType.checklist,
    title: 'To-Do / Checklist',
    description: 'Interactive checkbox task items',
    icon: Icons.check_box_outlined,
    keywords: ['todo', 'checklist', 'task', 'check', 'done'],
  ),
  SlashCommandItem(
    type: BlockType.code,
    title: 'Code Block',
    description: 'Syntax-friendly code snippet block',
    icon: Icons.code_rounded,
    keywords: ['code', 'python', 'javascript', 'snippet', 'java', 'cpp'],
  ),
  SlashCommandItem(
    type: BlockType.callout,
    title: 'Callout / Key Takeaway',
    description: 'Highlighted card for essential exam tips and definitions',
    icon: Icons.lightbulb_outline_rounded,
    keywords: ['callout', 'quote', 'tip', 'info', 'note', 'alert', 'important'],
  ),
  SlashCommandItem(
    type: BlockType.equation,
    title: 'Math Equation',
    description: 'Mathematical formulas and expressions',
    icon: Icons.functions_rounded,
    keywords: ['math', 'equation', 'formula', 'latex', 'calc'],
  ),
  SlashCommandItem(
    type: BlockType.divider,
    title: 'Divider',
    description: 'Visual separation horizontal rule',
    icon: Icons.horizontal_rule_rounded,
    keywords: ['divider', 'line', 'hr', 'separate'],
  ),
];

class SlashCommandPalette extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<BlockType> onSelect;
  final VoidCallback onDismiss;

  const SlashCommandPalette({
    super.key,
    this.initialQuery = '',
    required this.onSelect,
    required this.onDismiss,
  });

  static Future<BlockType?> show(
    BuildContext context, {
    String initialQuery = '',
  }) {
    return showModalBottomSheet<BlockType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SlashCommandModal(initialQuery: initialQuery),
    );
  }

  @override
  State<SlashCommandPalette> createState() => _SlashCommandPaletteState();
}

class _SlashCommandPaletteState extends State<SlashCommandPalette> {
  late TextEditingController _filterController;
  List<SlashCommandItem> _filtered = kSlashCommands;

  @override
  void initState() {
    super.initState();
    final clean = widget.initialQuery.replaceFirst('/', '').trim().toLowerCase();
    _filterController = TextEditingController(text: clean);
    _applyFilter(clean);
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = kSlashCommands;
      } else {
        _filtered = kSlashCommands.where((item) {
          if (item.title.toLowerCase().contains(q)) return true;
          if (item.description.toLowerCase().contains(q)) return true;
          return item.keywords.any((k) => k.contains(q));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Filter Input
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: TextField(
              controller: _filterController,
              autofocus: true,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Filter components (e.g. heading, bullet, code)...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _applyFilter,
            ),
          ),
          const Divider(height: 1),
          // Commands List
          Flexible(
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No matching block component found for "${_filterController.text}"',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      return ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.icon, color: AppColors.primary, size: 18),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        subtitle: Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        onTap: () => widget.onSelect(item.type),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SlashCommandModal extends StatefulWidget {
  final String initialQuery;
  const _SlashCommandModal({this.initialQuery = ''});

  @override
  State<_SlashCommandModal> createState() => _SlashCommandModalState();
}

class _SlashCommandModalState extends State<_SlashCommandModal> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Insert Block Component',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'Type "/" in text',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SlashCommandPalette(
                initialQuery: widget.initialQuery,
                onSelect: (type) => Navigator.pop(context, type),
                onDismiss: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
