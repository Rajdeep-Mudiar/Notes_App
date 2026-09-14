import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/exams/models/exam_model.dart';
import 'package:frontend/features/exams/providers/exams_provider.dart';
import 'package:frontend/features/exams/widgets/create_edit_exam_dialog.dart';
import 'package:frontend/features/exams/widgets/exam_card.dart';
import 'package:frontend/features/exams/widgets/study_calendar_widget.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

class ExamsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const ExamsScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final examsAsync = ref.watch(examsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final selectedSubject = ref.watch(examSubjectFilterProvider);
    final selectedType = ref.watch(examTypeFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Title + "+ Schedule Exam" Button
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.event_note_rounded,
                              color: Color(0xFFF59E0B),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Exam Schedule',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Midterms, finals & study calendar',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Schedule Exam'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => const CreateEditExamDialog(),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Summary Metric Strip
                  examsAsync.when(
                    data: (data) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _metricPill(
                            label: 'Total Assessments',
                            count: data.total,
                            color: const Color(0xFFF59E0B),
                            icon: Icons.school_rounded,
                            isDark: isDark,
                          ),
                          _metricPill(
                            label: 'Upcoming Exams',
                            count: data.upcomingCount,
                            color: const Color(0xFF3B82F6),
                            icon: Icons.upcoming_rounded,
                            isDark: isDark,
                          ),
                          _metricPill(
                            label: 'Completed / Graded',
                            count: data.completedCount,
                            color: AppColors.success,
                            icon: Icons.verified_rounded,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox(height: 38),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: 14),

                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: const Color(0xFFF59E0B),
                    labelColor: const Color(0xFFF59E0B),
                    unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Upcoming Exams', icon: Icon(Icons.timer_outlined, size: 16)),
                      Tab(text: 'Study Calendar', icon: Icon(Icons.calendar_month_outlined, size: 16)),
                      Tab(text: 'Completed & Past', icon: Icon(Icons.history_rounded, size: 16)),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Upcoming Exams
                  _buildExamsListTab(
                    context,
                    ref,
                    examsAsync,
                    subjectsAsync,
                    selectedSubject,
                    selectedType,
                    isUpcomingFilter: true,
                    isDark: isDark,
                  ),

                  // Tab 2: Study Calendar
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: StudyCalendarWidget(),
                  ),

                  // Tab 3: Completed & Past Exams
                  _buildExamsListTab(
                    context,
                    ref,
                    examsAsync,
                    subjectsAsync,
                    selectedSubject,
                    selectedType,
                    isUpcomingFilter: false,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsListTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<ExamListResponseModel> examsAsync,
    AsyncValue<List<dynamic>> subjectsAsync,
    String? selectedSubject,
    ExamTypeEnum? selectedType, {
    required bool isUpcomingFilter,
    required bool isDark,
  }) {
    return Column(
      children: [
        // Filter Bar (Search + Course + Type)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // Search Input
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(examSearchQueryProvider.notifier).state = val;
                      ref.read(examsProvider.notifier).loadExams();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search exams...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(examSearchQueryProvider.notifier).state = '';
                                ref.read(examsProvider.notifier).loadExams();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Subject Dropdown
              Expanded(
                flex: 2,
                child: subjectsAsync.when(
                  data: (subjects) => SizedBox(
                    height: 38,
                    child: DropdownButtonFormField<String?>(
                      initialValue: selectedSubject,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Courses', style: TextStyle(fontSize: 13)),
                        ),
                        ...subjects.map((s) => DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text('${s.code} - ${s.name}', style: const TextStyle(fontSize: 13)),
                            )),
                      ],
                      onChanged: (val) {
                        ref.read(examSubjectFilterProvider.notifier).state = val;
                        ref.read(examsProvider.notifier).loadExams();
                      },
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ),
              const SizedBox(width: 10),

              // Exam Type Dropdown
              SizedBox(
                height: 38,
                width: 140,
                child: DropdownButtonFormField<ExamTypeEnum?>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: [
                    const DropdownMenuItem<ExamTypeEnum?>(
                      value: null,
                      child: Text('All Types', style: TextStyle(fontSize: 13)),
                    ),
                    ...ExamTypeEnum.values.map((t) => DropdownMenuItem<ExamTypeEnum?>(
                          value: t,
                          child: Text(t.label, style: const TextStyle(fontSize: 12)),
                        )),
                  ],
                  onChanged: (val) {
                    ref.read(examTypeFilterProvider.notifier).state = val;
                    ref.read(examsProvider.notifier).loadExams();
                  },
                ),
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: examsAsync.when(
            data: (data) {
              final filteredItems = data.items.where((e) {
                if (isUpcomingFilter) {
                  return !e.isCompleted;
                } else {
                  return e.isCompleted;
                }
              }).toList();

              if (filteredItems.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_outlined, size: 48, color: Color(0xFFF59E0B)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isUpcomingFilter ? 'No Upcoming Exams Scheduled' : 'No Completed Exams Found',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isUpcomingFilter
                              ? 'Schedule your midterms, finals, and quizzes to track countdowns & room locations.'
                              : 'Your finished exams, target goals, and score feedback will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (isUpcomingFilter) ...[
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Schedule First Exam'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => const CreateEditExamDialog(),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.read(examsProvider.notifier).loadExams(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    return ExamCard(exam: filteredItems[index]);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading exams: $err')),
          ),
        ),
      ],
    );
  }

  Widget _metricPill({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
