import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/analytics/models/analytics_model.dart';

class AnalyticsRepository {
  final ApiClient _apiClient;

  AnalyticsRepository(this._apiClient);

  Future<GpaSummaryModel> getGpaSummary({
    GradingScale scale = GradingScale.scale40,
    int graduationRequiredCredits = 120,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.gpaSummary,
      queryParameters: {
        'scale': scale.value,
        'graduation_required_credits': graduationRequiredCredits,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return GpaSummaryModel.fromJson(data);
  }

  Future<List<SemesterGpaModel>> getSemesterGpaBreakdown({
    GradingScale scale = GradingScale.scale40,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.gpaSemesters,
      queryParameters: {
        'scale': scale.value,
      },
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((item) => SemesterGpaModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<SubjectGradeModel> updateSubjectGrade(
    String subjectId, {
    String? letterGrade,
    double? numericalGrade,
    String? targetGrade,
    GradingScale scale = GradingScale.scale40,
  }) async {
    final payload = <String, dynamic>{};
    if (letterGrade != null) payload['letter_grade'] = letterGrade;
    if (numericalGrade != null) payload['numerical_grade'] = numericalGrade;
    if (targetGrade != null) payload['target_grade'] = targetGrade;

    final response = await _apiClient.put(
      ApiEndpoints.subjectGrade(subjectId),
      queryParameters: {
        'scale': scale.value,
      },
      data: payload,
    );

    final data = response['data'] as Map<String, dynamic>;
    return SubjectGradeModel.fromJson(data);
  }

  Future<WhatIfScenarioResponseModel> calculateWhatIf({
    required List<WhatIfCourseInputModel> courses,
    double? targetCgpa,
    GradingScale scale = GradingScale.scale40,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.gpaWhatIf,
      data: {
        'courses': courses.map((c) => c.toJson()).toList(),
        if (targetCgpa != null) 'target_cgpa': targetCgpa,
        'scale': scale.value,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return WhatIfScenarioResponseModel.fromJson(data);
  }
}
