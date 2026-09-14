import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/notes/models/note_model.dart';
import 'package:frontend/shared/widgets/status_badge.dart';

class NoteCard extends StatelessWidget {
  final NoteSummaryModel note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final noteColor = note.color;
    final dateStr = note.updatedAt != null
        ? DateFormat('MMM d, yyyy').format(note.updatedAt!)
        : 'Recent';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar: Subject Chip + Pin/Fav Icons
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (note.subjectCode != null)
                          StatusBadge(
                            label: note.subjectCode!,
                            color: noteColor,
                            isPill: false,
                          ),
                        if (note.isPinned)
                          const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.primary),
                        if (note.isFavorite)
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.lightTextMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Note Title
              Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),

              // Snippet Preview
              if (note.previewSnippet.isNotEmpty) ...[
                Text(
                  note.previewSnippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Tags & Date Footer
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: note.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lightBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(fontSize: 10, color: AppColors.lightTextSecondary),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: AppColors.lightTextMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
