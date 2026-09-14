import 'package:flutter/material.dart';

enum FileTypeEnum {
  pdf,
  document,
  presentation,
  spreadsheet,
  image,
  video,
  audio,
  archive,
  code,
  other;

  static FileTypeEnum fromString(String val) {
    return FileTypeEnum.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => FileTypeEnum.other,
    );
  }

  String get label {
    switch (this) {
      case FileTypeEnum.pdf:
        return 'PDF';
      case FileTypeEnum.document:
        return 'Document';
      case FileTypeEnum.presentation:
        return 'Slide Deck';
      case FileTypeEnum.spreadsheet:
        return 'Spreadsheet';
      case FileTypeEnum.image:
        return 'Image';
      case FileTypeEnum.video:
        return 'Video';
      case FileTypeEnum.audio:
        return 'Audio';
      case FileTypeEnum.archive:
        return 'Archive';
      case FileTypeEnum.code:
        return 'Code';
      case FileTypeEnum.other:
        return 'File';
    }
  }

  Color get color {
    switch (this) {
      case FileTypeEnum.pdf:
        return const Color(0xFFEF4444); // Crimson Red
      case FileTypeEnum.document:
        return const Color(0xFF3B82F6); // Blue
      case FileTypeEnum.presentation:
        return const Color(0xFFF97316); // Orange
      case FileTypeEnum.spreadsheet:
        return const Color(0xFF10B981); // Emerald Green
      case FileTypeEnum.image:
        return const Color(0xFF8B5CF6); // Violet
      case FileTypeEnum.video:
        return const Color(0xFFEC4899); // Pink
      case FileTypeEnum.audio:
        return const Color(0xFFF59E0B); // Amber
      case FileTypeEnum.archive:
        return const Color(0xFF14B8A6); // Teal
      case FileTypeEnum.code:
        return const Color(0xFF06B6D4); // Cyan
      case FileTypeEnum.other:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData get iconData {
    switch (this) {
      case FileTypeEnum.pdf:
        return Icons.picture_as_pdf_rounded;
      case FileTypeEnum.document:
        return Icons.description_rounded;
      case FileTypeEnum.presentation:
        return Icons.slideshow_rounded;
      case FileTypeEnum.spreadsheet:
        return Icons.table_chart_rounded;
      case FileTypeEnum.image:
        return Icons.image_rounded;
      case FileTypeEnum.video:
        return Icons.movie_rounded;
      case FileTypeEnum.audio:
        return Icons.audiotrack_rounded;
      case FileTypeEnum.archive:
        return Icons.folder_zip_rounded;
      case FileTypeEnum.code:
        return Icons.code_rounded;
      case FileTypeEnum.other:
        return Icons.insert_drive_file_rounded;
    }
  }
}

class FileModel {
  final String id;
  final String userId;
  final String? subjectId;
  final String? folderId;
  final String filename;
  final String originalName;
  final FileTypeEnum fileType;
  final String mimeType;
  final int sizeBytes;
  final String sizeFormatted;
  final String downloadUrl;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  FileModel({
    required this.id,
    required this.userId,
    this.subjectId,
    this.folderId,
    required this.filename,
    required this.originalName,
    required this.fileType,
    required this.mimeType,
    required this.sizeBytes,
    required this.sizeFormatted,
    required this.downloadUrl,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fileExtension {
    if (!originalName.contains('.')) return '';
    return originalName.split('.').last.toUpperCase();
  }

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      subjectId: json['subject_id'],
      folderId: json['folder_id'],
      filename: json['filename'] ?? '',
      originalName: json['original_name'] ?? '',
      fileType: FileTypeEnum.fromString(json['file_type'] ?? 'other'),
      mimeType: json['mime_type'] ?? 'application/octet-stream',
      sizeBytes: json['size_bytes'] ?? 0,
      sizeFormatted: json['size_formatted'] ?? '0 B',
      downloadUrl: json['download_url'] ?? '',
      isFavorite: json['is_favorite'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'folder_id': folderId,
      'filename': filename,
      'original_name': originalName,
      'file_type': fileType.name,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'size_formatted': sizeFormatted,
      'download_url': downloadUrl,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FileModel copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? folderId,
    String? filename,
    String? originalName,
    FileTypeEnum? fileType,
    String? mimeType,
    int? sizeBytes,
    String? sizeFormatted,
    String? downloadUrl,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      folderId: folderId ?? this.folderId,
      filename: filename ?? this.filename,
      originalName: originalName ?? this.originalName,
      fileType: fileType ?? this.fileType,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sizeFormatted: sizeFormatted ?? this.sizeFormatted,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FolderModel {
  final String id;
  final String userId;
  final String name;
  final String? subjectId;
  final String? parentId;
  final String colorHex;
  final String icon;
  final int itemsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  FolderModel({
    required this.id,
    required this.userId,
    required this.name,
    this.subjectId,
    this.parentId,
    this.colorHex = '#4F46E5',
    this.icon = 'folder',
    this.itemsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      subjectId: json['subject_id'],
      parentId: json['parent_id'],
      colorHex: json['color'] ?? '#4F46E5',
      icon: json['icon'] ?? 'folder',
      itemsCount: json['items_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'subject_id': subjectId,
      'parent_id': parentId,
      'color': colorHex,
      'icon': icon,
      'items_count': itemsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class StorageSummaryModel {
  final int usedBytes;
  final String usedFormatted;
  final int totalLimitBytes;
  final String totalLimitFormatted;
  final double percentageUsed;
  final int filesCount;
  final Map<String, int> byType;

  StorageSummaryModel({
    required this.usedBytes,
    required this.usedFormatted,
    required this.totalLimitBytes,
    required this.totalLimitFormatted,
    required this.percentageUsed,
    required this.filesCount,
    required this.byType,
  });

  factory StorageSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawByType = json['by_type'] as Map<String, dynamic>? ?? {};
    final byType = rawByType.map((k, v) => MapEntry(k, (v as num).toInt()));

    return StorageSummaryModel(
      usedBytes: json['used_bytes'] ?? 0,
      usedFormatted: json['used_formatted'] ?? '0 B',
      totalLimitBytes: json['total_limit_bytes'] ?? (500 * 1024 * 1024),
      totalLimitFormatted: json['total_limit_formatted'] ?? '500.0 MB',
      percentageUsed: (json['percentage_used'] as num?)?.toDouble() ?? 0.0,
      filesCount: json['files_count'] ?? 0,
      byType: byType,
    );
  }
}

class FileListResponseModel {
  final List<FileModel> items;
  final List<FolderModel> folders;
  final int totalFiles;
  final int totalFolders;

  FileListResponseModel({
    required this.items,
    required this.folders,
    required this.totalFiles,
    required this.totalFolders,
  });

  factory FileListResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final rawFolders = json['folders'] as List<dynamic>? ?? [];

    return FileListResponseModel(
      items: rawItems.map((e) => FileModel.fromJson(e as Map<String, dynamic>)).toList(),
      folders: rawFolders.map((e) => FolderModel.fromJson(e as Map<String, dynamic>)).toList(),
      totalFiles: json['total_files'] ?? rawItems.length,
      totalFolders: json['total_folders'] ?? rawFolders.length,
    );
  }
}
