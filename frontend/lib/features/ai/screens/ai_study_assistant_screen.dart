import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/ai/models/ai_model.dart';
import 'package:frontend/features/ai/providers/ai_provider.dart';
import 'package:frontend/features/ai/widgets/citation_chip_widget.dart';
import 'package:frontend/features/ai/widgets/flashcards_view_widget.dart';
import 'package:frontend/features/ai/widgets/practice_quiz_widget.dart';
import 'package:frontend/features/ai/widgets/revision_summary_widget.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

class AiStudyAssistantScreen extends ConsumerStatefulWidget {
  const AiStudyAssistantScreen({super.key});

  @override
  ConsumerState<AiStudyAssistantScreen> createState() => _AiStudyAssistantScreenState();
}

class _AiStudyAssistantScreenState extends ConsumerState<AiStudyAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(aiStudyControllerProvider.notifier).sendChatMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(aiStudyModeProvider);
    final selectedSubjectId = ref.watch(selectedAiSubjectIdProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final controllerState = ref.watch(aiStudyControllerProvider);
    final isLoading = controllerState.isLoading;

    final chatMessages = ref.watch(chatMessagesProvider);
    final generatedQuiz = ref.watch(generatedQuizProvider);
    final generatedFlashcards = ref.watch(generatedFlashcardsProvider);
    final generatedSummary = ref.watch(generatedSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'AI Assistant',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Subject Filter Selector
          subjectsAsync.when(
            data: (subjects) => Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: selectedSubjectId,
                  hint: const Text('All Courses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Courses', style: TextStyle(fontSize: 12)),
                    ),
                    ...subjects.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text(s.code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    ref.read(selectedAiSubjectIdProvider.notifier).state = val;
                  },
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          IconButton(
            tooltip: 'New Chat Session',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () {
              ref.read(aiStudyControllerProvider.notifier).startNewSession();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Top Study Mode Switcher Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              child: Row(
                children: StudyModeEnum.values.map((mode) {
                  final isSelected = currentMode == mode;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          ref.read(aiStudyModeProvider.notifier).state = mode;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? mode.color.withValues(alpha: 0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? mode.color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                mode.icon,
                                size: 18,
                                color: isSelected ? mode.color : Colors.grey,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                mode.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? mode.color : Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Main Content Area based on Study Mode
            Expanded(
              child: _buildModeContent(
                context: context,
                mode: currentMode,
                isLoading: isLoading,
                chatMessages: chatMessages,
                quiz: generatedQuiz,
                flashcards: generatedFlashcards,
                summary: generatedSummary,
                isDark: isDark,
              ),
            ),

            // Bottom Input Bar for Chat Mode
            if (currentMode == StudyModeEnum.chat)
              _buildChatInputBar(context, isLoading, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildModeContent({
    required BuildContext context,
    required StudyModeEnum mode,
    required bool isLoading,
    required List<ChatMessageModel> chatMessages,
    required QuizResponseModel? quiz,
    required FlashcardResponseModel? flashcards,
    required SummaryResponseModel? summary,
    required bool isDark,
  }) {
    switch (mode) {
      case StudyModeEnum.chat:
        return _buildChatStream(context, chatMessages, isLoading, isDark);
      case StudyModeEnum.quiz:
        if (quiz != null) {
          return PracticeQuizWidget(quiz: quiz);
        }
        return _buildStarterCard(
          context,
          title: 'Generate Practice Quiz',
          subtitle: 'Create multiple-choice test questions from your enrolled course notes and lecture slides.',
          icon: Icons.quiz_outlined,
          color: const Color(0xFF0EA5E9),
          buttonText: 'Generate Practice Quiz',
          onTap: () {
            ref.read(aiStudyControllerProvider.notifier).generateQuiz();
          },
          isLoading: isLoading,
        );
      case StudyModeEnum.flashcards:
        if (flashcards != null) {
          return FlashcardsViewWidget(deck: flashcards);
        }
        return _buildStarterCard(
          context,
          title: 'Generate Flashcard Deck',
          subtitle: 'Extract high-yield key terms, formulas, and definitions into interactive flip cards.',
          icon: Icons.style_outlined,
          color: const Color(0xFFF59E0B),
          buttonText: 'Generate Flashcards',
          onTap: () {
            ref.read(aiStudyControllerProvider.notifier).generateFlashcards();
          },
          isLoading: isLoading,
        );
      case StudyModeEnum.summary:
        if (summary != null) {
          return RevisionSummaryWidget(summary: summary);
        }
        return _buildStarterCard(
          context,
          title: 'Generate Revision Cheat Sheet',
          subtitle: 'Synthesize syllabus overview, core formulas, and high-yield exam tips across course materials.',
          icon: Icons.auto_stories_outlined,
          color: const Color(0xFF10B981),
          buttonText: 'Generate Exam Summary',
          onTap: () {
            ref.read(aiStudyControllerProvider.notifier).generateSummary();
          },
          isLoading: isLoading,
        );
    }
  }

  Widget _buildChatStream(
    BuildContext context,
    List<ChatMessageModel> messages,
    bool isLoading,
    bool isDark,
  ) {
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'How can I help you study today?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask questions grounded directly in your uploaded lecture slides, notes, and course files.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildPromptSuggestion('Explain the core concepts from recent notes'),
                  _buildPromptSuggestion('What are the key formulas for my upcoming exam?'),
                  _buildPromptSuggestion('Summarize differences between algorithms'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isLoading) {
          return _buildLoadingBubble(isDark);
        }
        final msg = messages[index];
        return _buildMessageBubble(context, msg, isDark);
      },
    );
  }

  Widget _buildPromptSuggestion(String text) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        _textController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessageModel msg, bool isDark) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.content,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ),
      );
    }

    // Assistant response with citations
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Notoo AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6366F1)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              msg.content,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            if (msg.citations.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Sources & Grounding:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Wrap(
                children: msg.citations.asMap().entries.map((e) => CitationChipWidget(
                  citation: e.value,
                  index: e.key + 1,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
            ),
            SizedBox(width: 10),
            Text('Synthesizing grounded answer...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String buttonText,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: isLoading ? null : onTap,
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(isLoading ? 'Generating...' : buttonText),
                  style: FilledButton.styleFrom(backgroundColor: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatInputBar(BuildContext context, bool isLoading, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ask a question about your course materials...',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isLoading ? null : _sendMessage,
            icon: const Icon(Icons.send_rounded, size: 18),
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
