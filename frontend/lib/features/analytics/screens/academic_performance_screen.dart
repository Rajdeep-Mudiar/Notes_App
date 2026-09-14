import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/text_styles.dart';
import 'package:frontend/features/analytics/models/analytics_model.dart';
import 'package:frontend/features/analytics/providers/analytics_provider.dart';
import 'package:frontend/features/analytics/widgets/gpa_hero_card.dart';
import 'package:frontend/features/analytics/widgets/semester_gpa_card.dart';
import 'package:frontend/features/analytics/widgets/what_if_simulator_widget.dart';

class AcademicPerformanceScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const AcademicPerformanceScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<AcademicPerformanceScreen> createState() => _AcademicPerformanceScreenState();
}

class _AcademicPerformanceScreenState extends ConsumerState<AcademicPerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    super.dispose();
  }

  void _showGraduationCreditsDialog() {
    final currentCredits = ref.read(graduationRequirementCreditsProvider);
    final controller = TextEditingController(text: currentCredits.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Degree Credit Requirement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the total number of credits required for your degree program (e.g. 120 for 4-year, 160 for engineering/double degree):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Graduation Credits',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed > 0) {
                ref.read(graduationRequirementCreditsProvider.notifier).state = parsed;
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summaryAsync = ref.watch(gpaSummaryProvider);
    final semesterBreakdownAsync = ref.watch(semesterGpaBreakdownProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.insights_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Academic Performance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Degree Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showGraduationCreditsDialog,
          ),
          IconButton(
            tooltip: 'Refresh Analytics',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(gpaSummaryProvider);
              ref.invalidate(semesterGpaBreakdownProvider);
              ref.invalidate(whatIfScenarioResultProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Overview & CGPA'),
            Tab(icon: Icon(Icons.school_rounded), text: 'Semesters'),
            Tab(icon: Icon(Icons.psychology_rounded), text: 'What-If Simulator'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Overview & CGPA
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(gpaSummaryProvider);
              ref.invalidate(semesterGpaBreakdownProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: summaryAsync.when(
                    data: (summary) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GpaHeroCard(summary: summary),
                        const SizedBox(height: 24),

                        // Performance Highlights Metrics
                        Text('Academic Highlights', style: AppTextStyles.titleMedium(context)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                title: 'Highest SGPA',
                                value: summary.highestSgpaSemester != null
                                    ? 'Sem ${summary.highestSgpaSemester}'
                                    : 'N/A',
                                subtitle: 'Best Term Record',
                                icon: Icons.emoji_events_rounded,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                title: 'Enrolled Credits',
                                value: '${summary.totalEnrolledCredits}',
                                subtitle: '${summary.totalEarnedCredits} completed',
                                icon: Icons.fact_check_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                title: 'Total Semesters',
                                value: '${summary.semesterBreakdown.length}',
                                subtitle: 'Terms Enrolled',
                                icon: Icons.calendar_today_rounded,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // GPA Progression Bar Chart / Step Visualizer
                        if (summary.semesterBreakdown.isNotEmpty) ...[
                          Text('GPA Trend Across Semesters', style: AppTextStyles.titleMedium(context)),
                          const SizedBox(height: 12),
                          _buildGpaProgressionWidget(context, summary),
                        ],
                      ],
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('Error loading GPA analytics: $err'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tab 2: Semesters Breakdown
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(semesterGpaBreakdownProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: semesterBreakdownAsync.when(
                    data: (semesters) {
                      if (semesters.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                const Icon(Icons.school_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'No semester grade records found',
                                  style: AppTextStyles.titleMedium(context),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'All Enrolled Semesters (${semesters.length})',
                                style: AppTextStyles.titleMedium(context),
                              ),
                              Text(
                                'Tap course edit icon to update grades',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...semesters.map((sem) => SemesterGpaCard(semester: sem)),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Text('Error: $err'),
                  ),
                ),
              ),
            ),
          ),

          // Tab 3: What-If Simulator
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: const WhatIfSimulatorWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpaProgressionWidget(BuildContext context, GpaSummaryModel summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semesters = summary.semesterBreakdown;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SGPA by Semester', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Overall: ${summary.currentCgpa.toStringAsFixed(2)} CGPA',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: semesters.map((sem) {
              final maxScale = summary.scale == 'percentage'
                  ? 100.0
                  : summary.scale == 'scale_10_0'
                      ? 10.0
                      : 4.0;
              final heightRatio = (sem.sgpa / maxScale).clamp(0.1, 1.0);
              const maxHeight = 120.0;
              final barHeight = maxHeight * heightRatio;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    summary.scale == 'percentage'
                        ? '${sem.sgpa.toStringAsFixed(0)}%'
                        : sem.sgpa.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 38,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sem ${sem.semester}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
