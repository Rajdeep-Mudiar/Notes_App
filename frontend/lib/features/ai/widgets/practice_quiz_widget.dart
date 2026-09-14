import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/ai/models/ai_model.dart';
import 'package:frontend/features/ai/providers/ai_provider.dart';
import 'package:frontend/features/ai/widgets/citation_chip_widget.dart';

class PracticeQuizWidget extends ConsumerStatefulWidget {
  final QuizResponseModel quiz;

  const PracticeQuizWidget({super.key, required this.quiz});

  @override
  ConsumerState<PracticeQuizWidget> createState() => _PracticeQuizWidgetState();
}

class _PracticeQuizWidgetState extends ConsumerState<PracticeQuizWidget> {
  late List<QuizQuestionModel> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.quiz.questions;
  }

  @override
  void didUpdateWidget(covariant PracticeQuizWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quiz != widget.quiz) {
      _questions = widget.quiz.questions;
    }
  }

  int get _answeredCount => _questions.where((q) => q.isAnswered).length;
  int get _correctCount => _questions.where((q) => q.isCorrect).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiz Header Score Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.quiz.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Answered $_answeredCount of ${_questions.length} questions',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_correctCount / ${_questions.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Questions List
              ..._questions.asMap().entries.map((entry) {
                final idx = entry.key;
                final q = entry.value;
                return _buildQuestionCard(context, index: idx + 1, question: q, isDark: isDark);
              }),

              const SizedBox(height: 16),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        for (var q in _questions) {
                          q.selectedOptionIndex = null;
                        }
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset Answers'),
                  ),
                  const SizedBox(width: 14),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(aiStudyControllerProvider.notifier).generateQuiz();
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('Generate New Quiz'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context, {
    required int index,
    required QuizQuestionModel question,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q$index',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Options List
          ...question.options.asMap().entries.map((optEntry) {
            final optIdx = optEntry.key;
            final optText = optEntry.value;
            final isSelected = question.selectedOptionIndex == optIdx;
            final isCorrect = optIdx == question.correctOptionIndex;

            Color borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
            Color bgColor = Colors.transparent;
            Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

            if (question.isAnswered) {
              if (isCorrect) {
                borderColor = const Color(0xFF10B981);
                bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
                textColor = const Color(0xFF10B981);
              } else if (isSelected && !isCorrect) {
                borderColor = const Color(0xFFEF4444);
                bgColor = const Color(0xFFEF4444).withValues(alpha: 0.12);
                textColor = const Color(0xFFEF4444);
              }
            } else if (isSelected) {
              borderColor = AppColors.primary;
              bgColor = AppColors.primary.withValues(alpha: 0.1);
            }

            final optionLetters = ['A', 'B', 'C', 'D'];
            final letter = optIdx < optionLetters.length ? optionLetters[optIdx] : '${optIdx + 1}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: question.isAnswered
                    ? null
                    : () {
                        setState(() {
                          question.selectedOptionIndex = optIdx;
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: isSelected || (question.isAnswered && isCorrect) ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (question.isAnswered && isCorrect)
                              ? const Color(0xFF10B981)
                              : (question.isAnswered && isSelected && !isCorrect)
                                  ? const Color(0xFFEF4444)
                                  : isDark
                                      ? AppColors.darkSurface
                                      : const Color(0xFFE5E7EB),
                        ),
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: (question.isAnswered && (isCorrect || isSelected))
                                ? Colors.white
                                : isDark
                                    ? Colors.white70
                                    : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          optText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || (question.isAnswered && isCorrect)
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (question.isAnswered && isCorrect)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                      else if (question.isAnswered && isSelected && !isCorrect)
                        const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Explanation & Citation if answered
          if (question.isAnswered) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        question.isCorrect ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                        size: 14,
                        color: question.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        question.isCorrect ? 'Correct!' : 'Explanation',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: question.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.explanation,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (question.citation != null) ...[
                    const SizedBox(height: 8),
                    CitationChipWidget(citation: question.citation!, index: 1),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
