import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/ai/models/ai_model.dart';

class AiRepository {
  final ApiClient _apiClient;

  AiRepository(this._apiClient);

  Future<ChatResponseModel> sendMessage(
    String message, {
    String? subjectId,
    String? sessionId,
    List<ChatMessageModel> history = const [],
  }) async {
    final payload = {
      'message': message,
      if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId,
      if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      'history': history.map((h) => h.toJson()).toList(),
    };

    final response = await _apiClient.post(
      ApiEndpoints.aiChat,
      data: payload,
    );
    final data = (response['data'] is Map<String, dynamic> ? response['data'] : response) as Map<String, dynamic>;
    return ChatResponseModel.fromJson(data);
  }

  Future<QuizResponseModel> generateQuiz({
    String? subjectId,
    int numQuestions = 5,
    String? topic,
  }) async {
    final payload = {
      if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId,
      'num_questions': numQuestions,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
    };

    final response = await _apiClient.post(
      ApiEndpoints.aiGenerateQuiz,
      data: payload,
    );
    final data = (response['data'] is Map<String, dynamic> ? response['data'] : response) as Map<String, dynamic>;
    return QuizResponseModel.fromJson(data);
  }

  Future<FlashcardResponseModel> generateFlashcards({
    String? subjectId,
    int numCards = 6,
    String? topic,
  }) async {
    final payload = {
      if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId,
      'num_cards': numCards,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
    };

    final response = await _apiClient.post(
      ApiEndpoints.aiGenerateFlashcards,
      data: payload,
    );
    final data = (response['data'] is Map<String, dynamic> ? response['data'] : response) as Map<String, dynamic>;
    return FlashcardResponseModel.fromJson(data);
  }

  Future<SummaryResponseModel> generateSummary({
    String? subjectId,
    String? topic,
    List<String>? focusAreas,
  }) async {
    final payload = {
      if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
      if (focusAreas != null) 'focus_areas': focusAreas,
    };

    final response = await _apiClient.post(
      ApiEndpoints.aiSummarize,
      data: payload,
    );
    final data = (response['data'] is Map<String, dynamic> ? response['data'] : response) as Map<String, dynamic>;
    return SummaryResponseModel.fromJson(data);
  }

  Future<ConversationListResponseModel> getConversations({int limit = 30}) async {
    final response = await _apiClient.get(
      ApiEndpoints.aiConversations,
      queryParameters: {'limit': limit},
    );
    final data = (response['data'] is Map<String, dynamic> ? response['data'] : response) as Map<String, dynamic>;
    return ConversationListResponseModel.fromJson(data);
  }

  Future<bool> deleteConversation(String sessionId) async {
    await _apiClient.delete(ApiEndpoints.aiConversationById(sessionId));
    return true;
  }
}
