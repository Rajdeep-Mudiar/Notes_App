import 'package:flutter/material.dart';

enum BlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  bulletList,
  numberedList,
  checklist,
  quote,
  callout,
  divider,
  code,
  table,
  equation,
  image,
  file;

  static BlockType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'heading_1':
      case 'h1':
        return BlockType.heading1;
      case 'heading_2':
      case 'h2':
        return BlockType.heading2;
      case 'heading_3':
      case 'h3':
        return BlockType.heading3;
      case 'bullet_list':
        return BlockType.bulletList;
      case 'numbered_list':
        return BlockType.numberedList;
      case 'checklist':
      case 'todo':
        return BlockType.checklist;
      case 'quote':
        return BlockType.quote;
      case 'callout':
        return BlockType.callout;
      case 'divider':
        return BlockType.divider;
      case 'code':
        return BlockType.code;
      case 'table':
        return BlockType.table;
      case 'equation':
      case 'latex':
      case 'math':
        return BlockType.equation;
      case 'image':
        return BlockType.image;
      case 'file':
        return BlockType.file;
      case 'paragraph':
      default:
        return BlockType.paragraph;
    }
  }

  String toServerString() {
    switch (this) {
      case BlockType.heading1:
        return 'heading_1';
      case BlockType.heading2:
        return 'heading_2';
      case BlockType.heading3:
        return 'heading_3';
      case BlockType.bulletList:
        return 'bullet_list';
      case BlockType.numberedList:
        return 'numbered_list';
      case BlockType.checklist:
        return 'checklist';
      case BlockType.quote:
        return 'quote';
      case BlockType.callout:
        return 'callout';
      case BlockType.divider:
        return 'divider';
      case BlockType.code:
        return 'code';
      case BlockType.table:
        return 'table';
      case BlockType.equation:
        return 'equation';
      case BlockType.image:
        return 'image';
      case BlockType.file:
        return 'file';
      case BlockType.paragraph:
        return 'paragraph';
    }
  }

  String get label {
    switch (this) {
      case BlockType.heading1:
        return 'Heading 1';
      case BlockType.heading2:
        return 'Heading 2';
      case BlockType.heading3:
        return 'Heading 3';
      case BlockType.bulletList:
        return 'Bulleted List';
      case BlockType.numberedList:
        return 'Numbered List';
      case BlockType.checklist:
        return 'Checklist / Todo';
      case BlockType.quote:
        return 'Quote';
      case BlockType.callout:
        return 'Callout Box';
      case BlockType.divider:
        return 'Divider';
      case BlockType.code:
        return 'Code Block';
      case BlockType.table:
        return 'Table';
      case BlockType.equation:
        return 'Math Equation (LaTeX)';
      case BlockType.image:
        return 'Image';
      case BlockType.file:
        return 'File Attachment';
      case BlockType.paragraph:
        return 'Paragraph';
    }
  }

  IconData get icon {
    switch (this) {
      case BlockType.heading1:
        return Icons.format_size_rounded;
      case BlockType.heading2:
        return Icons.title_rounded;
      case BlockType.heading3:
        return Icons.text_fields_rounded;
      case BlockType.bulletList:
        return Icons.format_list_bulleted_rounded;
      case BlockType.numberedList:
        return Icons.format_list_numbered_rounded;
      case BlockType.checklist:
        return Icons.check_box_outlined;
      case BlockType.quote:
        return Icons.format_quote_rounded;
      case BlockType.callout:
        return Icons.lightbulb_outline_rounded;
      case BlockType.divider:
        return Icons.horizontal_rule_rounded;
      case BlockType.code:
        return Icons.code_rounded;
      case BlockType.table:
        return Icons.table_chart_outlined;
      case BlockType.equation:
        return Icons.functions_rounded;
      case BlockType.image:
        return Icons.image_outlined;
      case BlockType.file:
        return Icons.attach_file_rounded;
      case BlockType.paragraph:
        return Icons.notes_rounded;
    }
  }
}

class NoteBlockModel {
  final String id;
  final BlockType type;
  final String content;
  final Map<String, dynamic> properties;
  final int order;

