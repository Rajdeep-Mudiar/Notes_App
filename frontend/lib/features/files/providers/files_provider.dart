import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/files/models/file_model.dart';
import 'package:frontend/features/files/repositories/file_repository.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FileRepository(apiClient);
});

// Filter states
final activeFileTypeFilterProvider = StateProvider<String>((ref) => 'all');
final fileSearchQueryProvider = StateProvider<String>((ref) => '');
final fileSubjectFilterProvider = StateProvider<String?>((ref) => null);
final fileFavoriteFilterProvider = StateProvider<bool?>((ref) => null);

// Folder navigation stack: empty list = Root
final folderNavStackProvider = StateProvider<List<FolderModel>>((ref) => []);

// Main files and folders provider
final filesListProvider = FutureProvider.autoDispose<FileListResponseModel>((ref) async {
  final repo = ref.watch(fileRepositoryProvider);
  final subjectId = ref.watch(fileSubjectFilterProvider);
  final fileType = ref.watch(activeFileTypeFilterProvider);
  final search = ref.watch(fileSearchQueryProvider);
  final isFav = ref.watch(fileFavoriteFilterProvider);
  final navStack = ref.watch(folderNavStackProvider);

  final currentFolderId = navStack.isNotEmpty ? navStack.last.id : null;

  return repo.getFiles(
    subjectId: subjectId,
    folderId: currentFolderId,
    fileType: fileType == 'all' ? null : fileType,
    search: search.isEmpty ? null : search,
    isFavorite: isFav,
  );
});

// Storage usage metrics provider
final storageSummaryProvider = FutureProvider.autoDispose<StorageSummaryModel>((ref) async {
  final repo = ref.watch(fileRepositoryProvider);
  return repo.getStorageSummary();
});

// Subject-scoped files provider for the Subject Hub (Files Tab)
final subjectFilesProvider = FutureProvider.autoDispose.family<FileListResponseModel, String>((ref, subjectId) async {
  final repo = ref.watch(fileRepositoryProvider);
  return repo.getFiles(subjectId: subjectId);
});

// Operations Notifier
class FileOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final FileRepository _repo;

  FileOperationsNotifier(this._ref, this._repo) : super(const AsyncValue.data(null));

  Future<FileModel?> uploadFile({
    required String fileName,
    List<int>? bytes,
    String? filePath,
    String? subjectId,
    String? folderId,
    void Function(int, int)? onProgress,
  }) async {
    state = const AsyncValue.loading();
    try {
      final file = await _repo.uploadFile(
        fileName: fileName,
        bytes: bytes,
        filePath: filePath,
        subjectId: subjectId,
        folderId: folderId,
        onProgress: onProgress,
      );
      state = const AsyncValue.data(null);
      _invalidateProviders(subjectId);
      return file;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteFile(String fileId, {String? subjectId}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteFile(fileId);
      state = const AsyncValue.data(null);
      _invalidateProviders(subjectId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleFavorite(String fileId, {String? subjectId}) async {
    try {
      await _repo.toggleFavorite(fileId);
      _invalidateProviders(subjectId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<FolderModel> createFolder({
    required String name,
    String? subjectId,
    String? parentId,
    String? color,
    String? icon,
  }) async {
    state = const AsyncValue.loading();
    try {
      final folder = await _repo.createFolder(
        name: name,
        subjectId: subjectId,
        parentId: parentId,
        color: color,
        icon: icon,
      );
      state = const AsyncValue.data(null);
      _invalidateProviders(subjectId);
      return folder;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteFolder(String folderId, {String? subjectId}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteFolder(folderId);
      state = const AsyncValue.data(null);
      _invalidateProviders(subjectId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void _invalidateProviders(String? subjectId) {
    _ref.invalidate(filesListProvider);
    _ref.invalidate(storageSummaryProvider);
    if (subjectId != null) {
      _ref.invalidate(subjectFilesProvider(subjectId));
      _ref.read(subjectsProvider.notifier).loadSubjects();
    }
  }
}

final fileOperationsProvider = StateNotifierProvider<FileOperationsNotifier, AsyncValue<void>>((ref) {
  return FileOperationsNotifier(ref, ref.watch(fileRepositoryProvider));
});
