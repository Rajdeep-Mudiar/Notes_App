import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/assignments/models/assignment_model.dart';
import 'package:frontend/features/assignments/providers/assignments_provider.dart';
import 'package:frontend/features/assignments/widgets/assignment_card.dart';
import 'package:frontend/features/assignments/widgets/assignment_kanban_column.dart';
import 'package:frontend/features/assignments/widgets/create_edit_assignment_dialog.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewMode = ref.watch(assignmentViewModeProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final summaryAsync = ref.watch(assignmentSummaryProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    final selectedSubject = ref.watch(assignmentSubjectFilterProvider);
    final selectedPriority = ref.watch(assignmentPriorityFilterProvider);
    final selectedStatus = ref.watch(assignmentStatusFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Header
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
                  // Title + View Switcher + New Assignment Button
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
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.assignment_turned_in_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Academic Planner',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Track coursework deadlines & grades',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          // View Mode Switcher Segmented Button
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _viewButton(
                                  icon: Icons.view_agenda_outlined,
                                  label: 'List',
                                  isSelected: viewMode == AssignmentViewMode.list,
                                  onTap: () {
                                    ref.read(assignmentViewModeProvider.notifier).state =
                                        AssignmentViewMode.list;
                                  },
                                  isDark: isDark,
                                ),
                                _viewButton(
                                  icon: Icons.view_column_outlined,
                                  label: 'Kanban',
                                  isSelected: viewMode == AssignmentViewMode.kanban,
                                  onTap: () {
                                    ref.read(assignmentViewModeProvider.notifier).state =
                                        AssignmentViewMode.kanban;
                                  },
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),

                          // "+ New Assignment" Button
                          FilledButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('New Task'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => const CreateEditAssignmentDialog(),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Summary Metric Strip
                  summaryAsync.when(
                    data: (summary) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _metricPill(
                            label: 'Total Tasks',
                            count: summary.totalAssignments,
                            color: AppColors.primary,
                            icon: Icons.checklist_rounded,
                            isDark: isDark,
                          ),
                          _metricPill(
                            label: 'Due This Week',
                            count: summary.dueThisWeekCount,
                            color: AppColors.warning,
                            icon: Icons.upcoming_rounded,
                            isDark: isDark,
                          ),
                          _metricPill(
                            label: 'Overdue',
                            count: summary.overdueCount,
                            color: AppColors.error,
                            icon: Icons.warning_amber_rounded,
                            isDark: isDark,
                          ),
                          _metricPill(
                            label: 'In Progress',
                            count: summary.inProgressCount,
                            color: const Color(0xFF6366F1),
                            icon: Icons.timelapse_rounded,
                            isDark: isDark,
                          ),
                          _metricPill(
                            label: 'Completed / Graded',
                            count: summary.submittedCount + summary.gradedCount,
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

                  // Filter and Search Row
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              ref.read(assignmentSearchQueryProvider.notifier).state = val;
                              ref.read(assignmentsProvider.notifier).loadAssignments();
                            },
                            decoration: InputDecoration(
                              hintText: 'Search assignments...',
                              hintStyle: const TextStyle(fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(assignmentSearchQueryProvider.notifier).state = '';
                                        ref.read(assignmentsProvider.notifier).loadAssignments();
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Subject Filter Dropdown
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
                                ref.read(assignmentSubjectFilterProvider.notifier).state = val;
                                ref.read(assignmentsProvider.notifier).loadAssignments();
                              },
                            ),
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Priority Filter Dropdown
                      SizedBox(
                        height: 38,
                        width: 130,
                        child: DropdownButtonFormField<AssignmentPriority?>(
                          initialValue: selectedPriority,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: [
                            const DropdownMenuItem<AssignmentPriority?>(
                              value: null,
                              child: Text('All Priority', style: TextStyle(fontSize: 13)),
                            ),
                            ...AssignmentPriority.values.map(
                              (p) => DropdownMenuItem<AssignmentPriority?>(
                                value: p,
                                child: Row(
                                  children: [
                                    Icon(p.icon, size: 14, color: p.color),
                                    const SizedBox(width: 6),
                                    Text(p.label, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            ref.read(assignmentPriorityFilterProvider.notifier).state = val;
                            ref.read(assignmentsProvider.notifier).loadAssignments();
                          },
                        ),
                      ),

                      // Status Filter (only relevant in List mode)
                      if (viewMode == AssignmentViewMode.list) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 38,
                          width: 130,
                          child: DropdownButtonFormField<AssignmentStatus?>(
                            initialValue: selectedStatus,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: [
                              const DropdownMenuItem<AssignmentStatus?>(
                                value: null,
                                child: Text('All Status', style: TextStyle(fontSize: 13)),
                              ),
                              ...AssignmentStatus.values.map(
                                (s) => DropdownMenuItem<AssignmentStatus?>(
                                  value: s,
                                  child: Row(
                                    children: [
                                      Icon(s.icon, size: 14, color: s.color),
                                      const SizedBox(width: 6),
                                      Text(s.label, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              ref.read(assignmentStatusFilterProvider.notifier).state = val;
                              ref.read(assignmentsProvider.notifier).loadAssignments();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: assignmentsAsync.when(
                data: (data) {
                  if (data.items.isEmpty) {
                    return _buildEmptyState(context, isDark);
                  }

                  if (viewMode == AssignmentViewMode.kanban) {
                    return _buildKanbanBoard(data.items);
                  } else {
                    return _buildListView(data.items);
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text('Error loading assignments: $err'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.read(assignmentsProvider.notifier).loadAssignments(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildListView(List<AssignmentModel> items) {
    return RefreshIndicator(
      onRefresh: () => ref.read(assignmentsProvider.notifier).loadAssignments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return AssignmentCard(assignment: items[index]);
        },
      ),
    );
  }

  Widget _buildKanbanBoard(List<AssignmentModel> items) {
    final todoItems = items.where((i) => i.status == AssignmentStatus.pending).toList();
    final inProgressItems = items.where((i) => i.status == AssignmentStatus.inProgress).toList();
    final submittedItems = items.where((i) => i.status == AssignmentStatus.submitted).toList();
    final gradedItems = items.where((i) => i.status == AssignmentStatus.graded).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AssignmentKanbanColumn(status: AssignmentStatus.pending, items: todoItems),
            AssignmentKanbanColumn(status: AssignmentStatus.inProgress, items: inProgressItems),
            AssignmentKanbanColumn(status: AssignmentStatus.submitted, items: submittedItems),
            AssignmentKanbanColumn(status: AssignmentStatus.graded, items: gradedItems),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Assignments Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Stay ahead of coursework deadlines and manage semester workloads.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add First Assignment'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const CreateEditAssignmentDialog(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
