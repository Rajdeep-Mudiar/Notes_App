import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/text_styles.dart';
import 'package:frontend/features/analytics/models/analytics_model.dart';
import 'package:frontend/features/analytics/providers/analytics_provider.dart';

class GpaHeroCard extends ConsumerWidget {
  final GpaSummaryModel summary;

  const GpaHeroCard({super.key, required this.summary});

  Color _getGpaColor(double cgpa, String scale) {
    if (scale == 'percentage') {
      if (cgpa >= 85) return const Color(0xFF10B981);
      if (cgpa >= 70) return const Color(0xFF3B82F6);
      if (cgpa >= 55) return const Color(0xFFF59E0B);
      return const Color(0xFFEF4444);
    } else if (scale == 'scale_10_0') {
      if (cgpa >= 8.5) return const Color(0xFF10B981);
      if (cgpa >= 7.0) return const Color(0xFF3B82F6);
      if (cgpa >= 5.5) return const Color(0xFFF59E0B);
      return const Color(0xFFEF4444);
    } else {
      if (cgpa >= 3.5) return const Color(0xFF10B981);
      if (cgpa >= 3.0) return const Color(0xFF3B82F6);
      if (cgpa >= 2.0) return const Color(0xFFF59E0B);
      return const Color(0xFFEF4444);
    }
  }

  String _getMaxScaleLabel(String scale) {
    if (scale == 'percentage') return '100%';
    if (scale == 'scale_10_0') return '10.0';
    return '4.00';
  }

  double _getNormalizedProgress(double cgpa, String scale) {
    if (scale == 'percentage') return (cgpa / 100.0).clamp(0.0, 1.0);
    if (scale == 'scale_10_0') return (cgpa / 10.0).clamp(0.0, 1.0);
    return (cgpa / 4.0).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScale = ref.watch(gradingScaleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gpaColor = _getGpaColor(summary.currentCgpa, summary.scale);
    final normalized = _getNormalizedProgress(summary.currentCgpa, summary.scale);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
              : [const Color(0xFFEEF2FF), const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF312E81) : const Color(0xFFE0E7FF),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with scale switch selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cumulative CGPA',
                            style: AppTextStyles.titleMedium(context).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Weighted Credit Performance',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Scale Selector Popup / Menu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<GradingScale>(
                    value: currentScale,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    items: GradingScale.values.map((scale) {
                      return DropdownMenuItem(
                        value: scale,
                        child: Text(
                          scale == GradingScale.scale40
                              ? '4.0 Scale'
                              : scale == GradingScale.scale100
                                  ? '10.0 Scale'
                                  : 'Percentage',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                    onChanged: (newScale) {
                      if (newScale != null) {
                        ref.read(gradingScaleProvider.notifier).state = newScale;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main CGPA Gauge & Honors Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Gauge / Indicator
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: normalized,
                        strokeWidth: 8,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(gpaColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          summary.scale == 'percentage'
                              ? '${summary.currentCgpa.toStringAsFixed(1)}%'
                              : summary.currentCgpa.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: summary.scale == 'percentage' ? 18 : 22,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'out of ${_getMaxScaleLabel(summary.scale)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Honors Badge & Academic Standing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Honors Standing Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            gpaColor.withValues(alpha: 0.15),
                            gpaColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: gpaColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            summary.honorsStanding.contains('Summa') || summary.honorsStanding.contains('Distinction')
                                ? Icons.workspace_premium_rounded
                                : Icons.star_rounded,
                            color: gpaColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              summary.honorsStanding,
                              style: TextStyle(
                                color: gpaColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Academic Status Tag
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: summary.academicStatus == 'Good Standing'
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Status: ${summary.academicStatus}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${summary.totalEarnedCredits} Earned Credits across ${summary.semesterBreakdown.length} Semesters',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Degree Graduation Credit Meter Progress
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Degree Credit Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${summary.totalEarnedCredits} / ${summary.graduationRequiredCredits} Credits (${summary.creditsProgressPercentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (summary.creditsProgressPercentage / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
