import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/notes/models/note_model.dart';
import 'package:frontend/features/notes/repositories/note_repository.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

// Repository Provider
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NoteRepository(apiClient);
});

// Filter Providers
final noteSubjectFilterProvider = StateProvider<String?>((ref) => null);
final noteTagFilterProvider = StateProvider<String?>((ref) => null);
final noteSearchQueryProvider = StateProvider<String>((ref) => '');
final noteOnlyFavoritesProvider = StateProvider<bool>((ref) => false);

// Notes List State Notifier
class NotesListNotifier extends StateNotifier<AsyncValue<List<NoteSummaryModel>>> {
  final NoteRepository _repository;
  final Ref _ref;

  NotesListNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final subjectId = _ref.read(noteSubjectFilterProvider);
      final tag = _ref.read(noteTagFilterProvider);
      final search = _ref.read(noteSearchQueryProvider);
      final onlyFav = _ref.read(noteOnlyFavoritesProvider);

      final notes = await _repository.getNotes(
        subjectId: subjectId,
        tag: tag,
        isFavorite: onlyFav ? true : null,
        search: search.isNotEmpty ? search : null,
      );
      state = AsyncValue.data(notes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((n) => n.id != noteId).toList());
      _ref.invalidate(recentNotesProvider);
      _ref.invalidate(subjectsProvider);
    } catch (_) {}
  }
}

final notesListProvider = StateNotifierProvider<NotesListNotifier, AsyncValue<List<NoteSummaryModel>>>((ref) {
  ref.watch(currentUserProvider);
  final repository = ref.watch(noteRepositoryProvider);
  return NotesListNotifier(repository, ref);
});

// Recent Notes for Dashboard
final recentNotesProvider = FutureProvider.autoDispose<List<NoteSummaryModel>>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);
  return await repository.getRecentNotes(limit: 5);
});

// Single Note Detail Provider
final singleNoteProvider = FutureProvider.family<NoteModel, String>((ref, noteId) async {
  final repository = ref.watch(noteRepositoryProvider);
  return await repository.getNoteById(noteId);
});
