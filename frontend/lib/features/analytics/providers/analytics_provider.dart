import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/analytics/models/analytics_model.dart';
import 'package:frontend/features/analytics/repositories/analytics_repository.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnalyticsRepository(apiClient);
});

// Settings & Config
final gradingScaleProvider = StateProvider<GradingScale>((ref) => GradingScale.scale40);
final graduationRequirementCreditsProvider = StateProvider<int>((ref) => 120);

// GPA Summary Provider
final gpaSummaryProvider = FutureProvider.autoDispose<GpaSummaryModel>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final scale = ref.watch(gradingScaleProvider);
  final targetCredits = ref.watch(graduationRequirementCreditsProvider);

  return repository.getGpaSummary(
    scale: scale,
    graduationRequiredCredits: targetCredits,
  );
});

// Semester Breakdown Provider
final semesterGpaBreakdownProvider = FutureProvider.autoDispose<List<SemesterGpaModel>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final scale = ref.watch(gradingScaleProvider);

  return repository.getSemesterGpaBreakdown(scale: scale);
});

// What-If Scenario State
final whatIfCoursesProvider = StateProvider<List<WhatIfCourseInputModel>>((ref) {
  return [
    WhatIfCourseInputModel(courseName: 'Advanced Algorithms', credits: 4, hypotheticalGrade: 'A'),
    WhatIfCourseInputModel(courseName: 'Operating Systems', credits: 4, hypotheticalGrade: 'A-'),
    WhatIfCourseInputModel(courseName: 'Database Engineering', credits: 3, hypotheticalGrade: 'B+'),
  ];
});

final whatIfTargetCgpaProvider = StateProvider<double?>((ref) => 3.85);

final whatIfScenarioResultProvider = FutureProvider.autoDispose<WhatIfScenarioResponseModel?>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final courses = ref.watch(whatIfCoursesProvider);
  final targetCgpa = ref.watch(whatIfTargetCgpaProvider);
  final scale = ref.watch(gradingScaleProvider);

  if (courses.isEmpty) return null;

  return repository.calculateWhatIf(
    courses: courses,
    targetCgpa: targetCgpa,
    scale: scale,
  );
});

// Analytics Controller for Mutations
class AnalyticsController extends StateNotifier<AsyncValue<void>> {
  final AnalyticsRepository _repository;
  final Ref _ref;

  AnalyticsController(this._repository, this._ref) : super(const AsyncValue.data(null));

  void _invalidateAll() {
    _ref.invalidate(gpaSummaryProvider);
    _ref.invalidate(semesterGpaBreakdownProvider);
    _ref.invalidate(whatIfScenarioResultProvider);
  }

  Future<bool> updateGrade({
    required String subjectId,
    String? letterGrade,
    double? numericalGrade,
    String? targetGrade,
  }) async {
    state = const AsyncValue.loading();
    try {
      final scale = _ref.read(gradingScaleProvider);
      await _repository.updateSubjectGrade(
        subjectId,
        letterGrade: letterGrade,
        numericalGrade: numericalGrade,
        targetGrade: targetGrade,
        scale: scale,
      );
      state = const AsyncValue.data(null);
      _invalidateAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void addWhatIfCourse(WhatIfCourseInputModel course) {
    final current = _ref.read(whatIfCoursesProvider);
    _ref.read(whatIfCoursesProvider.notifier).state = [...current, course];
    _ref.invalidate(whatIfScenarioResultProvider);
  }

  void removeWhatIfCourse(int index) {
    final current = _ref.read(whatIfCoursesProvider);
    if (index >= 0 && index < current.length) {
      final updated = List<WhatIfCourseInputModel>.from(current)..removeAt(index);
      _ref.read(whatIfCoursesProvider.notifier).state = updated;
      _ref.invalidate(whatIfScenarioResultProvider);
    }
  }

  void updateWhatIfCourse(int index, WhatIfCourseInputModel course) {
    final current = _ref.read(whatIfCoursesProvider);
    if (index >= 0 && index < current.length) {
      final updated = List<WhatIfCourseInputModel>.from(current);
      updated[index] = course;
      _ref.read(whatIfCoursesProvider.notifier).state = updated;
      _ref.invalidate(whatIfScenarioResultProvider);
    }
  }

  void setWhatIfTarget(double? target) {
    _ref.read(whatIfTargetCgpaProvider.notifier).state = target;
    _ref.invalidate(whatIfScenarioResultProvider);
  }
}

final analyticsControllerProvider = StateNotifierProvider<AnalyticsController, AsyncValue<void>>((ref) {
  final repository = ref.watch(analyticsRepositoryProvider);
  return AnalyticsController(repository, ref);
});
