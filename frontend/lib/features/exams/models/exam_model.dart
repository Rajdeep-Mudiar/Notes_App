import 'package:flutter/material.dart';

enum ExamTypeEnum {
  quiz,
  midterm,
  finalExam,
  labPractical,
  oralPresentation;

  static ExamTypeEnum fromString(String val) {
    switch (val.toLowerCase()) {
      case 'quiz':
        return ExamTypeEnum.quiz;
      case 'final':
      case 'final_exam':
        return ExamTypeEnum.finalExam;
      case 'lab_practical':
      case 'labpractical':
        return ExamTypeEnum.labPractical;
      case 'oral_presentation':
      case 'oralpresentation':
      case 'presentation':
        return ExamTypeEnum.oralPresentation;
      case 'midterm':
      default:
        return ExamTypeEnum.midterm;
    }
  }

  String get value {
    switch (this) {
      case ExamTypeEnum.finalExam:
        return 'final';
      case ExamTypeEnum.labPractical:
        return 'lab_practical';
      case ExamTypeEnum.oralPresentation:
        return 'oral_presentation';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case ExamTypeEnum.quiz:
        return 'Quiz / Test';
      case ExamTypeEnum.midterm:
        return 'Midterm Exam';
      case ExamTypeEnum.finalExam:
        return 'Final Exam';
      case ExamTypeEnum.labPractical:
        return 'Lab Practical';
      case ExamTypeEnum.oralPresentation:
        return 'Presentation / Viva';
    }
  }

  Color get color {
    switch (this) {
      case ExamTypeEnum.quiz:
        return const Color(0xFF3B82F6); // Blue
      case ExamTypeEnum.midterm:
        return const Color(0xFFF59E0B); // Amber
      case ExamTypeEnum.finalExam:
        return const Color(0xFFEF4444); // Crimson Red
      case ExamTypeEnum.labPractical:
        return const Color(0xFF10B981); // Emerald Green
      case ExamTypeEnum.oralPresentation:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  IconData get icon {
    switch (this) {
      case ExamTypeEnum.quiz:
        return Icons.quiz_outlined;
      case ExamTypeEnum.midterm:
        return Icons.assignment_late_outlined;
      case ExamTypeEnum.finalExam:
        return Icons.school_rounded;
      case ExamTypeEnum.labPractical:
        return Icons.biotech_rounded;
      case ExamTypeEnum.oralPresentation:
        return Icons.record_voice_over_outlined;
    }
  }
}

class ExamModel {
  final String id;
  final String userId;
  final String? subjectId;
  final String? subjectCode;
  final String? subjectName;
  final String? subjectColor;
  final String title;
  final ExamTypeEnum examType;
  final DateTime dateTime;
  final int durationMinutes;
  final String location;
  final String? seatNumber;
  final List<String> syllabusTopics;
  final double? weightPercentage;
  final double? targetGrade;
  final double? actualGrade;
  final String notes;
  final bool isCompleted;
  final String countdownText;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamModel({
    required this.id,
    required this.userId,
    this.subjectId,
    this.subjectCode,
    this.subjectName,
    this.subjectColor,
    required this.title,
    this.examType = ExamTypeEnum.midterm,
    required this.dateTime,
    this.durationMinutes = 60,
    this.location = '',
    this.seatNumber,
    this.syllabusTopics = const [],
    this.weightPercentage,
    this.targetGrade,
    this.actualGrade,
    this.notes = '',
    this.isCompleted = false,
    this.countdownText = '',
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes mins';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return mins == 0 ? '$hours hrs' : '$hours hrs $mins mins';
  }

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String?,
      subjectCode: json['subject_code'] as String?,
      subjectName: json['subject_name'] as String?,
      subjectColor: json['subject_color'] as String?,
      title: json['title'] as String? ?? '',
      examType: ExamTypeEnum.fromString(json['exam_type'] as String? ?? 'midterm'),
      dateTime: DateTime.parse(json['date_time'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      location: json['location'] as String? ?? '',
      seatNumber: json['seat_number'] as String?,
      syllabusTopics: (json['syllabus_topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      weightPercentage: (json['weight_percentage'] as num?)?.toDouble(),
      targetGrade: (json['target_grade'] as num?)?.toDouble(),
      actualGrade: (json['actual_grade'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      countdownText: json['countdown_text'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'title': title,
      'exam_type': examType.value,
      'date_time': dateTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'location': location,
      'seat_number': seatNumber,
      'syllabus_topics': syllabusTopics,
      'weight_percentage': weightPercentage,
      'target_grade': targetGrade,
      'actual_grade': actualGrade,
      'notes': notes,
    };
  }

  ExamModel copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? subjectCode,
    String? subjectName,
    String? subjectColor,
    String? title,
    ExamTypeEnum? examType,
    DateTime? dateTime,
    int? durationMinutes,
    String? location,
    String? seatNumber,
    List<String>? syllabusTopics,
    double? weightPercentage,
    double? targetGrade,
    double? actualGrade,
    String? notes,
    bool? isCompleted,
    String? countdownText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      subjectColor: subjectColor ?? this.subjectColor,
      title: title ?? this.title,
      examType: examType ?? this.examType,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      seatNumber: seatNumber ?? this.seatNumber,
      syllabusTopics: syllabusTopics ?? this.syllabusTopics,
      weightPercentage: weightPercentage ?? this.weightPercentage,
      targetGrade: targetGrade ?? this.targetGrade,
      actualGrade: actualGrade ?? this.actualGrade,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      countdownText: countdownText ?? this.countdownText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ExamListResponseModel {
  final List<ExamModel> items;
  final int total;
  final int upcomingCount;
  final int completedCount;

  ExamListResponseModel({
    required this.items,
    required this.total,
    required this.upcomingCount,
    required this.completedCount,
  });

  factory ExamListResponseModel.fromJson(Map<String, dynamic> json) {
    return ExamListResponseModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ExamModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      upcomingCount: json['upcoming_count'] as int? ?? 0,
      completedCount: json['completed_count'] as int? ?? 0,
    );
  }
}

class CalendarEventItemModel {
  final String id;
  final String type; // 'exam' or 'assignment'
  final String title;
  final DateTime dateTime;
  final String? subjectCode;
  final String? subjectName;
  final String? subjectColor;
  final String priorityOrType;
  final bool isCompleted;
  final String? locationOrDesc;

  CalendarEventItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.dateTime,
    this.subjectCode,
    this.subjectName,
    this.subjectColor,
    required this.priorityOrType,
    this.isCompleted = false,
    this.locationOrDesc,
  });

  bool get isExam => type == 'exam';
  bool get isAssignment => type == 'assignment';

  factory CalendarEventItemModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventItemModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'exam',
      title: json['title'] as String? ?? '',
      dateTime: DateTime.parse(json['date_time'] as String),
      subjectCode: json['subject_code'] as String?,
      subjectName: json['subject_name'] as String?,
      subjectColor: json['subject_color'] as String?,
      priorityOrType: json['priority_or_type'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      locationOrDesc: json['location_or_desc'] as String?,
    );
  }
}

class ExamCalendarResponseModel {
  final DateTime startDate;
  final DateTime endDate;
  final List<CalendarEventItemModel> events;
  final int totalEvents;

  ExamCalendarResponseModel({
    required this.startDate,
    required this.endDate,
    required this.events,
    required this.totalEvents,
  });

  factory ExamCalendarResponseModel.fromJson(Map<String, dynamic> json) {
    return ExamCalendarResponseModel(
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => CalendarEventItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalEvents: json['total_events'] as int? ?? 0,
    );
  }
}
