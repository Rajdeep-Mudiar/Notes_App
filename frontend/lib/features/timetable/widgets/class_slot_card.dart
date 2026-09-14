import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/timetable/models/timetable_model.dart';
import 'package:frontend/features/timetable/providers/timetable_provider.dart';
import 'package:frontend/features/timetable/widgets/create_edit_slot_dialog.dart';
import 'package:frontend/features/timetable/widgets/log_attendance_dialog.dart';

class ClassSlotCard extends ConsumerWidget {
  final TimetableSlotModel slot;
  final VoidCallback? onTap;

  const ClassSlotCard({
    super.key,
    required this.slot,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = slot.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Color Strip
              Container(
                width: 6,
                color: accentColor,
              ),

              // Card Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Subject Code/Tag, Class Type & Context Menu
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (slot.subjectCode != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: accentColor.withAlpha(60),
                                      ),
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

                                // Class Type Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: slot.classType.color.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        slot.classType.icon,
                                        size: 13,
                                        color: slot.classType.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        slot.classType.label,
                                        style: TextStyle(
                                          color: slot.classType.color,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // More Options Popup Menu
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              size: 20,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (val) async {
                              if (val == 'edit') {
                                showDialog(
                                  context: context,
                                  builder: (_) => CreateEditSlotDialog(slot: slot),
                                );
                              } else if (val == 'log') {
                                showDialog(
                                  context: context,
                                  builder: (_) => LogAttendanceDialog(slot: slot),
                                );
                              } else if (val == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Class Slot'),
                                    content: Text('Are you sure you want to delete ${slot.title}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(timetableControllerProvider.notifier).deleteSlot(slot.id);
                                }
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'log',
                                child: Row(
                                  children: [
                                    Icon(Icons.how_to_reg_outlined, size: 18, color: Color(0xFF10B981)),
                                    SizedBox(width: 8),
                                    Text('Log Attendance'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit Slot'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Title
                      Text(
                        slot.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),

                      if (slot.subjectName != null && slot.subjectName != slot.title) ...[
                        const SizedBox(height: 2),
                        Text(
                          slot.subjectName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Time and Location row
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Time Range
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  slot.timeRangeFormatted,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Location
                          if (slot.location.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.place_outlined,
                                    size: 14,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    slot.location,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Professor
                          if (slot.professorName != null && slot.professorName!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 14,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    slot.professorName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.black87,
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
            ],
          ),
        ),
      ),
    );
  }
}
