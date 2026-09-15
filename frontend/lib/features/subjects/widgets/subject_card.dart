import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/subjects/models/subject_model.dart';
import 'package:frontend/shared/widgets/status_badge.dart';

class SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SubjectCard({
    super.key,
    required this.subject,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjectColor = subject.color;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 0 : 1,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Icon + Code + Options Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: subjectColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: subjectColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      subject.iconData,
                      color: subjectColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            StatusBadge(
                              label: subject.code,
                              color: subjectColor,
                              isPill: false,
                            ),
                            Text(
                              '${subject.credits} Credits',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? const Color(0xFFF8FAFC) : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, size: 18, color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextMuted),
                      padding: EdgeInsets.zero,
                      onSelected: (val) {
                        if (val == 'edit' && onEdit != null) onEdit!();
                        if (val == 'delete' && onDelete != null) onDelete!();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Subject', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Middle: Professor & Description
              if (subject.professor.isNotEmpty && subject.professor != 'TBD') ...[
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 14, color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        subject.professor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Bottom Stats Row: Notes, Files & Vault, Assignments Counters
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(context, isDark, Icons.article_outlined, '${subject.notesCount} Notes'),
                    _buildStatDivider(isDark),
                    _buildStatItem(context, isDark, Icons.folder_zip_outlined, '${subject.filesCount} Vault Files'),
                    _buildStatDivider(isDark),
                    _buildStatItem(context, isDark, Icons.assignment_outlined, '${subject.assignmentsCount} Tasks'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, bool isDark, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFCBD5E1) : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 12,
      width: 1,
      color: isDark ? const Color(0xFF334155) : AppColors.lightBorder,
    );
  }
}
