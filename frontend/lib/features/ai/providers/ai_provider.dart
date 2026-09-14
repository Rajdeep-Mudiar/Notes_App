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
final selectedAiSubjectIdProvider = StateProvider<String?>((ref) => null);

// Current chat session ID
final currentAiSessionIdProvider = StateProvider<String?>((ref) => null);

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
  return ChatMessagesNotifier();
});

// Active generated study artifacts
final generatedQuizProvider = StateProvider<QuizResponseModel?>((ref) => null);
final generatedFlashcardsProvider = StateProvider<FlashcardResponseModel?>((ref) => null);
final generatedSummaryProvider = StateProvider<SummaryResponseModel?>((ref) => null);

// Historical AI study sessions list provider
final aiConversationsListProvider = FutureProvider.autoDispose<ConversationListResponseModel>((ref) async {
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
