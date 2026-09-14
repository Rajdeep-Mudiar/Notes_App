import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/exams/models/exam_model.dart';
import 'package:frontend/features/exams/repositories/exam_repository.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

// Repository Provider
final examRepositoryProvider = Provider<ExamRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExamRepository(apiClient);
});

// Filter & Selection Providers
final examSubjectFilterProvider = StateProvider<String?>((ref) => null);
final examTypeFilterProvider = StateProvider<ExamTypeEnum?>((ref) => null);
final examIsUpcomingFilterProvider = StateProvider<bool?>((ref) => null);
final examSearchQueryProvider = StateProvider<String>((ref) => '');

final selectedCalendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// Exams List Notifier
class ExamsNotifier extends StateNotifier<AsyncValue<ExamListResponseModel>> {
  final ExamRepository _repository;
  final Ref _ref;

  ExamsNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadExams();
  }

  Future<void> loadExams() async {
    state = const AsyncValue.loading();
    try {
      final subjectId = _ref.read(examSubjectFilterProvider);
      final examType = _ref.read(examTypeFilterProvider);
      final isUpcoming = _ref.read(examIsUpcomingFilterProvider);
      final search = _ref.read(examSearchQueryProvider);

      final result = await _repository.getExams(
        subjectId: subjectId,
        examType: examType?.value,
        isUpcoming: isUpcoming,
        search: search.isNotEmpty ? search : null,
      );
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
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
    final created = await _repository.createExam(
      title: title,
      subjectId: subjectId,
      examType: examType,
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      location: location,
      seatNumber: seatNumber,
      syllabusTopics: syllabusTopics,
      weightPercentage: weightPercentage,
      targetGrade: targetGrade,
      actualGrade: actualGrade,
      notes: notes,
    );

    await loadExams();
    _ref.invalidate(upcomingExamsProvider);
    _ref.invalidate(examCalendarProvider);
    _ref.invalidate(subjectsProvider);

    return created;
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
    final updated = await _repository.updateExam(
      id,
      title: title,
      subjectId: subjectId,
      examType: examType,
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      location: location,
      seatNumber: seatNumber,
      syllabusTopics: syllabusTopics,
      weightPercentage: weightPercentage,
      targetGrade: targetGrade,
      actualGrade: actualGrade,
      notes: notes,
    );

    await loadExams();
    _ref.invalidate(upcomingExamsProvider);
    _ref.invalidate(examCalendarProvider);
    _ref.invalidate(subjectsProvider);

    return updated;
  }

  Future<void> deleteExam(String id) async {
    try {
      await _repository.deleteExam(id);
      await loadExams();
      _ref.invalidate(upcomingExamsProvider);
      _ref.invalidate(examCalendarProvider);
      _ref.invalidate(subjectsProvider);
    } catch (_) {}
  }
}

final examsProvider = StateNotifierProvider<ExamsNotifier, AsyncValue<ExamListResponseModel>>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return ExamsNotifier(repository, ref);
});

// Upcoming Exams for Dashboard and Countdown Badges
final upcomingExamsProvider = FutureProvider.autoDispose<List<ExamModel>>((ref) async {
  final repository = ref.watch(examRepositoryProvider);
  return await repository.getUpcomingExams(limit: 5);
});

// Unified Study Calendar Provider (combining exams & assignments for the month)
final examCalendarProvider = FutureProvider.autoDispose<ExamCalendarResponseModel>((ref) async {
  final repository = ref.watch(examRepositoryProvider);
  final month = ref.watch(selectedCalendarMonthProvider);

  final startDate = DateTime.utc(month.year, month.month, 1).subtract(const Duration(days: 7));
  final endDate = DateTime.utc(month.year, month.month + 1, 1).add(const Duration(days: 14));

  return await repository.getCalendarEvents(
    startDate: startDate,
    endDate: endDate,
  );
});

// Single Exam Detail Provider
final singleExamProvider = FutureProvider.family<ExamModel, String>((ref, id) async {
  final repository = ref.watch(examRepositoryProvider);
  return await repository.getExamById(id);
});
