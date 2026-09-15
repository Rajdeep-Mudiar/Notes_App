import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/subjects/models/subject_model.dart';
import 'package:frontend/features/subjects/repositories/subject_repository.dart';

// Repository Provider
final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubjectRepository(apiClient);
});

// Selected Semester Filter Provider (null means all semesters)
final selectedSemesterFilterProvider = StateProvider<int?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.currentSemester ?? 1;
});

// Include Archived Filter Provider
final includeArchivedProvider = StateProvider<bool>((ref) => false);

// Subjects State Notifier
class SubjectsNotifier extends StateNotifier<AsyncValue<List<SubjectModel>>> {
  final SubjectRepository _repository;
  final Ref _ref;

  SubjectsNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    state = const AsyncValue.loading();
    try {
      final semester = _ref.read(selectedSemesterFilterProvider);
      final includeArchived = _ref.read(includeArchivedProvider);
      final subjects = await _repository.getSubjects(
        semester: semester,
        includeArchived: includeArchived,
      );
      state = AsyncValue.data(subjects);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createSubject({
    required String name,
    required String code,
    required String professor,
    required int credits,
    required String color,
    required String icon,
    String description = '',
    required int semester,
  }) async {
    try {
      final newSubject = await _repository.createSubject(
        name: name,
        code: code,
        professor: professor,
        credits: credits,
        color: color,
        icon: icon,
        description: description,
        semester: semester,
      );

      final current = state.value ?? [];
      state = AsyncValue.data([newSubject, ...current]);
      _ref.invalidate(academicSummaryProvider);
      return true;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('already exists')) {
        return false;
      }
      // Offline / network timeout auto-provisioning
      final localSubject = SubjectModel(
        id: 'subj_${DateTime.now().millisecondsSinceEpoch}',
        userId: _ref.read(currentUserProvider)?.id ?? 'local_student',
        name: name,
        code: code,
        professor: professor,
        credits: credits,
        colorHex: color,
        icon: icon,
        description: description,
        semester: semester,
        isArchived: false,
        notesCount: 0,
        filesCount: 0,
        assignmentsCount: 0,
        examsCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final current = state.value ?? [];
      state = AsyncValue.data([localSubject, ...current]);
      _ref.invalidate(academicSummaryProvider);
      return true;
    }
  }

  Future<bool> updateSubject(
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
    try {
      final updated = await _repository.updateSubject(
        id,
        name: name,
        code: code,
        professor: professor,
        credits: credits,
        color: color,
        icon: icon,
        description: description,
        semester: semester,
        isArchived: isArchived,
      );

      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((s) => s.id == id ? updated : s).toList(),
      );
      _ref.invalidate(academicSummaryProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSubject(String id) async {
    try {
      await _repository.deleteSubject(id);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((s) => s.id != id).toList());
      _ref.invalidate(academicSummaryProvider);
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Subjects List Provider
final subjectsProvider = StateNotifierProvider<SubjectsNotifier, AsyncValue<List<SubjectModel>>>((ref) {
  ref.watch(currentUserProvider);
  final repository = ref.watch(subjectRepositoryProvider);
  return SubjectsNotifier(repository, ref);
});

// Single Subject by ID Provider
final singleSubjectProvider = FutureProvider.family<SubjectModel, String>((ref, subjectId) async {
  final repository = ref.watch(subjectRepositoryProvider);
  return await repository.getSubjectById(subjectId);
});

// Academic Summary Provider
final academicSummaryProvider = FutureProvider.autoDispose<AcademicSummaryModel>((ref) async {
  final repository = ref.watch(subjectRepositoryProvider);
  return await repository.getAcademicSummary();
});
