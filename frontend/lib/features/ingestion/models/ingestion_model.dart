import 'package:flutter/material.dart';

enum SourceTypeEnum {
  file('file', 'File', Icons.insert_drive_file_outlined),
  note('note', 'Note', Icons.sticky_note_2_outlined);

  final String value;
  final String label;
  final IconData icon;

  const SourceTypeEnum(this.value, this.label, this.icon);

  static SourceTypeEnum fromString(String val) {
    return SourceTypeEnum.values.firstWhere(
      (e) => e.value == val,
      orElse: () => SourceTypeEnum.note,
    );
  }
}

enum IngestionStatusEnum {
  pending('pending', 'Pending', Color(0xFF6B7280), Icons.hourglass_empty_rounded),
  processing('processing', 'Indexing...', Color(0xFF3B82F6), Icons.sync_rounded),
  completed('completed', 'AI Indexed', Color(0xFF10B981), Icons.check_circle_outline_rounded),
  failed('failed', 'Indexing Failed', Color(0xFFEF4444), Icons.error_outline_rounded);

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const IngestionStatusEnum(this.value, this.label, this.color, this.icon);

  static IngestionStatusEnum fromString(String val) {
    return IngestionStatusEnum.values.firstWhere(
      (e) => e.value == val,
      orElse: () => IngestionStatusEnum.pending,
    );
  }
}

class IngestionStatusModel {
  final String sourceId;
  final SourceTypeEnum sourceType;
  final String sourceName;
  final IngestionStatusEnum status;
  final int chunksCount;
  final int totalTokens;
  final String? errorMessage;
  final DateTime updatedAt;

  IngestionStatusModel({
    required this.sourceId,
    required this.sourceType,
    required this.sourceName,
    required this.status,
    this.chunksCount = 0,
    this.totalTokens = 0,
    this.errorMessage,
    required this.updatedAt,
  });

  bool get isCompleted => status == IngestionStatusEnum.completed;
  bool get isProcessing => status == IngestionStatusEnum.processing;
  bool get isFailed => status == IngestionStatusEnum.failed;

  factory IngestionStatusModel.fromJson(Map<String, dynamic> json) {
    return IngestionStatusModel(
      sourceId: json['source_id'] ?? '',
      sourceType: SourceTypeEnum.fromString(json['source_type'] ?? 'note'),
      sourceName: json['source_name'] ?? 'Untitled Source',
      status: IngestionStatusEnum.fromString(json['status'] ?? 'pending'),
      chunksCount: json['chunks_count'] ?? 0,
      totalTokens: json['total_tokens'] ?? 0,
      errorMessage: json['error_message'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_id': sourceId,
      'source_type': sourceType.value,
      'source_name': sourceName,
      'status': status.value,
      'chunks_count': chunksCount,
      'total_tokens': totalTokens,
      'error_message': errorMessage,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class IngestionStatsModel {
  final int totalChunks;
  final int totalIndexedFiles;
  final int totalIndexedNotes;
  final int totalTokensEstimated;
  final Map<String, int> bySubject;
  final Map<String, int> byType;

  IngestionStatsModel({
    this.totalChunks = 0,
    this.totalIndexedFiles = 0,
    this.totalIndexedNotes = 0,
    this.totalTokensEstimated = 0,
    this.bySubject = const {},
    this.byType = const {},
  });

  int get totalIndexedSources => totalIndexedFiles + totalIndexedNotes;

  factory IngestionStatsModel.fromJson(Map<String, dynamic> json) {
    final rawBySubject = json['by_subject'] as Map<String, dynamic>? ?? {};
    final rawByType = json['by_type'] as Map<String, dynamic>? ?? {};

    return IngestionStatsModel(
      totalChunks: json['total_chunks'] ?? 0,
      totalIndexedFiles: json['total_indexed_files'] ?? 0,
      totalIndexedNotes: json['total_indexed_notes'] ?? 0,
      totalTokensEstimated: json['total_tokens_estimated'] ?? 0,
      bySubject: rawBySubject.map((k, v) => MapEntry(k, (v as num).toInt())),
      byType: rawByType.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_chunks': totalChunks,
      'total_indexed_files': totalIndexedFiles,
      'total_indexed_notes': totalIndexedNotes,
      'total_tokens_estimated': totalTokensEstimated,
      'by_subject': bySubject,
      'by_type': byType,
    };
  }
}

class SemanticSearchResultItemModel {
  final String chunkId;
  final String sourceId;
  final SourceTypeEnum sourceType;
  final String sourceName;
  final String? subjectId;
  final String? pageOrSection;
  final String textContent;
  final double similarityScore;
  final Map<String, dynamic> metadata;

  SemanticSearchResultItemModel({
    required this.chunkId,
    required this.sourceId,
    required this.sourceType,
    required this.sourceName,
    this.subjectId,
    this.pageOrSection,
    required this.textContent,
    required this.similarityScore,
    this.metadata = const {},
  });

  factory SemanticSearchResultItemModel.fromJson(Map<String, dynamic> json) {
    return SemanticSearchResultItemModel(
      chunkId: json['chunk_id'] ?? '',
      sourceId: json['source_id'] ?? '',
      sourceType: SourceTypeEnum.fromString(json['source_type'] ?? 'note'),
      sourceName: json['source_name'] ?? 'Untitled Source',
      subjectId: json['subject_id'],
      pageOrSection: json['page_or_section'],
      textContent: json['text_content'] ?? '',
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chunk_id': chunkId,
      'source_id': sourceId,
      'source_type': sourceType.value,
      'source_name': sourceName,
      'subject_id': subjectId,
      'page_or_section': pageOrSection,
      'text_content': textContent,
      'similarity_score': similarityScore,
      'metadata': metadata,
    };
  }
}

class SemanticSearchResponseModel {
  final String query;
  final int resultsCount;
  final List<SemanticSearchResultItemModel> results;

  SemanticSearchResponseModel({
    required this.query,
    required this.resultsCount,
    required this.results,
  });

  factory SemanticSearchResponseModel.fromJson(Map<String, dynamic> json) {
    return SemanticSearchResponseModel(
      query: json['query'] ?? '',
      resultsCount: json['results_count'] ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => SemanticSearchResultItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'results_count': resultsCount,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }
}
