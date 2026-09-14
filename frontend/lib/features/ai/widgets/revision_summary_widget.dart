import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/ai/models/ai_model.dart';
import 'package:frontend/features/ai/providers/ai_provider.dart';
import 'package:frontend/features/ai/widgets/citation_chip_widget.dart';

class RevisionSummaryWidget extends ConsumerWidget {
  final SummaryResponseModel summary;

  const RevisionSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          summary.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary.overview,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Key Concepts
              _buildSectionCard(
                context,
                title: 'Key Concepts & Definitions',
                icon: Icons.checklist_rounded,
                iconColor: const Color(0xFF6366F1),
                isDark: isDark,
                child: Column(
                  children: summary.keyConcepts.map((c) => _buildCheckItem(context, c, isDark)).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Important Formulas & Code Takeaways
              if (summary.importantFormulasOrTakeaways.isNotEmpty) ...[
                _buildSectionCard(
                  context,
                  title: 'Essential Formulas & Rules',
                  icon: Icons.functions_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  isDark: isDark,
                  child: Column(
                    children: summary.importantFormulasOrTakeaways.map((f) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        f,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Exam Tips
              if (summary.examTips.isNotEmpty) ...[
                _buildSectionCard(
                  context,
                  title: 'High-Yield Exam Tips',
                  icon: Icons.tips_and_updates_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  isDark: isDark,
                  child: Column(
                    children: summary.examTips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Grounded Sources
              if (summary.citations.isNotEmpty) ...[
                Text(
                  'Grounded Source Materials',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  children: summary.citations.asMap().entries.map((e) => CitationChipWidget(
                    citation: e.value,
                    index: e.key + 1,
                  )).toList(),
                ),
                const SizedBox(height: 18),
              ],

              Center(
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(aiStudyControllerProvider.notifier).generateSummary();
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Regenerate Summary'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
