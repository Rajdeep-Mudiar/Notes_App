import 'package:flutter/material.dart';

class SubjectModel {
  final String id;
  final String userId;
  final String name;
  final String code;
  final String professor;
  final int credits;
  final String colorHex;
  final String icon;
  final String description;
  final int semester;
  final bool isArchived;
  final int notesCount;
  final int filesCount;
  final int assignmentsCount;
  final int examsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubjectModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.code,
    required this.professor,
    required this.credits,
    required this.colorHex,
    required this.icon,
    this.description = '',
    required this.semester,
    this.isArchived = false,
    this.notesCount = 0,
    this.filesCount = 0,
    this.assignmentsCount = 0,
    this.examsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Subject',
      code: json['code'] as String? ?? 'SUB101',
      professor: json['professor'] as String? ?? 'Professor',
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      colorHex: json['color'] as String? ?? '#4F46E5',
      icon: json['icon'] as String? ?? 'book',
      description: json['description'] as String? ?? '',
      semester: (json['semester'] as num?)?.toInt() ?? 1,
      isArchived: json['is_archived'] as bool? ?? false,
      notesCount: (json['notes_count'] as num?)?.toInt() ?? 0,
      filesCount: (json['files_count'] as num?)?.toInt() ?? 0,
      assignmentsCount: (json['assignments_count'] as num?)?.toInt() ?? 0,
      examsCount: (json['exams_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'professor': professor,
      'credits': credits,
      'color': colorHex,
      'icon': icon,
      'description': description,
      'semester': semester,
      'is_archived': isArchived,
    };
  }

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }

  IconData get iconData {
    switch (icon.toLowerCase()) {
      case 'code':
        return Icons.code_rounded;
      case 'memory':
      case 'cpu':
        return Icons.memory_rounded;
      case 'storage':
      case 'database':
        return Icons.storage_rounded;
      case 'calculator':
      case 'math':
        return Icons.calculate_rounded;
      case 'practical':
      case 'science':
      case 'atom':
        return Icons.science_rounded;
      case 'network':
        return Icons.hub_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'palette':
      case 'design':
        return Icons.palette_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'book':
      default:
        return Icons.menu_book_rounded;
    }
  }

  SubjectModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? code,
    String? professor,
    int? credits,
    String? colorHex,
    String? icon,
    String? description,
    int? semester,
    bool? isArchived,
    int? notesCount,
    int? filesCount,
    int? assignmentsCount,
    int? examsCount,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      code: code ?? this.code,
      professor: professor ?? this.professor,
      credits: credits ?? this.credits,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      semester: semester ?? this.semester,
      isArchived: isArchived ?? this.isArchived,
      notesCount: notesCount ?? this.notesCount,
      filesCount: filesCount ?? this.filesCount,
      assignmentsCount: assignmentsCount ?? this.assignmentsCount,
      examsCount: examsCount ?? this.examsCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class AcademicSummaryModel {
  final int totalSubjects;
  final int activeSubjects;
  final int archivedSubjects;
  final int totalCredits;
  final int currentSemester;
  final int semesterCredits;

  const AcademicSummaryModel({
    required this.totalSubjects,
    required this.activeSubjects,
    required this.archivedSubjects,
    required this.totalCredits,
    required this.currentSemester,
    required this.semesterCredits,
  });

  factory AcademicSummaryModel.fromJson(Map<String, dynamic> json) {
    return AcademicSummaryModel(
      totalSubjects: (json['total_subjects'] as num?)?.toInt() ?? 0,
      activeSubjects: (json['active_subjects'] as num?)?.toInt() ?? 0,
      archivedSubjects: (json['archived_subjects'] as num?)?.toInt() ?? 0,
      totalCredits: (json['total_credits'] as num?)?.toInt() ?? 0,
      currentSemester: (json['current_semester'] as num?)?.toInt() ?? 1,
      semesterCredits: (json['semester_credits'] as num?)?.toInt() ?? 0,
    );
  }
}
