import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/timetable/models/timetable_model.dart';

class AttendanceMeterWidget extends StatelessWidget {
  final SubjectAttendanceStatsModel stats;
  final VoidCallback? onTap;

  const AttendanceMeterWidget({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pct = stats.attendancePercentage;
    final isSafe = !stats.isCritical;
    final statusColor = isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: stats.isCritical
              ? statusColor.withAlpha(120)
              : (isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15)),
          width: stats.isCritical ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Subject Code & Name + Percentage Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stats.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: stats.color.withAlpha(60)),
                  ),
                  child: Text(
                    stats.subjectCode,
                    style: TextStyle(
                      color: stats.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stats.subjectName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withAlpha(80)),
                  ),
                  child: Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  LinearProgressIndicator(
                    value: stats.totalClasses > 0 ? (stats.attendedClasses / stats.totalClasses).clamp(0.0, 1.0) : 1.0,
                    minHeight: 10,
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                  // Threshold Marker Line at 75%
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final markerPos = constraints.maxWidth * 0.75;
                        return Stack(
                          children: [
                            Positioned(
                              left: markerPos,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Safe Bunks vs Recovery classes advice banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSafe ? const Color(0xFF10B981).withAlpha(15) : const Color(0xFFEF4444).withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSafe ? const Color(0xFF10B981).withAlpha(40) : const Color(0xFFEF4444).withAlpha(40),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSafe ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSafe
                          ? (stats.safeBunks > 0
                              ? 'Safe Bunks: You can miss ${stats.safeBunks} more ${stats.safeBunks == 1 ? "class" : "classes"} while staying above 75%.'
                              : 'On Track: On the 75% threshold limit.')
                          : 'Critical: Attend ${stats.classesNeededToTarget} consecutive ${stats.classesNeededToTarget == 1 ? "class" : "classes"} to restore 75% attendance.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white.withAlpha(220) : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Breakdown stats row
            Row(
              children: [
                Expanded(child: _statItem('Attended', stats.attendedClasses.toString(), const Color(0xFF10B981))),
                Expanded(child: _statItem('Absent', stats.absentClasses.toString(), const Color(0xFFEF4444))),
                Expanded(child: _statItem('Late', stats.lateClasses.toString(), const Color(0xFFF59E0B))),
                Expanded(child: _statItem('Total', stats.totalClasses.toString(), AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
