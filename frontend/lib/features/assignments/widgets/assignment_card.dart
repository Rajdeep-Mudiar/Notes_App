import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/assignments/models/assignment_model.dart';
import 'package:frontend/features/assignments/providers/assignments_provider.dart';
import 'package:frontend/features/assignments/widgets/create_edit_assignment_dialog.dart';

class AssignmentCard extends ConsumerWidget {
  final AssignmentModel assignment;
  final bool isCompact;

  const AssignmentCard({
    super.key,
    required this.assignment,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = assignment.subjectColor != null
        ? _parseColor(assignment.subjectColor!)
        : AppColors.primary;

    final isOverdue = assignment.isOverdue;
    final isCompleted = assignment.isCompleted;

    Color countdownBgColor;
    Color countdownTextColor;

    if (isCompleted) {
      countdownBgColor = AppColors.success.withValues(alpha: 0.12);
      countdownTextColor = AppColors.success;
    } else if (isOverdue) {
      countdownBgColor = AppColors.error.withValues(alpha: 0.15);
      countdownTextColor = AppColors.error;
    } else if (assignment.countdownText.toLowerCase().contains('today') ||
        assignment.countdownText.toLowerCase().contains('hour') ||
        assignment.countdownText.toLowerCase().contains('min')) {
      countdownBgColor = AppColors.warning.withValues(alpha: 0.15);
      countdownTextColor = AppColors.warning;
    } else {
      countdownBgColor = (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05));
      countdownTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue && !isCompleted
              ? AppColors.error.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isOverdue && !isCompleted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openEditDialog(context),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Subject Badge + Priority Badge + Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Subject Pill
                          if (assignment.subjectCode != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: subjectColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: subjectColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                assignment.subjectCode!,
                                style: TextStyle(
                                  color: subjectColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                          // Priority Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: assignment.priority.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  assignment.priority.icon,
                                  size: 12,
                                  color: assignment.priority.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  assignment.priority.label,
                                  style: TextStyle(
                                    color: assignment.priority.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Weight Percentage Pill if present
                    if (assignment.weightPercentage != null && assignment.weightPercentage! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${assignment.weightPercentage!.toStringAsFixed(0)}% weight',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),

                    // More Menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _openEditDialog(context);
                        } else if (val == 'delete') {
                          _confirmDelete(context, ref);
                        } else if (val.startsWith('status_')) {
                          final newStatusStr = val.replaceFirst('status_', '');
                          final newStatus = AssignmentStatus.fromString(newStatusStr);
                          ref.read(assignmentsProvider.notifier).updateStatus(assignment.id, newStatus);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Assignment', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'status_pending',
                          child: Row(
                            children: [
                              Icon(Icons.radio_button_unchecked_rounded, size: 16, color: AssignmentStatus.pending.color),
                              const SizedBox(width: 8),
                              const Text('Set as To-Do', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'status_in_progress',
                          child: Row(
                            children: [
                              Icon(Icons.timelapse_rounded, size: 16, color: AssignmentStatus.inProgress.color),
                              const SizedBox(width: 8),
                              const Text('Set as In Progress', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'status_submitted',
                          child: Row(
                            children: [
                              Icon(Icons.task_alt_rounded, size: 16, color: AssignmentStatus.submitted.color),
                              const SizedBox(width: 8),
                              const Text('Set as Submitted', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'status_graded',
                          child: Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 16, color: AssignmentStatus.graded.color),
                              const SizedBox(width: 8),
                              const Text('Set as Graded', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
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

                const SizedBox(height: 10),

                // Middle row: Checkbox/Status + Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Quick Status Circle
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        // Toggle cycle: pending -> in_progress -> submitted
                        AssignmentStatus nextStatus;
                        if (assignment.status == AssignmentStatus.pending) {
                          nextStatus = AssignmentStatus.inProgress;
                        } else if (assignment.status == AssignmentStatus.inProgress) {
                          nextStatus = AssignmentStatus.submitted;
                        } else {
                          nextStatus = AssignmentStatus.pending;
                        }
                        ref.read(assignmentsProvider.notifier).updateStatus(assignment.id, nextStatus);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          assignment.status == AssignmentStatus.submitted || assignment.status == AssignmentStatus.graded
                              ? Icons.check_circle_rounded
                              : (assignment.status == AssignmentStatus.inProgress
                                  ? Icons.timelapse_rounded
                                  : Icons.radio_button_unchecked_rounded),
                          color: assignment.status.color,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted
                              ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),
                  ],
                ),

                // Description snippet if available & not compact
                if (!isCompact && assignment.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Text(
                      assignment.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Bottom row: Due Date + Countdown badge + Grade badge
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 30),
                        // Calendar icon + Date
                        Icon(
                          Icons.event_outlined,
                          size: 13,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, h:mm a').format(assignment.dueDate.toLocal()),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Countdown badge
                    if (assignment.countdownText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: countdownBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          assignment.countdownText,
                          style: TextStyle(
                            color: countdownTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // Grade Badge if available
                    if (assignment.gradeReceived != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.grade_rounded, size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              '${assignment.gradeReceived!.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => CreateEditAssignmentDialog(assignment: assignment),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "${assignment.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(assignmentsProvider.notifier).deleteAssignment(assignment.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return AppColors.primary;
  }
}
