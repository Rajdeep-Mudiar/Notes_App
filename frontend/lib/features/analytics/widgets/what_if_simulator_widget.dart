import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/text_styles.dart';
import 'package:frontend/features/analytics/models/analytics_model.dart';
import 'package:frontend/features/analytics/providers/analytics_provider.dart';

class WhatIfSimulatorWidget extends ConsumerStatefulWidget {
  const WhatIfSimulatorWidget({super.key});

  @override
  ConsumerState<WhatIfSimulatorWidget> createState() => _WhatIfSimulatorWidgetState();
}

class _WhatIfSimulatorWidgetState extends ConsumerState<WhatIfSimulatorWidget> {
  final List<String> _gradeOptions = [
    'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F'
  ];

  void _showAddCourseDialog() {
    final nameController = TextEditingController();
    int credits = 4;
    String grade = 'A';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('Add Simulated Course'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Course Name / Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Machine Learning',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Credits', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            initialValue: credits,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: List.generate(8, (i) => i + 1)
                                .map((c) => DropdownMenuItem(value: c, child: Text('$c cr')))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDlgState(() => credits = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Expected Grade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: grade,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: _gradeOptions
                                .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontWeight: FontWeight.bold))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDlgState(() => grade = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim().isNotEmpty
                      ? nameController.text.trim()
                      : 'Simulated Course';
                  ref.read(analyticsControllerProvider.notifier).addWhatIfCourse(
                        WhatIfCourseInputModel(
                          courseName: name,
                          credits: credits,
                          hypotheticalGrade: grade,
                        ),
                      );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add to Simulator'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final courses = ref.watch(whatIfCoursesProvider);
    final targetCgpa = ref.watch(whatIfTargetCgpaProvider);
    final scenarioAsync = ref.watch(whatIfScenarioResultProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
                  : [const Color(0xFFEEF2FF), const Color(0xFFFDF2F8)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF4338CA) : const Color(0xFFE0E7FF),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predictive Grade & Target GPA Simulator',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Simulate future term grades to forecast your cumulative CGPA and determine what grade points you need to reach honors standing.',
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
        ),
        const SizedBox(height: 20),

        // Target CGPA Solver input
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.flag_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Target Graduation CGPA Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        'Desired cumulative target',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    initialValue: targetCgpa != null ? targetCgpa.toStringAsFixed(2) : '3.80',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val.trim());
                      ref.read(analyticsControllerProvider.notifier).setWhatIfTarget(parsed);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Projection Result Card
        scenarioAsync.when(
          data: (result) {
            if (result == null) return const SizedBox.shrink();

            final isPositive = result.cgpaDifference >= 0;
            final diffColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [Colors.white, const Color(0xFFF8FAFC)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Projected CGPA Outcome', style: AppTextStyles.titleMedium(context)),
                      // Delta Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: diffColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              color: diffColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${isPositive ? "+" : ""}${result.cgpaDifference.toStringAsFixed(2)} CGPA',
                              style: TextStyle(
                                color: diffColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Current vs Projected Comparison Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Baseline CGPA', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                result.baselineCgpa.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Projected CGPA', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                result.projectedCgpa.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Projection advice message banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (result.targetAchieved == true)
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (result.targetAchieved == true) ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: (result.targetAchieved == true) ? const Color(0xFF10B981) : AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.projectionMessage,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: (result.targetAchieved == true) ? const Color(0xFF10B981) : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
          error: (err, _) => Text('Error calculating projection: $err'),
        ),
        const SizedBox(height: 24),

        // Course scenario list
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Simulated Courses (${courses.length})', style: AppTextStyles.titleMedium(context)),
            TextButton.icon(
              onPressed: _showAddCourseDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Course'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (courses.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.playlist_add_rounded, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('No simulated courses added yet.'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showAddCourseDialog,
                    child: const Text('Add a Course'),
                  ),
                ],
              ),
            ),
          )
        else
          for (int index = 0; index < courses.length; index++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courses[index].courseName ?? 'Course ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${courses[index].credits} Credits',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Grade Selector Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: courses[index].hypotheticalGrade,
                        isDense: true,
                        items: _gradeOptions
                            .map((g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (newGrade) {
                          if (newGrade != null) {
                            ref.read(analyticsControllerProvider.notifier).updateWhatIfCourse(
                                  index,
                                  WhatIfCourseInputModel(
                                    courseName: courses[index].courseName,
                                    credits: courses[index].credits,
                                    hypotheticalGrade: newGrade,
                                  ),
                                );
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                    tooltip: 'Remove',
                    onPressed: () {
                      ref.read(analyticsControllerProvider.notifier).removeWhatIfCourse(index);
                    },
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}
