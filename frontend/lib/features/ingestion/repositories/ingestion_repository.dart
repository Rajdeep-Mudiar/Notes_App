import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/ingestion/models/ingestion_model.dart';

class IngestionRepository {
  final ApiClient _apiClient;

  IngestionRepository(this._apiClient);

  Future<IngestionStatusModel> ingestFile(String fileId) async {
    final response = await _apiClient.post(ApiEndpoints.ingestFile(fileId));
    final data = (response['data'] is Map<String, dynamic> ? response['data'] : response) as Map<String, dynamic>;
    return IngestionStatusModel.fromJson(data);
  }

  Future<IngestionStatusModel> ingestNote(String noteId) async {
    final response = await _apiClient.post(ApiEndpoints.ingestNote(noteId));
    final data = (response['data'] is Map<String, dynamic> ? response['data'] : response) as Map<String, dynamic>;
    return IngestionStatusModel.fromJson(data);
  }

  Future<IngestionStatusModel> getIngestionStatus(String sourceId) async {
    final response = await _apiClient.get(ApiEndpoints.ingestionStatus(sourceId));
    final data = (response['data'] is Map<String, dynamic> ? response['data'] : response) as Map<String, dynamic>;
    return IngestionStatusModel.fromJson(data);
  }

  Future<IngestionStatsModel> getIngestionStats() async {
    final response = await _apiClient.get(ApiEndpoints.ingestionStats);
    final data = (response['data'] is Map<String, dynamic> ? response['data'] : response) as Map<String, dynamic>;
    return IngestionStatsModel.fromJson(data);
  }

  Future<bool> deleteSource(String sourceId) async {
    await _apiClient.delete(ApiEndpoints.deleteIngestionSource(sourceId));
    return true;
  }

  Future<SemanticSearchResponseModel> searchSimilarChunks(
    String query, {
    String? subjectId,
    String? sourceId,
    String? sourceType,
    int topK = 5,
  }) async {
    final payload = {
      'query': query,
      'top_k': topK,
      if (subjectId != null) 'subject_id': subjectId,
      if (sourceId != null) 'source_id': sourceId,
      if (sourceType != null) 'source_type': sourceType,
    };

    final response = await _apiClient.post(
      ApiEndpoints.ingestionQuery,
      data: payload,
    );
    final data = (response['data'] is Map<String, dynamic> ? response['data'] : response) as Map<String, dynamic>;
    return SemanticSearchResponseModel.fromJson(data);
  }
}
