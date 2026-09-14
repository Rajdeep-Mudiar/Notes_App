import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/exams/models/exam_model.dart';
import 'package:frontend/features/exams/providers/exams_provider.dart';
import 'package:frontend/features/exams/widgets/create_edit_exam_dialog.dart';

class ExamCard extends ConsumerWidget {
  final ExamModel exam;
  final bool isCompact;

  const ExamCard({
    super.key,
    required this.exam,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = exam.subjectColor != null
        ? _parseColor(exam.subjectColor!)
        : AppColors.primary;

    final isCompleted = exam.isCompleted;

    Color countdownBgColor;
    Color countdownTextColor;

    if (isCompleted) {
      countdownBgColor = AppColors.success.withValues(alpha: 0.12);
      countdownTextColor = AppColors.success;
    } else if (exam.countdownText.toLowerCase().contains('today') ||
        exam.countdownText.toLowerCase().contains('hour') ||
        exam.countdownText.toLowerCase().contains('mins')) {
      countdownBgColor = AppColors.error.withValues(alpha: 0.15);
      countdownTextColor = AppColors.error;
    } else if (exam.countdownText.toLowerCase().contains('tomorrow') ||
        exam.countdownText.toLowerCase().contains('2 days') ||
        exam.countdownText.toLowerCase().contains('3 days')) {
      countdownBgColor = AppColors.warning.withValues(alpha: 0.15);
      countdownTextColor = AppColors.warning;
    } else {
      countdownBgColor = (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05));
      countdownTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !isCompleted &&
                  (exam.countdownText.toLowerCase().contains('today') ||
                      exam.countdownText.toLowerCase().contains('hour') ||
                      exam.countdownText.toLowerCase().contains('mins'))
              ? AppColors.error.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: !isCompleted && exam.countdownText.toLowerCase().contains('today') ? 1.5 : 1.0,
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
                // Top Row: Type Pill + Subject Pill + Countdown Pill + More Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Exam Type Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: exam.examType.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(exam.examType.icon, size: 13, color: exam.examType.color),
                                const SizedBox(width: 4),
                                Text(
                                  exam.examType.label,
                                  style: TextStyle(
                                    color: exam.examType.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Subject Pill
                          if (exam.subjectCode != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: subjectColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: subjectColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                exam.subjectCode!,
                                style: TextStyle(
                                  color: subjectColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Countdown Badge
                    if (exam.countdownText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: countdownBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exam.countdownText,
                          style: TextStyle(
                            color: countdownTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                    const SizedBox(width: 4),

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
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Exam Details', style: TextStyle(fontSize: 13)),
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

                const SizedBox(height: 10),

                // Title
                Text(
                  exam.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                // Schedule Details: Date & Time + Duration + Location + Seat
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    // Date & Time
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('EEE, MMM d, y • h:mm a').format(exam.dateTime.toLocal()),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Duration
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        const SizedBox(width: 4),
                        Text(
                          exam.formattedDuration,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Location
                    if (exam.location.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.place_outlined, size: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                          const SizedBox(width: 4),
                          Text(
                            exam.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),

                    // Seat Number
                    if (exam.seatNumber != null && exam.seatNumber!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_seat_rounded, size: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Seat: ${exam.seatNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Syllabus Topics Chips
                if (!isCompact && exam.syllabusTopics.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: exam.syllabusTopics.map((topic) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '# $topic',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Grade Banner (Target & Actual)
                if (exam.targetGrade != null || exam.actualGrade != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (exam.targetGrade != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            'Target: ${exam.targetGrade!.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      if (exam.actualGrade != null)
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
                              const Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                'Score: ${exam.actualGrade!.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 11,
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
      builder: (ctx) => CreateEditExamDialog(exam: exam),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam Schedule'),
        content: Text('Are you sure you want to delete "${exam.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(examsProvider.notifier).deleteExam(exam.id);
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
