import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/assignments/widgets/create_edit_assignment_dialog.dart';
import 'package:frontend/features/exams/models/exam_model.dart';
import 'package:frontend/features/exams/providers/exams_provider.dart';
import 'package:frontend/features/exams/widgets/create_edit_exam_dialog.dart';

class StudyCalendarWidget extends ConsumerWidget {
  const StudyCalendarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMonth = ref.watch(selectedCalendarMonthProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final calendarAsync = ref.watch(examCalendarProvider);

    return Column(
      children: [
        // Month Navigation Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  ref.read(selectedCalendarMonthProvider.notifier).state =
                      DateTime(currentMonth.year, currentMonth.month - 1, 1);
                },
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(currentMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  ref.read(selectedCalendarMonthProvider.notifier).state =
                      DateTime(currentMonth.year, currentMonth.month + 1, 1);
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final now = DateTime.now();
                  ref.read(selectedCalendarMonthProvider.notifier).state =
                      DateTime(now.year, now.month, 1);
                  ref.read(selectedCalendarDateProvider.notifier).state =
                      DateTime(now.year, now.month, now.day);
                },
                child: const Text('Today', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Calendar Grid + Day Agenda
        Expanded(
          child: calendarAsync.when(
            data: (calendarData) => _buildCalendarBody(
              context,
              ref,
              currentMonth,
              selectedDate,
              calendarData.events,
              isDark,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading calendar: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarBody(
    BuildContext context,
    WidgetRef ref,
    DateTime currentMonth,
    DateTime selectedDate,
    List<CalendarEventItemModel> events,
    bool isDark,
  ) {
    // Calculate calendar grid days
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);

    // Days from previous month to fill the first row
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final daysBefore = startingWeekday;

    final totalDaysInMonth = lastDayOfMonth.day;
    final totalCells = ((daysBefore + totalDaysInMonth + 6) ~/ 7) * 7;

    final gridStart = firstDayOfMonth.subtract(Duration(days: daysBefore));

    // Filter events for selected date
    final selectedDayEvents = events.where((e) {
      final localDt = e.dateTime.toLocal();
      return localDt.year == selectedDate.year &&
          localDt.month == selectedDate.month &&
          localDt.day == selectedDate.day;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Grid (Left)
              Expanded(
                flex: 3,
                child: _buildMonthGrid(
                  context,
                  ref,
                  gridStart,
                  totalCells,
                  currentMonth,
                  selectedDate,
                  events,
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              // Day Agenda (Right)
              Expanded(
                flex: 2,
                child: _buildDayAgenda(context, selectedDate, selectedDayEvents, isDark),
              ),
            ],
          );
        } else {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildMonthGrid(
                  context,
                  ref,
                  gridStart,
                  totalCells,
                  currentMonth,
                  selectedDate,
                  events,
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildDayAgenda(context, selectedDate, selectedDayEvents, isDark),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    WidgetRef ref,
    DateTime gridStart,
    int totalCells,
    DateTime currentMonth,
    DateTime selectedDate,
    List<CalendarEventItemModel> events,
    bool isDark,
  ) {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Weekday Labels Row
          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final cellDate = gridStart.add(Duration(days: index));
              final isCurrentMonth = cellDate.month == currentMonth.month;
              final isToday = cellDate.year == now.year &&
                  cellDate.month == now.month &&
                  cellDate.day == now.day;
              final isSelected = cellDate.year == selectedDate.year &&
                  cellDate.month == selectedDate.month &&
                  cellDate.day == selectedDate.day;

              // Find events on this date
              final dayEvents = events.where((e) {
                final local = e.dateTime.toLocal();
                return local.year == cellDate.year &&
                    local.month == cellDate.month &&
                    local.day == cellDate.day;
              }).toList();

              final hasExam = dayEvents.any((e) => e.isExam);
              final hasAssignment = dayEvents.any((e) => e.isAssignment);

              return InkWell(
                onTap: () {
                  ref.read(selectedCalendarDateProvider.notifier).state = cellDate;
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : (isToday
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isToday ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${cellDate.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isCurrentMonth
                              ? (isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary))
                              : (isDark ? Colors.white24 : Colors.black26),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Event dots row
                      if (dayEvents.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasExam)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B), // Amber for Exams
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (hasAssignment)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6366F1), // Indigo for Tasks
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayAgenda(
    BuildContext context,
    DateTime selectedDate,
    List<CalendarEventItemModel> dayEvents,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & Quick Actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(selectedDate),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${dayEvents.length} event(s) scheduled',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Events list or empty state
          if (dayEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available_rounded, size: 36, color: isDark ? Colors.white24 : Colors.black26),
                    const SizedBox(height: 8),
                    Text(
                      'No exams or deadlines on this day',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Exam', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => CreateEditExamDialog(
                                initialDateTime: selectedDate,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Task', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => CreateEditAssignmentDialog(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: dayEvents.map((ev) => _buildEventTile(context, ev, isDark)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, CalendarEventItemModel ev, bool isDark) {
    final isExam = ev.isExam;
    final color = isExam ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isExam ? Icons.school_rounded : Icons.assignment_turned_in_rounded,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (ev.subjectCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: (ev.subjectColor != null
                                  ? Color(int.parse('FF${ev.subjectColor!.replaceAll('#', '')}', radix: 16))
                                  : AppColors.primary)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ev.subjectCode!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ev.subjectColor != null
                                ? Color(int.parse('FF${ev.subjectColor!.replaceAll('#', '')}', radix: 16))
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isExam ? ev.priorityOrType.toUpperCase() : 'TASK',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('h:mm a').format(ev.dateTime.toLocal()),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  ev.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (ev.locationOrDesc != null && ev.locationOrDesc!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ev.locationOrDesc!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
