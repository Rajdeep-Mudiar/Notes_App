import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/ingestion/models/ingestion_model.dart';
import 'package:frontend/features/ingestion/repositories/ingestion_repository.dart';

final ingestionRepositoryProvider = Provider<IngestionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return IngestionRepository(apiClient);
});

// Knowledge base overall indexing statistics provider
final ingestionStatsProvider = FutureProvider.autoDispose<IngestionStatsModel>((ref) async {
  final repository = ref.watch(ingestionRepositoryProvider);
  return repository.getIngestionStats();
});

// Source-specific ingestion status provider
final sourceIngestionStatusProvider = FutureProvider.autoDispose.family<IngestionStatusModel?, String>((ref, sourceId) async {
  if (sourceId.isEmpty) return null;
  final repository = ref.watch(ingestionRepositoryProvider);
  try {
    return await repository.getIngestionStatus(sourceId);
  } catch (_) {
    return null;
  }
});

// Ingestion Controller for manual actions & mutations
class IngestionController extends StateNotifier<AsyncValue<void>> {
  final IngestionRepository _repository;
  final Ref _ref;

  IngestionController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<IngestionStatusModel?> indexFile(String fileId) async {
    state = const AsyncValue.loading();
    try {
      final status = await _repository.ingestFile(fileId);
      state = const AsyncValue.data(null);
      _ref.invalidate(ingestionStatsProvider);
      _ref.invalidate(sourceIngestionStatusProvider(fileId));
      return status;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<IngestionStatusModel?> indexNote(String noteId) async {
    state = const AsyncValue.loading();
    try {
      final status = await _repository.ingestNote(noteId);
      state = const AsyncValue.data(null);
      _ref.invalidate(ingestionStatsProvider);
      _ref.invalidate(sourceIngestionStatusProvider(noteId));
      return status;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> purgeSourceIndex(String sourceId) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.deleteSource(sourceId);
      state = const AsyncValue.data(null);
      _ref.invalidate(ingestionStatsProvider);
      _ref.invalidate(sourceIngestionStatusProvider(sourceId));
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<SemanticSearchResponseModel?> searchSemantic(
    String query, {
    String? subjectId,
    String? sourceId,
    String? sourceType,
    int topK = 5,
  }) async {
    try {
      return await _repository.searchSimilarChunks(
        query,
        subjectId: subjectId,
        sourceId: sourceId,
        sourceType: sourceType,
        topK: topK,
      );
    } catch (_) {
      return null;
    }
  }
}

final ingestionControllerProvider = StateNotifierProvider<IngestionController, AsyncValue<void>>((ref) {
  final repository = ref.watch(ingestionRepositoryProvider);
  return IngestionController(repository, ref);
});