  const NoteBlockModel({
    required this.id,
    required this.type,
    required this.content,
    this.properties = const {},
    this.order = 0,
  });

  factory NoteBlockModel.fromJson(Map<String, dynamic> json) {
    return NoteBlockModel(
      id: json['id'] as String? ?? UniqueKey().toString(),
      type: BlockType.fromString(json['type'] as String? ?? 'paragraph'),
      content: json['content'] as String? ?? '',
      properties: (json['properties'] as Map<String, dynamic>?) ?? {},
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toServerString(),
      'content': content,
      'properties': properties,
      'order': order,
    };
  }

  NoteBlockModel copyWith({
    String? id,
    BlockType? type,
    String? content,
    Map<String, dynamic>? properties,
    int? order,
  }) {
    return NoteBlockModel(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      properties: properties ?? this.properties,
      order: order ?? this.order,
    );
  }
}

class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String? subjectId;
  final String? subjectName;
  final String? subjectCode;
  final String? subjectColor;
  final List<String> tags;
  final String? coverImage;
  final String icon;
  final List<NoteBlockModel> blocks;
  final bool isFavorite;
  final bool isPinned;
  final bool isArchived;
  final String previewSnippet;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
    this.subjectColor,
    this.tags = const [],
    this.coverImage,
    this.icon = 'article',
    this.blocks = const [],
    this.isFavorite = false,
    this.isPinned = false,
    this.isArchived = false,
    this.previewSnippet = '',
    this.createdAt,
    this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['blocks'] as List<dynamic>? ?? [];
    return NoteModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Note',
      subjectId: json['subject_id'] as String?,
      subjectName: json['subject_name'] as String?,
      subjectCode: json['subject_code'] as String?,
      subjectColor: json['subject_color'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      coverImage: json['cover_image'] as String?,
      icon: json['icon'] as String? ?? 'article',
      blocks: rawBlocks.map((b) => NoteBlockModel.fromJson(b as Map<String, dynamic>)).toList(),
      isFavorite: json['is_favorite'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      previewSnippet: json['preview_snippet'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subject_id': subjectId,
      'tags': tags,
      'cover_image': coverImage,
      'icon': icon,
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'is_favorite': isFavorite,
      'is_pinned': isPinned,
    };
  }

  Color get color {
    if (subjectColor == null) return const Color(0xFF4F46E5);
    try {
      final hex = subjectColor!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }

  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
    String? subjectColor,
    List<String>? tags,
    String? coverImage,
    String? icon,
    List<NoteBlockModel>? blocks,
    bool? isFavorite,
    bool? isPinned,
    bool? isArchived,
    String? previewSnippet,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectColor: subjectColor ?? this.subjectColor,
      tags: tags ?? this.tags,
      coverImage: coverImage ?? this.coverImage,
      icon: icon ?? this.icon,
      blocks: blocks ?? this.blocks,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      previewSnippet: previewSnippet ?? this.previewSnippet,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class NoteSummaryModel {
  final String id;
  final String userId;
  final String title;
  final String? subjectId;
  final String? subjectName;
  final String? subjectCode;
  final String? subjectColor;
  final List<String> tags;
  final String icon;
  final String previewSnippet;
  final int blocksCount;
  final bool isFavorite;
  final bool isPinned;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NoteSummaryModel({
    required this.id,
    required this.userId,
    required this.title,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
    this.subjectColor,
    this.tags = const [],
    this.icon = 'article',
    this.previewSnippet = '',
    this.blocksCount = 0,
    this.isFavorite = false,
    this.isPinned = false,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  });

  factory NoteSummaryModel.fromJson(Map<String, dynamic> json) {
    return NoteSummaryModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Note',
      subjectId: json['subject_id'] as String?,
      subjectName: json['subject_name'] as String?,
      subjectCode: json['subject_code'] as String?,
      subjectColor: json['subject_color'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      icon: json['icon'] as String? ?? 'article',
      previewSnippet: json['preview_snippet'] as String? ?? '',
      blocksCount: (json['blocks_count'] as num?)?.toInt() ?? 0,
      isFavorite: json['is_favorite'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Color get color {
    if (subjectColor == null) return const Color(0xFF4F46E5);
    try {
      final hex = subjectColor!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }
}
