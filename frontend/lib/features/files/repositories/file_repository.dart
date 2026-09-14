import 'package:dio/dio.dart';
import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/files/models/file_model.dart';

class FileRepository {
  final ApiClient _apiClient;

  FileRepository(this._apiClient);

  Future<FileModel> uploadFile({
    required String fileName,
    List<int>? bytes,
    String? filePath,
    String? subjectId,
    String? folderId,
    void Function(int sent, int total)? onProgress,
  }) async {
    MultipartFile multipartFile;
    if (bytes != null) {
      multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
    } else if (filePath != null) {
      multipartFile = await MultipartFile.fromFile(filePath, filename: fileName);
    } else {
      throw Exception('Either file bytes or filePath must be provided');
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
      if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId,
      if (folderId != null && folderId.isNotEmpty) 'folder_id': folderId,
    });

    final response = await _apiClient.dio.post(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.filesUpload}',
      data: formData,
      onSendProgress: onProgress,
    );

    return FileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FileListResponseModel> getFiles({
    String? subjectId,
    String? folderId,
    String? fileType,
    String? search,
    bool? isFavorite,
  }) async {
    final queryParams = <String, dynamic>{};
    if (subjectId != null && subjectId.isNotEmpty) queryParams['subject_id'] = subjectId;
    if (folderId != null && folderId.isNotEmpty) queryParams['folder_id'] = folderId;
    if (fileType != null && fileType.isNotEmpty && fileType != 'all') queryParams['file_type'] = fileType;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (isFavorite != null) queryParams['is_favorite'] = isFavorite;

    final response = await _apiClient.get(
      ApiEndpoints.files,
      queryParameters: queryParams,
    );

    return FileListResponseModel.fromJson(response);
  }

  Future<StorageSummaryModel> getStorageSummary() async {
    final response = await _apiClient.get(ApiEndpoints.filesStorage);
    return StorageSummaryModel.fromJson(response);
  }

  Future<void> deleteFile(String fileId) async {
    await _apiClient.delete(ApiEndpoints.fileById(fileId));
  }

  Future<FileModel> toggleFavorite(String fileId) async {
    final response = await _apiClient.put(ApiEndpoints.fileFavorite(fileId));
    return FileModel.fromJson(response);
  }

  Future<FolderModel> createFolder({
    required String name,
    String? subjectId,
    String? parentId,
    String? color,
    String? icon,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.folders,
      data: {
        'name': name,
        if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId,
        if (parentId != null && parentId.isNotEmpty) 'parent_id': parentId,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
      },
    );

    return FolderModel.fromJson(response);
  }

  Future<List<FolderModel>> getFolders({String? subjectId, String? parentId}) async {
    final queryParams = <String, dynamic>{};
    if (subjectId != null && subjectId.isNotEmpty) queryParams['subject_id'] = subjectId;
    if (parentId != null && parentId.isNotEmpty) queryParams['parent_id'] = parentId;

    final response = await _apiClient.get(
      ApiEndpoints.folders,
      queryParameters: queryParams,
    );

    final rawList = (response['data'] ?? response) as List<dynamic>? ?? [];
    return rawList.map((e) => FolderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteFolder(String folderId) async {
    await _apiClient.delete(ApiEndpoints.folderById(folderId));
  }
}
