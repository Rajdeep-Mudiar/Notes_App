import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/notes/models/note_model.dart';

class NoteRepository {
  final ApiClient _apiClient;

  NoteRepository(this._apiClient);

  Future<List<NoteSummaryModel>> getNotes({
    String? subjectId,
    String? tag,
    bool? isFavorite,
    bool? isPinned,
    String? search,
    int limit = 100,
    int skip = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'skip': skip,
    };
    if (subjectId != null) queryParams['subject_id'] = subjectId;
    if (tag != null) queryParams['tag'] = tag;
    if (isFavorite != null) queryParams['is_favorite'] = isFavorite;
    if (isPinned != null) queryParams['is_pinned'] = isPinned;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _apiClient.get(
      ApiEndpoints.notes,
      queryParameters: queryParams,
    );

    final data = response['data'] as Map<String, dynamic>;
    final list = data['notes'] as List<dynamic>? ?? [];
    return list.map((item) => NoteSummaryModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<NoteSummaryModel>> getRecentNotes({int limit = 5}) async {
    final response = await _apiClient.get(
      ApiEndpoints.notesRecent,
      queryParameters: {'limit': limit},
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((item) => NoteSummaryModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<NoteModel> getNoteById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.noteById(id));
    final data = response['data'] as Map<String, dynamic>;
    return NoteModel.fromJson(data);
  }

  Future<NoteModel> createNote({
    required String title,
    String? subjectId,
    List<String> tags = const [],
    String? coverImage,
    String icon = 'article',
    List<NoteBlockModel> blocks = const [],
    bool isFavorite = false,
    bool isPinned = false,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.notes,
      data: {
        'title': title.trim(),
        'subject_id': subjectId,
        'tags': tags,
        'cover_image': coverImage,
        'icon': icon,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'is_favorite': isFavorite,
        'is_pinned': isPinned,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return NoteModel.fromJson(data);
  }

  Future<NoteModel> updateNote(
    String id, {
    String? title,
    String? subjectId,
    List<String>? tags,
    String? coverImage,
    String? icon,
    List<NoteBlockModel>? blocks,
    bool? isFavorite,
    bool? isPinned,
    bool? isArchived,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title.trim();
    if (subjectId != null) payload['subject_id'] = subjectId;
    if (tags != null) payload['tags'] = tags;
    if (coverImage != null) payload['cover_image'] = coverImage;
    if (icon != null) payload['icon'] = icon;
    if (blocks != null) payload['blocks'] = blocks.map((b) => b.toJson()).toList();
    if (isFavorite != null) payload['is_favorite'] = isFavorite;
    if (isPinned != null) payload['is_pinned'] = isPinned;
    if (isArchived != null) payload['is_archived'] = isArchived;

    final response = await _apiClient.put(
      ApiEndpoints.noteById(id),
      data: payload,
    );

    final data = response['data'] as Map<String, dynamic>;
    return NoteModel.fromJson(data);
  }

  Future<bool> deleteNote(String id) async {
    final response = await _apiClient.delete(ApiEndpoints.noteById(id));
    return response['success'] as bool? ?? true;
  }

  Future<NoteModel> toggleFavorite(String id) async {
    final response = await _apiClient.put(ApiEndpoints.noteFavorite(id));
    final data = response['data'] as Map<String, dynamic>;
    return NoteModel.fromJson(data);
  }

  Future<NoteModel> togglePin(String id) async {
    final response = await _apiClient.put(ApiEndpoints.notePin(id));
    final data = response['data'] as Map<String, dynamic>;
    return NoteModel.fromJson(data);
  }
}
