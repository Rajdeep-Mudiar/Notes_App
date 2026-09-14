import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/exams/models/exam_model.dart';

class ExamRepository {
  final ApiClient _apiClient;

  ExamRepository(this._apiClient);

  Future<ExamListResponseModel> getExams({
    String? subjectId,
    String? examType,
    bool? isUpcoming,
    String? search,
    int limit = 100,
    int skip = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'skip': skip,
    };
    if (subjectId != null) queryParams['subject_id'] = subjectId;
    if (examType != null) queryParams['exam_type'] = examType;
    if (isUpcoming != null) queryParams['is_upcoming'] = isUpcoming;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _apiClient.get(
      ApiEndpoints.exams,
      queryParameters: queryParams,
    );

    final data = response['data'] as Map<String, dynamic>;
    return ExamListResponseModel.fromJson(data);
  }

  Future<List<ExamModel>> getUpcomingExams({int limit = 5}) async {
    final response = await _apiClient.get(
      ApiEndpoints.examsUpcoming,
      queryParameters: {'limit': limit},
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((item) => ExamModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ExamCalendarResponseModel> getCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toUtc().toIso8601String();
    }

    final response = await _apiClient.get(
      ApiEndpoints.examsCalendar,
      queryParameters: queryParams,
    );

    final data = response['data'] as Map<String, dynamic>;
    return ExamCalendarResponseModel.fromJson(data);
  }

  Future<ExamModel> getExamById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.examById(id));
    final data = response['data'] as Map<String, dynamic>;
    return ExamModel.fromJson(data);
  }

  Future<ExamModel> createExam({
    required String title,
    String? subjectId,
    ExamTypeEnum examType = ExamTypeEnum.midterm,
    required DateTime dateTime,
    int durationMinutes = 60,
    String location = '',
    String? seatNumber,
    List<String> syllabusTopics = const [],
    double? weightPercentage,
    double? targetGrade,
    double? actualGrade,
    String notes = '',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.exams,
      data: {
        'title': title.trim(),
        'subject_id': subjectId,
        'exam_type': examType.value,
        'date_time': dateTime.toIso8601String(),
        'duration_minutes': durationMinutes,
        'location': location.trim(),
        'seat_number': seatNumber?.trim(),
        'syllabus_topics': syllabusTopics,
        'weight_percentage': weightPercentage,
        'target_grade': targetGrade,
        'actual_grade': actualGrade,
        'notes': notes.trim(),
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return ExamModel.fromJson(data);
  }

  Future<ExamModel> updateExam(
    String id, {
    String? title,
    String? subjectId,
    ExamTypeEnum? examType,
    DateTime? dateTime,
    int? durationMinutes,
    String? location,
    String? seatNumber,
    List<String>? syllabusTopics,
    double? weightPercentage,
    double? targetGrade,
    double? actualGrade,
    String? notes,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title.trim();
    if (subjectId != null) payload['subject_id'] = subjectId;
    if (examType != null) payload['exam_type'] = examType.value;
    if (dateTime != null) payload['date_time'] = dateTime.toIso8601String();
    if (durationMinutes != null) payload['duration_minutes'] = durationMinutes;
    if (location != null) payload['location'] = location.trim();
    if (seatNumber != null) payload['seat_number'] = seatNumber.trim();
    if (syllabusTopics != null) payload['syllabus_topics'] = syllabusTopics;
    if (weightPercentage != null) payload['weight_percentage'] = weightPercentage;
    if (targetGrade != null) payload['target_grade'] = targetGrade;
    if (actualGrade != null) payload['actual_grade'] = actualGrade;
    if (notes != null) payload['notes'] = notes.trim();

    final response = await _apiClient.put(
      ApiEndpoints.examById(id),
      data: payload,
    );

    final data = response['data'] as Map<String, dynamic>;
    return ExamModel.fromJson(data);
  }

  Future<bool> deleteExam(String id) async {
    final response = await _apiClient.delete(ApiEndpoints.examById(id));
    return response['success'] as bool? ?? true;
  }
}
