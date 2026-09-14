import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/timetable/models/timetable_model.dart';

class TimetableRepository {
  final ApiClient _apiClient;

  TimetableRepository(this._apiClient);

  Future<List<TimetableSlotModel>> getSlots({
    String? dayOfWeek,
    String? subjectId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (dayOfWeek != null) queryParams['day_of_week'] = dayOfWeek;
    if (subjectId != null) queryParams['subject_id'] = subjectId;

    final response = await _apiClient.get(
      ApiEndpoints.timetableSlots,
      queryParameters: queryParams,
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((item) => TimetableSlotModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<TimetableWeeklyModel> getWeeklySchedule() async {
    final response = await _apiClient.get(ApiEndpoints.timetableWeekly);
    final data = response['data'] as Map<String, dynamic>;
    return TimetableWeeklyModel.fromJson(data);
  }

  Future<List<TodayClassModel>> getTodaySchedule({DateTime? customDate}) async {
    final queryParams = <String, dynamic>{};
    if (customDate != null) {
      queryParams['date'] = customDate.toIso8601String().substring(0, 10);
    }

    final response = await _apiClient.get(
      ApiEndpoints.timetableToday,
      queryParameters: queryParams,
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((item) => TodayClassModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<TimetableSlotModel> getSlotById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.timetableSlotById(id));
    final data = response['data'] as Map<String, dynamic>;
    return TimetableSlotModel.fromJson(data);
  }

  Future<TimetableSlotModel> createSlot({
    String? subjectId,
    String? title,
    required DayOfWeekEnum dayOfWeek,
    required String startTime,
    required String endTime,
    ClassTypeEnum classType = ClassTypeEnum.lecture,
    String location = '',
    String? professorName,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.timetableSlots,
      data: {
        'subject_id': subjectId,
        'title': title,
        'day_of_week': dayOfWeek.value,
        'start_time': startTime,
        'end_time': endTime,
        'class_type': classType.value,
        'location': location,
        'professor_name': professorName,
        'notes': notes,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return TimetableSlotModel.fromJson(data);
  }

  Future<TimetableSlotModel> updateSlot({
    required String id,
    String? subjectId,
    String? title,
    DayOfWeekEnum? dayOfWeek,
    String? startTime,
    String? endTime,
    ClassTypeEnum? classType,
    String? location,
    String? professorName,
    String? notes,
  }) async {
    final payload = <String, dynamic>{};
    if (subjectId != null) payload['subject_id'] = subjectId;
    if (title != null) payload['title'] = title;
    if (dayOfWeek != null) payload['day_of_week'] = dayOfWeek.value;
    if (startTime != null) payload['start_time'] = startTime;
    if (endTime != null) payload['end_time'] = endTime;
    if (classType != null) payload['class_type'] = classType.value;
    if (location != null) payload['location'] = location;
    if (professorName != null) payload['professor_name'] = professorName;
    if (notes != null) payload['notes'] = notes;

    final response = await _apiClient.put(
      ApiEndpoints.timetableSlotById(id),
      data: payload,
    );

    final data = response['data'] as Map<String, dynamic>;
    return TimetableSlotModel.fromJson(data);
  }

  Future<void> deleteSlot(String id) async {
    await _apiClient.delete(ApiEndpoints.timetableSlotById(id));
  }

  // --- Attendance Endpoints ---

  Future<AttendanceLogModel> logAttendance({
    String? slotId,
    String? subjectId,
    required DateTime date,
    required AttendanceStatusEnum status,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.attendance,
      data: {
        'slot_id': slotId,
        'subject_id': subjectId,
        'date': date.toIso8601String().substring(0, 10),
        'status': status.value,
        'notes': notes,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return AttendanceLogModel.fromJson(data);
  }

  Future<AttendanceSummaryModel> getAttendanceSummary({double targetPercentage = 75.0}) async {
    final response = await _apiClient.get(
      ApiEndpoints.attendanceSummary,
      queryParameters: {'target_percentage': targetPercentage},
    );

    final data = response['data'] as Map<String, dynamic>;
    return AttendanceSummaryModel.fromJson(data);
  }

  Future<List<AttendanceLogModel>> getAttendanceLogs({
    String? subjectId,
    String? slotId,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (subjectId != null) queryParams['subject_id'] = subjectId;
    if (slotId != null) queryParams['slot_id'] = slotId;

    final response = await _apiClient.get(
      ApiEndpoints.attendanceLogs,
      queryParameters: queryParams,
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((item) => AttendanceLogModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> deleteAttendanceLog(String id) async {
    await _apiClient.delete(ApiEndpoints.attendanceLogById(id));
  }
}
