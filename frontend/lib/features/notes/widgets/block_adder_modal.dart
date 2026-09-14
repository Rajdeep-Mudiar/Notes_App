import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/notes/models/note_model.dart';

class BlockAdderModal extends StatelessWidget {
  const BlockAdderModal({super.key});

  static Future<BlockType?> show(BuildContext context) {
    return showModalBottomSheet<BlockType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BlockAdderModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Content Block',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose a structured element to add to your study notes.',
              style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 16),

            // Scrollable Block Options
            Expanded(
              child: ListView(
                children: [
                  _buildSectionHeader('BASIC TEXT BLOCKS'),
                  _buildBlockOption(
                    context,
                    type: BlockType.paragraph,
                    title: 'Paragraph',
                    desc: 'Plain text with rich formatting',
                    icon: Icons.notes_rounded,
                    color: AppColors.primary,
                  ),
                  _buildBlockOption(
                    context,
                    type: BlockType.heading1,
                    title: 'Heading 1',
                    desc: 'Large section header (H1)',
                    icon: Icons.format_size_rounded,
                    color: const Color(0xFF4338CA),
                  ),
                  _buildBlockOption(
                    context,
                    type: BlockType.heading2,
                    title: 'Heading 2',
                    desc: 'Medium subsection title (H2)',
                    icon: Icons.title_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                  _buildBlockOption(
                    context,
                    type: BlockType.heading3,
                    title: 'Heading 3',
                    desc: 'Small topic header (H3)',
                    icon: Icons.text_fields_rounded,
                    color: const Color(0xFF818CF8),
                  ),
                  _buildBlockOption(
                    context,
                    type: BlockType.bulletList,
                    title: 'Bulleted List',
                    desc: 'Key takeaways and bullet points',
                    icon: Icons.format_list_bulleted_rounded,
                    color: const Color(0xFF0EA5E9),
                  ),
                  _buildBlockOption(
                    context,
                    type: BlockType.numberedList,
                    title: 'Numbered List',
                    desc: 'Ordered step-by-step procedures',
                    icon: Icons.format_list_numbered_rounded,
                    color: const Color(0xFF0284C7),
                  ),
                  _buildBlockOption(
                    context,
                    type: BlockType.checklist,
                    title: 'Checklist / Todo',
                    desc: 'Action items with toggleable checkboxes',
                    icon: Icons.check_box_outlined,
                    color: AppColors.success,
                  ),
                  _buildBlockOption(
                    context,
                    type: BlockType.quote,
                    title: 'Quote',
                    desc: 'Notable statements or textbook quotes',
                    icon: Icons.format_quote_rounded,
                    color: const Color(0xFF64748B),
                  ),
                  _buildBlockOption(
                    context,
                    type: BlockType.divider,
                    title: 'Divider',
                    desc: 'Visual line separating concepts',
                    icon: Icons.horizontal_rule_rounded,
                    color: AppColors.lightTextMuted,
                  ),

                  _buildSectionHeader('ACADEMIC & TECHNICAL BLOCKS'),
                  _buildBlockOption(
                    context,
                    type: BlockType.callout,
                    title: 'Callout Box',
                    desc: 'Highlighted note, important exam alert or tip',
                    icon: Icons.lightbulb_outline_rounded,
                    color: AppColors.warning,
                  ),
                  _buildBlockOption(
                    context,
                    type: BlockType.code,
                    title: 'Code Snippet',
                    desc: 'Syntax highlighted code (Python, C++, Java, SQL)',
                    icon: Icons.code_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                  _buildBlockOption(
                    context,
                    type: BlockType.equation,
                    title: 'Math Equation',
                    desc: 'Mathematical formula using LaTeX notation',
                    icon: Icons.functions_rounded,
                    color: const Color(0xFFEC4899),
                  ),
                  _buildBlockOption(
                    context,
                    type: BlockType.table,
                    title: 'Table',
                    desc: 'Structured rows and columns for comparisons',
                    icon: Icons.table_chart_outlined,
                    color: const Color(0xFF14B8A6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.lightTextMuted,
        ),
      ),
    );
  }

  Widget _buildBlockOption(
    BuildContext context, {
    required BlockType type,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        desc,
        style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () => Navigator.of(context).pop(type),
    );
  }
}
