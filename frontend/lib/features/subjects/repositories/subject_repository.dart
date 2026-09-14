import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/subjects/models/subject_model.dart';

class SubjectRepository {
  final ApiClient _apiClient;

  SubjectRepository(this._apiClient);

  Future<List<SubjectModel>> getSubjects({
    int? semester,
    bool includeArchived = false,
  }) async {
    final queryParams = <String, dynamic>{
      'include_archived': includeArchived,
    };
    if (semester != null) {
      queryParams['semester'] = semester;
    }

    final response = await _apiClient.get(
      ApiEndpoints.subjects,
      queryParameters: queryParams,
    );

    final data = response['data'] as Map<String, dynamic>;
    final list = data['subjects'] as List<dynamic>? ?? [];
    return list.map((item) => SubjectModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<SubjectModel> getSubjectById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.subjectById(id));
    final data = response['data'] as Map<String, dynamic>;
    return SubjectModel.fromJson(data);
  }

  Future<SubjectModel> createSubject({
    required String name,
    required String code,
    required String professor,
    required int credits,
    required String color,
    required String icon,
    String description = '',
    required int semester,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.subjects,
      data: {
        'name': name.trim(),
        'code': code.trim().toUpperCase(),
        'professor': professor.trim(),
        'credits': credits,
        'color': color,
        'icon': icon,
        'description': description.trim(),
        'semester': semester,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return SubjectModel.fromJson(data);
  }

  Future<SubjectModel> updateSubject(
    String id, {
    String? name,
    String? code,
    String? professor,
    int? credits,
    String? color,
    String? icon,
    String? description,
    int? semester,
    bool? isArchived,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name.trim();
    if (code != null) payload['code'] = code.trim().toUpperCase();
    if (professor != null) payload['professor'] = professor.trim();
    if (credits != null) payload['credits'] = credits;
    if (color != null) payload['color'] = color;
    if (icon != null) payload['icon'] = icon;
    if (description != null) payload['description'] = description.trim();
    if (semester != null) payload['semester'] = semester;
    if (isArchived != null) payload['is_archived'] = isArchived;

    final response = await _apiClient.put(
      ApiEndpoints.subjectById(id),
      data: payload,
    );

    final data = response['data'] as Map<String, dynamic>;
    return SubjectModel.fromJson(data);
  }

  Future<bool> deleteSubject(String id) async {
    final response = await _apiClient.delete(ApiEndpoints.subjectById(id));
    return response['success'] as bool? ?? true;
  }

  Future<SubjectModel> toggleArchive(String id) async {
    final response = await _apiClient.put(
      ApiEndpoints.subjectArchive(id),
    );
    final data = response['data'] as Map<String, dynamic>;
    return SubjectModel.fromJson(data);
  }

  Future<AcademicSummaryModel> getAcademicSummary() async {
    final response = await _apiClient.get(ApiEndpoints.subjectsSummary);
    final data = response['data'] as Map<String, dynamic>;
    return AcademicSummaryModel.fromJson(data);
  }
}
