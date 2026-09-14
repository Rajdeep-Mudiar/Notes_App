import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';
import 'package:frontend/features/timetable/models/timetable_model.dart';
import 'package:frontend/features/timetable/providers/timetable_provider.dart';
import 'package:frontend/features/timetable/widgets/attendance_meter_widget.dart';
import 'package:frontend/features/timetable/widgets/class_slot_card.dart';
import 'package:frontend/features/timetable/widgets/create_edit_slot_dialog.dart';
import 'package:frontend/features/timetable/widgets/log_attendance_dialog.dart';
import 'package:frontend/features/timetable/widgets/today_schedule_card.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Class Schedule & Timetable',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.how_to_reg_outlined),
            tooltip: 'Record Attendance',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const LogAttendanceDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(timetableSlotsProvider);
              ref.invalidate(weeklyScheduleProvider);
              ref.invalidate(todayScheduleProvider);
              ref.invalidate(attendanceSummaryProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.today_rounded, size: 20), text: "Today's Schedule"),
            Tab(icon: Icon(Icons.view_week_rounded, size: 20), text: "Weekly Timetable"),
            Tab(icon: Icon(Icons.analytics_outlined, size: 20), text: "Attendance Tracker"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(context, isDark),
          _buildWeeklyTab(context, isDark),
          _buildAttendanceTab(context, isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Class Slot'),
        onPressed: () {
          final currentDay = ref.read(selectedTimetableDayProvider);
          showDialog(
            context: context,
            builder: (_) => CreateEditSlotDialog(initialDay: currentDay),
          );
        },
      ),
    );
  }

  // --- 1. Today's Classes Tab ---
  Widget _buildTodayTab(BuildContext context, bool isDark) {
    final todayAsync = ref.watch(todayScheduleProvider);
    final now = DateTime.now();
    final dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    final monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final todayTitle = "${dayNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day}";

    return todayAsync.when(
      data: (classes) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Date Banner
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withAlpha(200),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          classes.isEmpty
                              ? 'No lectures or labs scheduled for today'
                              : '${classes.length} class ${classes.length == 1 ? "session" : "sessions"} scheduled today',
                          style: TextStyle(
                            color: Colors.white.withAlpha(220),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (classes.isEmpty)
              _buildEmptyState(
                icon: Icons.free_breakfast_outlined,
                title: 'No Classes Today!',
                subtitle: 'Enjoy your free day or schedule a session to your timetable.',
                buttonText: '+ Schedule a Class',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const CreateEditSlotDialog(),
                  );
                },
              )
            else
              ...classes.map((c) => TodayScheduleCard(todayClass: c)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading today\'s schedule: $e')),
    );
  }

  // --- 2. Weekly Timetable Tab ---
  Widget _buildWeeklyTab(BuildContext context, bool isDark) {
    final selectedDay = ref.watch(selectedTimetableDayProvider);
    final selectedSubject = ref.watch(selectedTimetableSubjectFilterProvider);
    final slotsAsync = ref.watch(timetableSlotsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Day selector chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: DayOfWeekEnum.values.map((day) {
              final isSelected = selectedDay == day;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(day.label),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) {
                      ref.read(selectedTimetableDayProvider.notifier).state = day;
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Course filter dropdown
        subjectsAsync.when(
          data: (subjects) => Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedSubject,
                  decoration: InputDecoration(
                    labelText: 'Filter by Course',
                    prefixIcon: const Icon(Icons.filter_list_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Courses'),
                    ),
                    ...subjects.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text('${s.code} - ${s.name}'),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    ref.read(selectedTimetableSubjectFilterProvider.notifier).state = val;
                  },
                ),
              ),
              if (selectedSubject != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: 'Clear filter',
                  onPressed: () {
                    ref.read(selectedTimetableSubjectFilterProvider.notifier).state = null;
                  },
                ),
              ],
            ],
          ),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),

        const SizedBox(height: 16),

        // Slots List
        slotsAsync.when(
          data: (slots) {
            if (slots.isEmpty) {
              return _buildEmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No Classes on ${selectedDay.label}',
                subtitle: 'No classes scheduled for this day yet.',
                buttonText: '+ Add Class for ${selectedDay.label}',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CreateEditSlotDialog(initialDay: selectedDay),
                  );
                },
              );
            }
            return Column(
              children: slots.map((s) => ClassSlotCard(slot: s)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(child: Text('Error loading slots: $e')),
        ),
      ],
    );
  }

  // --- 3. Attendance Tracker Tab ---
  Widget _buildAttendanceTab(BuildContext context, bool isDark) {
    final summaryAsync = ref.watch(attendanceSummaryProvider);
    final logsAsync = ref.watch(attendanceLogsProvider);

    return summaryAsync.when(
      data: (summary) {
        final overallPct = summary.overallPercentage;
        final isSafe = overallPct >= summary.minimumRequiredPercentage;
        final statusColor = isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero Metric Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSafe ? statusColor.withAlpha(80) : const Color(0xFFEF4444).withAlpha(120),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withAlpha(25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Radial Gauge simulation
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor.withAlpha(20),
                          border: Border.all(color: statusColor, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            '${overallPct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overall Attendance Health',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSafe
                                  ? 'All good! You are meeting the university 75% minimum criteria.'
                                  : 'Warning: Attendance is below the 75% mandatory threshold.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _heroStat('Attended', summary.overallAttendedClasses.toString(), const Color(0xFF10B981)),
                      _heroStat('Absent', summary.overallAbsentClasses.toString(), const Color(0xFFEF4444)),
                      _heroStat('Total Classes', summary.overallTotalClasses.toString(), AppColors.primary),
                      _heroStat('Critical Courses', summary.criticalSubjectsCount.toString(), summary.criticalSubjectsCount > 0 ? const Color(0xFFEF4444) : Colors.grey),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Subject Attendance Meters
            const Text(
              'Course-Wise Attendance Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (summary.subjectsStats.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('No courses enrolled yet. Create subjects in Subject Hub.'),
                ),
              )
            else
              ...summary.subjectsStats.map((stat) => AttendanceMeterWidget(stats: stat)),

            const SizedBox(height: 24),

            // Recent Logs Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Attendance History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Log Session'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const LogAttendanceDialog(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No attendance records logged yet.')),
                  );
                }
                return Column(
                  children: logs.take(10).map((log) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(log.status.icon, color: log.status.color, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.subjectName ?? 'Class Session',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}${log.notes != null ? " • ${log.notes}" : ""}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: log.status.color.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.status.label,
                              style: TextStyle(
                                color: log.status.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                            onPressed: () async {
                              await ref.read(timetableControllerProvider.notifier).deleteAttendanceLog(log.id);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading attendance summary: $e')),
    );
  }

  Widget _heroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 56, color: Colors.grey.withAlpha(150)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
