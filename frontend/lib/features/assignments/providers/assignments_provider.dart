import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/assignments/models/assignment_model.dart';
import 'package:frontend/features/assignments/repositories/assignment_repository.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

enum AssignmentViewMode {
  list,
  kanban;

  String get label => this == AssignmentViewMode.list ? 'List' : 'Kanban Board';
}

// Repository Provider
final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AssignmentRepository(apiClient);
});

// Filter Providers
final assignmentSubjectFilterProvider = StateProvider<String?>((ref) => null);
final assignmentStatusFilterProvider = StateProvider<AssignmentStatus?>((ref) => null);
final assignmentPriorityFilterProvider = StateProvider<AssignmentPriority?>((ref) => null);
final assignmentSearchQueryProvider = StateProvider<String>((ref) => '');
final assignmentViewModeProvider = StateProvider<AssignmentViewMode>((ref) => AssignmentViewMode.list);

// Assignments List Notifier
class AssignmentsNotifier extends StateNotifier<AsyncValue<AssignmentListResponseModel>> {
  final AssignmentRepository _repository;
  final Ref _ref;

  AssignmentsNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadAssignments();
  }

  Future<void> loadAssignments() async {
    state = const AsyncValue.loading();
    try {
      final subjectId = _ref.read(assignmentSubjectFilterProvider);
      final status = _ref.read(assignmentStatusFilterProvider);
      final priority = _ref.read(assignmentPriorityFilterProvider);
      final search = _ref.read(assignmentSearchQueryProvider);

      final result = await _repository.getAssignments(
        subjectId: subjectId,
        status: status?.value,
        priority: priority?.value,
        search: search.isNotEmpty ? search : null,
      );
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
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
    final created = await _repository.createAssignment(
      title: title,
      description: description,
      subjectId: subjectId,
      dueDate: dueDate,
      priority: priority,
      status: status,
      weightPercentage: weightPercentage,
      fileIds: fileIds,
    );

    // Refresh state and related providers
    await loadAssignments();
    _ref.invalidate(upcomingAssignmentsProvider);
    _ref.invalidate(assignmentSummaryProvider);
    _ref.invalidate(subjectsProvider);

    return created;
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
    final updated = await _repository.updateAssignment(
      id,
      title: title,
      description: description,
      subjectId: subjectId,
      dueDate: dueDate,
      priority: priority,
      status: status,
      weightPercentage: weightPercentage,
      gradeReceived: gradeReceived,
      feedback: feedback,
      fileIds: fileIds,
    );

    await loadAssignments();
    _ref.invalidate(upcomingAssignmentsProvider);
    _ref.invalidate(assignmentSummaryProvider);
    _ref.invalidate(subjectsProvider);

    return updated;
  }

  Future<void> updateStatus(String id, AssignmentStatus newStatus) async {
    try {
      // Optimistic update
      final currentData = state.value;
      if (currentData != null) {
        final updatedItems = currentData.items.map((item) {
          if (item.id == id) {
            return item.copyWith(
              status: newStatus,
              countdownText: (newStatus == AssignmentStatus.submitted || newStatus == AssignmentStatus.graded)
                  ? 'Completed'
                  : item.countdownText,
            );
          }
          return item;
        }).toList();

        state = AsyncValue.data(AssignmentListResponseModel(
          items: updatedItems,
          total: currentData.total,
          pendingCount: currentData.pendingCount,
          inProgressCount: currentData.inProgressCount,
          submittedCount: currentData.submittedCount,
          gradedCount: currentData.gradedCount,
          urgentCount: currentData.urgentCount,
        ));
      }

      await _repository.updateStatus(id, newStatus);
      await loadAssignments();
      _ref.invalidate(upcomingAssignmentsProvider);
      _ref.invalidate(assignmentSummaryProvider);
    } catch (e) {
      await loadAssignments();
    }
  }

  Future<void> deleteAssignment(String id) async {
    try {
      await _repository.deleteAssignment(id);
      await loadAssignments();
      _ref.invalidate(upcomingAssignmentsProvider);
      _ref.invalidate(assignmentSummaryProvider);
      _ref.invalidate(subjectsProvider);
    } catch (_) {}
  }
}

final assignmentsProvider = StateNotifierProvider<AssignmentsNotifier, AsyncValue<AssignmentListResponseModel>>((ref) {
  final repository = ref.watch(assignmentRepositoryProvider);
  return AssignmentsNotifier(repository, ref);
});

// Upcoming Assignments for Dashboard & Study Calendar
final upcomingAssignmentsProvider = FutureProvider.autoDispose<List<AssignmentModel>>((ref) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return await repository.getUpcomingAssignments(limit: 5);
});

// Summary Metrics for Academic Planner
final assignmentSummaryProvider = FutureProvider.autoDispose<AssignmentSummaryModel>((ref) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return await repository.getSummary();
});

// Single Assignment Detail Provider
final singleAssignmentProvider = FutureProvider.family<AssignmentModel, String>((ref, id) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return await repository.getAssignmentById(id);
});
