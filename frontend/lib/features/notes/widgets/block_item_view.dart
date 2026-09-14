import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/notes/models/note_model.dart';

class BlockItemView extends StatelessWidget {
  final NoteBlockModel block;
  final int index;
  final int totalBlocks;
  final ValueChanged<String> onContentChanged;
  final ValueChanged<Map<String, dynamic>> onPropertiesChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;

  const BlockItemView({
    super.key,
    required this.block,
    required this.index,
    required this.totalBlocks,
    required this.onContentChanged,
    required this.onPropertiesChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag / Action Controls
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 4),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.drag_indicator_rounded, size: 18, color: AppColors.lightTextMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onSelected: (val) {
                if (val == 'up') onMoveUp();
                if (val == 'down') onMoveDown();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                if (index > 0)
                  const PopupMenuItem(
                    value: 'up',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Move Up'),
                      ],
                    ),
                  ),
                if (index < totalBlocks - 1)
                  const PopupMenuItem(
                    value: 'down',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Move Down'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete Block', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Block Content View
          Expanded(
            child: _buildBlockBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockBody(BuildContext context) {
    switch (block.type) {
      case BlockType.heading1:
        return TextFormField(
          initialValue: block.content,
          onChanged: onContentChanged,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
          decoration: const InputDecoration(
            hintText: 'Heading 1',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 4),
            filled: false,
          ),
          maxLines: null,
        );

      case BlockType.heading2:
        return TextFormField(
          initialValue: block.content,
          onChanged: onContentChanged,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
          decoration: const InputDecoration(
            hintText: 'Heading 2',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 4),
            filled: false,
          ),
          maxLines: null,
        );

      case BlockType.heading3:
        return TextFormField(
          initialValue: block.content,
          onChanged: onContentChanged,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
          decoration: const InputDecoration(
            hintText: 'Heading 3',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 4),
            filled: false,
          ),
          maxLines: null,
        );

      case BlockType.checklist:
        final isChecked = block.properties['checked'] as bool? ?? false;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isChecked,
              onChanged: (val) {
                final props = Map<String, dynamic>.from(block.properties);
                props['checked'] = val ?? false;
                onPropertiesChanged(props);
              },
            ),
            Expanded(
              child: TextFormField(
                initialValue: block.content,
                onChanged: onContentChanged,
                style: TextStyle(
                  fontSize: 14,
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                  color: isChecked ? AppColors.lightTextMuted : AppColors.lightTextPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'To-do item...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  filled: false,
                ),
                maxLines: null,
              ),
            ),
          ],
        );

      case BlockType.bulletList:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 12, right: 8, left: 4),
              child: Icon(Icons.circle, size: 6, color: AppColors.primary),
            ),
            Expanded(
              child: TextFormField(
                initialValue: block.content,
                onChanged: onContentChanged,
                style: const TextStyle(fontSize: 14, height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'List item...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  filled: false,
                ),
                maxLines: null,
              ),
            ),
          ],
        );

      case BlockType.numberedList:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8, left: 4),
              child: Text(
                '${index + 1}.',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
              ),
            ),
            Expanded(
              child: TextFormField(
                initialValue: block.content,
                onChanged: onContentChanged,
                style: const TextStyle(fontSize: 14, height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'Step...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  filled: false,
                ),
                maxLines: null,
              ),
            ),
          ],
        );

      case BlockType.quote:
        return Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
          ),
          child: TextFormField(
            initialValue: block.content,
            onChanged: onContentChanged,
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.lightTextSecondary),
            decoration: const InputDecoration(
              hintText: 'Quote text...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              filled: false,
            ),
            maxLines: null,
          ),
        );

      case BlockType.callout:
        final type = block.properties['type'] as String? ?? 'info';
        Color calloutColor = AppColors.info;
        IconData calloutIcon = Icons.info_outline_rounded;
        if (type == 'warning') {
          calloutColor = AppColors.warning;
          calloutIcon = Icons.warning_amber_rounded;
        } else if (type == 'tip') {
          calloutColor = AppColors.success;
          calloutIcon = Icons.lightbulb_outline_rounded;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: calloutColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: calloutColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(calloutIcon, color: calloutColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: block.content,
                  onChanged: onContentChanged,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                  decoration: const InputDecoration(
                    hintText: 'Important note or reminder...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                  maxLines: null,
                ),
              ),
            ],
          ),
        );

      case BlockType.code:
        final language = block.properties['language'] as String? ?? 'python';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      language.toUpperCase(),
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.code_rounded, color: Colors.white38, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: block.content,
                onChanged: onContentChanged,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  color: Color(0xFF38BDF8),
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  hintText: '// Enter code snippet here...',
                  hintStyle: TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                maxLines: null,
              ),
            ],
          ),
        );

      case BlockType.equation:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFBCFE8)),
          ),
          child: Row(
            children: [
              const Icon(Icons.functions_rounded, color: Color(0xFFDB2777), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: block.content,
                  onChanged: onContentChanged,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9D174D),
                  ),
                  decoration: const InputDecoration(
                    hintText: r'LaTeX: e.g. T(n) = 2T(n/2) + O(1)',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                ),
              ),
            ],
          ),
        );

      case BlockType.divider:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(thickness: 1.5, color: AppColors.lightBorder),
        );

      case BlockType.paragraph:
      default:
        return TextFormField(
          initialValue: block.content,
          onChanged: onContentChanged,
          style: const TextStyle(fontSize: 14, height: 1.5),
          decoration: const InputDecoration(
            hintText: 'Type something or add blocks...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 4),
            filled: false,
          ),
          maxLines: null,
        );
    }
  }
}
