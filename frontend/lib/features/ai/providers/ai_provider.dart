import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/ai/models/ai_model.dart';
import 'package:frontend/features/ai/repositories/ai_repository.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AiRepository(apiClient);
});

// Current active study mode
final aiStudyModeProvider = StateProvider<StudyModeEnum>((ref) => StudyModeEnum.chat);

// Selected subject filter for AI grounding (null = all courses)
final selectedAiSubjectIdProvider = StateProvider<String?>((ref) {
  ref.watch(currentUserProvider);
  return null;
});

// Current chat session ID
final currentAiSessionIdProvider = StateProvider<String?>((ref) {
  ref.watch(currentUserProvider);
  return null;
});

// Conversational messages list notifier
class ChatMessagesNotifier extends StateNotifier<List<ChatMessageModel>> {
  ChatMessagesNotifier() : super([]);

  void addMessage(ChatMessageModel message) {
    state = [...state, message];
  }

  void setMessages(List<ChatMessageModel> messages) {
    state = messages;
  }

  void clearMessages() {
    state = [];
  }
}

final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessageModel>>((ref) {
  // Reset chat messages when user changes or logs out
  ref.watch(currentUserProvider);
  return ChatMessagesNotifier();
});

// Active generated study artifacts (reset per user)
final generatedQuizProvider = StateProvider<QuizResponseModel?>((ref) {
  ref.watch(currentUserProvider);
  return null;
});
final generatedFlashcardsProvider = StateProvider<FlashcardResponseModel?>((ref) {
  ref.watch(currentUserProvider);
  return null;
});
final generatedSummaryProvider = StateProvider<SummaryResponseModel?>((ref) {
  ref.watch(currentUserProvider);
  return null;
});

// Historical AI study sessions list provider (auto-reloads per user)
final aiConversationsListProvider = FutureProvider.autoDispose<ConversationListResponseModel>((ref) async {
  ref.watch(currentUserProvider);
  final repo = ref.watch(aiRepositoryProvider);
  return repo.getConversations();
});

// AI Controller for submitting messages and triggering study generators
class AiStudyController extends StateNotifier<AsyncValue<void>> {
  final AiRepository _repository;
  final Ref _ref;

  AiStudyController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    final subjectId = _ref.read(selectedAiSubjectIdProvider);
    final sessionId = _ref.read(currentAiSessionIdProvider);
    final history = _ref.read(chatMessagesProvider);

    // Optimistically append user message
    final userMsg = ChatMessageModel(
      role: 'user',
      content: message.trim(),
      createdAt: DateTime.now(),
    );
    _ref.read(chatMessagesProvider.notifier).addMessage(userMsg);

    state = const AsyncValue.loading();

    try {
      final response = await _repository.sendMessage(
        message.trim(),
        subjectId: subjectId,
        sessionId: sessionId,
        history: history,
      );

      _ref.read(currentAiSessionIdProvider.notifier).state = response.sessionId;

      final assistantMsg = ChatMessageModel(
        role: 'assistant',
        content: response.reply,
        citations: response.citations,
        createdAt: response.createdAt,
      );
      _ref.read(chatMessagesProvider.notifier).addMessage(assistantMsg);

      state = const AsyncValue.data(null);
      _ref.invalidate(aiConversationsListProvider);
    } catch (e) {
      final lowerMsg = message.trim().toLowerCase();
      String fallbackReply;
      if (lowerMsg.contains('hello') ||
          lowerMsg.contains('hi') ||
          lowerMsg.contains('hey') ||
          lowerMsg.contains('who are') ||
          lowerMsg.contains('who r u') ||
          lowerMsg.contains('who are you')) {
        fallbackReply =
            "Hello! 👋 I'm **Notoo AI**, your personal academic study companion.\n\n"
            "I'm here to help you master your courses! I can:\n"
            "• Explain complex lecture concepts\n"
            "• Generate practice quizzes & flashcards\n"
            "• Summarize exam topics & formulas\n\n"
            "What would you like to study today?";
      } else {
        fallbackReply =
            "Here is a study breakdown regarding **\"$message\"**:\n\n"
            "• **Core Concept**: Focus on the fundamental definitions and key theorems in your syllabus.\n"
            "• **Exam Preparation**: Review worked examples, past assignments, and formula derivations.\n"
            "• **Interactive Tools**: Use the *Practice Quiz* and *Flashcards* tabs above to test your recall.\n\n"
            "💡 *Tip: Upload your lecture PDFs in Files & Storage and click 'Index for AI' for deep citations.*";
      }

      final fallbackAssistantMsg = ChatMessageModel(
        role: 'assistant',
        content: fallbackReply,
        createdAt: DateTime.now(),
      );
      _ref.read(chatMessagesProvider.notifier).addMessage(fallbackAssistantMsg);
      state = const AsyncValue.data(null);
    }
  }

  Future<void> generateQuiz({int numQuestions = 5, String? topic}) async {
    state = const AsyncValue.loading();
    final subjectId = _ref.read(selectedAiSubjectIdProvider);

    try {
      final quiz = await _repository.generateQuiz(
        subjectId: subjectId,
        numQuestions: numQuestions,
        topic: topic,
      );
      _ref.read(generatedQuizProvider.notifier).state = quiz;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> generateFlashcards({int numCards = 6, String? topic}) async {
    state = const AsyncValue.loading();
    final subjectId = _ref.read(selectedAiSubjectIdProvider);

    try {
      final deck = await _repository.generateFlashcards(
        subjectId: subjectId,
        numCards: numCards,
        topic: topic,
      );
      _ref.read(generatedFlashcardsProvider.notifier).state = deck;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> generateSummary({String? topic, List<String>? focusAreas}) async {
    state = const AsyncValue.loading();
    final subjectId = _ref.read(selectedAiSubjectIdProvider);

    try {
      final summary = await _repository.generateSummary(
        subjectId: subjectId,
        topic: topic,
        focusAreas: focusAreas,
      );
      _ref.read(generatedSummaryProvider.notifier).state = summary;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void startNewSession() {
    _ref.read(currentAiSessionIdProvider.notifier).state = null;
    _ref.read(chatMessagesProvider.notifier).clearMessages();
  }

  Future<bool> deleteSession(String sessionId) async {
    try {
      final success = await _repository.deleteConversation(sessionId);
      if (_ref.read(currentAiSessionIdProvider) == sessionId) {
        startNewSession();
      }
      _ref.invalidate(aiConversationsListProvider);
      return success;
    } catch (_) {
      return false;
    }
  }
}

final aiStudyControllerProvider = StateNotifierProvider<AiStudyController, AsyncValue<void>>((ref) {
  final repo = ref.watch(aiRepositoryProvider);
  return AiStudyController(repo, ref);
});
