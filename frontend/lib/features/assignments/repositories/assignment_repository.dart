import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/assignments/models/assignment_model.dart';

class AssignmentRepository {
  final ApiClient _apiClient;

  AssignmentRepository(this._apiClient);

  Future<AssignmentListResponseModel> getAssignments({
    String? subjectId,
    String? status,
    String? priority,
    String? search,
    int limit = 100,
    int skip = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'skip': skip,
    };
    if (subjectId != null) queryParams['subject_id'] = subjectId;
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _apiClient.get(
      ApiEndpoints.assignments,
      queryParameters: queryParams,
    );

    final data = response['data'] as Map<String, dynamic>;
    return AssignmentListResponseModel.fromJson(data);
  }

  Future<List<AssignmentModel>> getUpcomingAssignments({int limit = 5}) async {
    final response = await _apiClient.get(
      ApiEndpoints.assignmentsUpcoming,
      queryParameters: {'limit': limit},
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((item) => AssignmentModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<AssignmentSummaryModel> getSummary() async {
    final response = await _apiClient.get(ApiEndpoints.assignmentsSummary);
    final data = response['data'] as Map<String, dynamic>;
    return AssignmentSummaryModel.fromJson(data);
  }

  Future<AssignmentModel> getAssignmentById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.assignmentById(id));
    final data = response['data'] as Map<String, dynamic>;
    return AssignmentModel.fromJson(data);
  }

  Future<AssignmentModel> createAssignment({
    required String title,
    String description = '',
    String? subjectId,
    required DateTime dueDate,
    AssignmentPriority priority = AssignmentPriority.medium,
    AssignmentStatus status = AssignmentStatus.pending,
    double? weightPercentage,
    List<String> fileIds = const [],
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.assignments,
      data: {
        'title': title.trim(),
        'description': description.trim(),
        'subject_id': subjectId,
        'due_date': dueDate.toIso8601String(),
        'priority': priority.value,
        'status': status.value,
        'weight_percentage': weightPercentage,
        'file_ids': fileIds,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return AssignmentModel.fromJson(data);
  }

  Future<AssignmentModel> updateAssignment(
    String id, {
    String? title,
    String? description,
    String? subjectId,
    DateTime? dueDate,
    AssignmentPriority? priority,
    AssignmentStatus? status,
    double? weightPercentage,
    double? gradeReceived,
    String? feedback,
    List<String>? fileIds,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title.trim();
    if (description != null) payload['description'] = description.trim();
    if (subjectId != null) payload['subject_id'] = subjectId;
    if (dueDate != null) payload['due_date'] = dueDate.toIso8601String();
    if (priority != null) payload['priority'] = priority.value;
    if (status != null) payload['status'] = status.value;
    if (weightPercentage != null) payload['weight_percentage'] = weightPercentage;
    if (gradeReceived != null) payload['grade_received'] = gradeReceived;
    if (feedback != null) payload['feedback'] = feedback;
    if (fileIds != null) payload['file_ids'] = fileIds;

    final response = await _apiClient.put(
      ApiEndpoints.assignmentById(id),
      data: payload,
    );

    final data = response['data'] as Map<String, dynamic>;
    return AssignmentModel.fromJson(data);
  }

  Future<AssignmentModel> updateStatus(String id, AssignmentStatus status) async {
    final response = await _apiClient.patch(
      ApiEndpoints.assignmentStatus(id),
      data: {'status': status.value},
    );

    final data = response['data'] as Map<String, dynamic>;
    return AssignmentModel.fromJson(data);
  }

  Future<bool> deleteAssignment(String id) async {
    final response = await _apiClient.delete(ApiEndpoints.assignmentById(id));
    return response['success'] as bool? ?? true;
  }
}
