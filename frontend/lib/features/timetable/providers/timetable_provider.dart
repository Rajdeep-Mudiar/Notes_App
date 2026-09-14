import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/timetable/models/timetable_model.dart';
import 'package:frontend/features/timetable/repositories/timetable_repository.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TimetableRepository(apiClient);
});

// Filters
final selectedTimetableDayProvider = StateProvider<DayOfWeekEnum>((ref) {
  final weekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
  switch (weekday) {
    case 1:
      return DayOfWeekEnum.monday;
    case 2:
      return DayOfWeekEnum.tuesday;
    case 3:
      return DayOfWeekEnum.wednesday;
    case 4:
      return DayOfWeekEnum.thursday;
    case 5:
      return DayOfWeekEnum.friday;
    case 6:
      return DayOfWeekEnum.saturday;
    case 7:
    default:
      return DayOfWeekEnum.sunday;
  }
});

final selectedTimetableSubjectFilterProvider = StateProvider<String?>((ref) => null);

// Timetable slots list provider
final timetableSlotsProvider = FutureProvider<List<TimetableSlotModel>>((ref) async {
  final repository = ref.watch(timetableRepositoryProvider);
  final day = ref.watch(selectedTimetableDayProvider);
  final subjectId = ref.watch(selectedTimetableSubjectFilterProvider);

  return repository.getSlots(
    dayOfWeek: day.value,
    subjectId: subjectId,
  );
});

// Weekly timetable provider
final weeklyScheduleProvider = FutureProvider<TimetableWeeklyModel>((ref) async {
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getWeeklySchedule();
});

// Today's schedule provider
final todayScheduleProvider = FutureProvider<List<TodayClassModel>>((ref) async {
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getTodaySchedule();
});

// Attendance summary provider
final attendanceSummaryProvider = FutureProvider<AttendanceSummaryModel>((ref) async {
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getAttendanceSummary();
});

// Attendance logs provider
final attendanceLogsProvider = FutureProvider<List<AttendanceLogModel>>((ref) async {
  final repository = ref.watch(timetableRepositoryProvider);
  final subjectId = ref.watch(selectedTimetableSubjectFilterProvider);
  return repository.getAttendanceLogs(subjectId: subjectId);
});

// Timetable Controller for mutations
class TimetableController extends StateNotifier<AsyncValue<void>> {
  final TimetableRepository _repository;
  final Ref _ref;

  TimetableController(this._repository, this._ref) : super(const AsyncValue.data(null));

  void _invalidateAll() {
    _ref.invalidate(timetableSlotsProvider);
    _ref.invalidate(weeklyScheduleProvider);
    _ref.invalidate(todayScheduleProvider);
    _ref.invalidate(attendanceSummaryProvider);
    _ref.invalidate(attendanceLogsProvider);
  }

  Future<bool> createSlot({
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
    state = const AsyncValue.loading();
    try {
      await _repository.createSlot(
        subjectId: subjectId,
        title: title,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        classType: classType,
        location: location,
        professorName: professorName,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      _invalidateAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateSlot({
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
    state = const AsyncValue.loading();
    try {
      await _repository.updateSlot(
        id: id,
        subjectId: subjectId,
        title: title,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        classType: classType,
        location: location,
        professorName: professorName,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      _invalidateAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteSlot(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteSlot(id);
      state = const AsyncValue.data(null);
      _invalidateAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> logAttendance({
    String? slotId,
    String? subjectId,
    required DateTime date,
    required AttendanceStatusEnum status,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.logAttendance(
        slotId: slotId,
        subjectId: subjectId,
        date: date,
        status: status,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      _invalidateAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteAttendanceLog(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAttendanceLog(id);
      state = const AsyncValue.data(null);
      _invalidateAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final timetableControllerProvider = StateNotifierProvider<TimetableController, AsyncValue<void>>((ref) {
  final repository = ref.watch(timetableRepositoryProvider);
  return TimetableController(repository, ref);
});
