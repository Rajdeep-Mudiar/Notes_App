import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/timetable/models/timetable_model.dart';
import 'package:frontend/features/timetable/providers/timetable_provider.dart';

class TodayScheduleCard extends ConsumerWidget {
  final TodayClassModel todayClass;

  const TodayScheduleCard({
    super.key,
    required this.todayClass,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final slot = todayClass.slot;
    final accentColor = slot.color;

    Color statusColor;
    IconData statusIcon;
    if (todayClass.isOngoing) {
      statusColor = const Color(0xFF10B981); // Emerald
      statusIcon = Icons.sensors_rounded;
    } else if (todayClass.isUpcoming) {
      statusColor = const Color(0xFFF59E0B); // Amber
      statusIcon = Icons.hourglass_top_rounded;
    } else {
      statusColor = const Color(0xFF6B7280); // Gray
      statusIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: todayClass.isOngoing
              ? statusColor.withAlpha(120)
              : (isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15)),
          width: todayClass.isOngoing ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: todayClass.isOngoing ? statusColor.withAlpha(30) : Colors.black.withAlpha(8),
            blurRadius: todayClass.isOngoing ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status Bar: Live State Tag + Time Range
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                // Live Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        todayClass.timeStatusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time Range
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      slot.timeRangeFormatted,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Middle: Subject Tag, Title, Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slot.subjectCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8, top: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withAlpha(60)),
                    ),
                    child: Text(
                      slot.subjectCode!,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (slot.location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            Text(
                              slot.location,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            if (slot.professorName != null) ...[
                              Text('•', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
                              Text(
                                slot.professorName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Bottom 1-Tap Attendance Marker Bar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  'Mark Attendance:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _attendanceButton(
                      context: context,
                      ref: ref,
                      status: AttendanceStatusEnum.present,
                      currentStatus: todayClass.attendanceToday,
                    ),
                    _attendanceButton(
                      context: context,
                      ref: ref,
                      status: AttendanceStatusEnum.late,
                      currentStatus: todayClass.attendanceToday,
                    ),
                    _attendanceButton(
                      context: context,
                      ref: ref,
                      status: AttendanceStatusEnum.absent,
                      currentStatus: todayClass.attendanceToday,
                    ),
                    _attendanceButton(
                      context: context,
                      ref: ref,
                      status: AttendanceStatusEnum.excused,
                      currentStatus: todayClass.attendanceToday,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceButton({
    required BuildContext context,
    required WidgetRef ref,
    required AttendanceStatusEnum status,
    required AttendanceStatusEnum? currentStatus,
  }) {
    final isSelected = currentStatus == status;
    final color = status.color;

    return InkWell(
      onTap: () async {
        await ref.read(timetableControllerProvider.notifier).logAttendance(
          slotId: todayClass.slot.id,
          subjectId: todayClass.slot.subjectId,
          date: DateTime.now(),
          status: status,
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withAlpha(50),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status.icon,
              size: 13,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
