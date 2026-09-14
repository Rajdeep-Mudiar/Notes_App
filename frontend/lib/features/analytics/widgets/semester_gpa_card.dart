import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/analytics/models/analytics_model.dart';
import 'package:frontend/features/analytics/widgets/update_grade_dialog.dart';

class SemesterGpaCard extends StatefulWidget {
  final SemesterGpaModel semester;
  final bool initiallyExpanded;

  const SemesterGpaCard({
    super.key,
    required this.semester,
    this.initiallyExpanded = true,
  });

  @override
  State<SemesterGpaCard> createState() => _SemesterGpaCardState();
}

class _SemesterGpaCardState extends State<SemesterGpaCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  Color _getSgpaColor(double sgpa) {
    if (sgpa >= 3.5) return const Color(0xFF10B981);
    if (sgpa >= 3.0) return const Color(0xFF3B82F6);
    if (sgpa >= 2.0) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _parseSubjectColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sgpaColor = _getSgpaColor(widget.semester.sgpa);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header / Summary Row
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.semester.semesterLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.semester.totalCredits} Credits • ${widget.semester.subjects.length} Courses',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.semester.gradedCredits < widget.semester.totalCredits)
                          Text(
                            '(${widget.semester.gradedCredits}/${widget.semester.totalCredits} graded)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // SGPA Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sgpaColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sgpaColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.semester.sgpa.toStringAsFixed(2),
                          style: TextStyle(
                            color: sgpaColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SGPA',
                          style: TextStyle(
                            color: sgpaColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Subjects List
          if (_isExpanded) ...[
            const Divider(height: 1),
            if (widget.semester.subjects.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No subjects enrolled for ${widget.semester.semesterLabel}.',
                  style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.semester.subjects.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
                itemBuilder: (context, index) {
                  final subject = widget.semester.subjects[index];
                  final subColor = _parseSubjectColor(subject.subjectColor);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: subColor,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          subject.subjectCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            subject.subjectName,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          '${subject.credits} Credits',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        if (subject.targetGrade != null)
                          Text(
                            '• Goal: ${subject.targetGrade}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (subject.isGraded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  subject.letterGrade ?? (subject.numericalGrade != null ? '${subject.numericalGrade}%' : 'Graded'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                if (subject.gradePoint != null)
                                  Text(
                                    '${subject.gradePoint!.toStringAsFixed(1)} pts',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'In Progress',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          tooltip: 'Edit Grade',
                          onPressed: () => UpdateGradeDialog.show(context, subject),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
