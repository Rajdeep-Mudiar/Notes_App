import 'package:flutter/material.dart';

enum AssignmentPriority {
  low,
  medium,
  high,
  urgent;

  static AssignmentPriority fromString(String val) {
    switch (val.toLowerCase()) {
      case 'low':
        return AssignmentPriority.low;
      case 'high':
        return AssignmentPriority.high;
      case 'urgent':
        return AssignmentPriority.urgent;
      case 'medium':
      default:
        return AssignmentPriority.medium;
    }
  }

  String get value => name;

  String get label {
    switch (this) {
      case AssignmentPriority.low:
        return 'Low';
      case AssignmentPriority.medium:
        return 'Medium';
      case AssignmentPriority.high:
        return 'High';
      case AssignmentPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case AssignmentPriority.low:
        return const Color(0xFF10B981); // Emerald Green
      case AssignmentPriority.medium:
        return const Color(0xFF3B82F6); // Blue
      case AssignmentPriority.high:
        return const Color(0xFFF59E0B); // Amber
      case AssignmentPriority.urgent:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case AssignmentPriority.low:
        return Icons.arrow_downward_rounded;
      case AssignmentPriority.medium:
        return Icons.remove_rounded;
      case AssignmentPriority.high:
        return Icons.arrow_upward_rounded;
      case AssignmentPriority.urgent:
        return Icons.priority_high_rounded;
    }
  }
}

enum AssignmentStatus {
  pending,
  inProgress,
  submitted,
  graded;

  static AssignmentStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        return AssignmentStatus.inProgress;
      case 'submitted':
        return AssignmentStatus.submitted;
      case 'graded':
        return AssignmentStatus.graded;
      case 'pending':
      default:
        return AssignmentStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case AssignmentStatus.inProgress:
        return 'in_progress';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case AssignmentStatus.pending:
        return 'To-Do';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.graded:
        return 'Graded';
    }
  }

  Color get color {
    switch (this) {
      case AssignmentStatus.pending:
        return const Color(0xFF6B7280); // Slate Grey
      case AssignmentStatus.inProgress:
        return const Color(0xFF6366F1); // Indigo
      case AssignmentStatus.submitted:
        return const Color(0xFF06B6D4); // Cyan
      case AssignmentStatus.graded:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  IconData get icon {
    switch (this) {
      case AssignmentStatus.pending:
        return Icons.radio_button_unchecked_rounded;
      case AssignmentStatus.inProgress:
        return Icons.timelapse_rounded;
      case AssignmentStatus.submitted:
        return Icons.task_alt_rounded;
      case AssignmentStatus.graded:
        return Icons.verified_rounded;
    }
  }
}

class AssignmentModel {
  final String id;
  final String userId;
  final String? subjectId;
  final String? subjectCode;
  final String? subjectName;
  final String? subjectColor;
  final String title;
  final String description;
  final DateTime dueDate;
  final AssignmentPriority priority;
  final AssignmentStatus status;
  final double? weightPercentage;
  final double? gradeReceived;
  final String? feedback;
  final List<String> fileIds;
  final bool isOverdue;
  final String countdownText;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssignmentModel({
    required this.id,
    required this.userId,
    this.subjectId,
    this.subjectCode,
    this.subjectName,
    this.subjectColor,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.priority = AssignmentPriority.medium,
    this.status = AssignmentStatus.pending,
    this.weightPercentage,
    this.gradeReceived,
    this.feedback,
    this.fileIds = const [],
    this.isOverdue = false,
    this.countdownText = '',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted =>
      status == AssignmentStatus.submitted || status == AssignmentStatus.graded;

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String?,
      subjectCode: json['subject_code'] as String?,
      subjectName: json['subject_name'] as String?,
      subjectColor: json['subject_color'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: DateTime.parse(json['due_date'] as String),
      priority: AssignmentPriority.fromString(json['priority'] as String? ?? 'medium'),
      status: AssignmentStatus.fromString(json['status'] as String? ?? 'pending'),
      weightPercentage: (json['weight_percentage'] as num?)?.toDouble(),
      gradeReceived: (json['grade_received'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      fileIds: (json['file_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isOverdue: json['is_overdue'] as bool? ?? false,
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
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'priority': priority.value,
      'status': status.value,
      'weight_percentage': weightPercentage,
      'grade_received': gradeReceived,
      'feedback': feedback,
      'file_ids': fileIds,
    };
  }

  AssignmentModel copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? subjectCode,
    String? subjectName,
    String? subjectColor,
    String? title,
    String? description,
    DateTime? dueDate,
    AssignmentPriority? priority,
    AssignmentStatus? status,
    double? weightPercentage,
    double? gradeReceived,
    String? feedback,
    List<String>? fileIds,
    bool? isOverdue,
    String? countdownText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      subjectColor: subjectColor ?? this.subjectColor,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      weightPercentage: weightPercentage ?? this.weightPercentage,
      gradeReceived: gradeReceived ?? this.gradeReceived,
      feedback: feedback ?? this.feedback,
      fileIds: fileIds ?? this.fileIds,
      isOverdue: isOverdue ?? this.isOverdue,
      countdownText: countdownText ?? this.countdownText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AssignmentListResponseModel {
  final List<AssignmentModel> items;
  final int total;
  final int pendingCount;
  final int inProgressCount;
  final int submittedCount;
  final int gradedCount;
  final int urgentCount;

  AssignmentListResponseModel({
    required this.items,
    required this.total,
    required this.pendingCount,
    required this.inProgressCount,
    required this.submittedCount,
    required this.gradedCount,
    required this.urgentCount,
  });

  factory AssignmentListResponseModel.fromJson(Map<String, dynamic> json) {
    return AssignmentListResponseModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      pendingCount: json['pending_count'] as int? ?? 0,
      inProgressCount: json['in_progress_count'] as int? ?? 0,
      submittedCount: json['submitted_count'] as int? ?? 0,
      gradedCount: json['graded_count'] as int? ?? 0,
      urgentCount: json['urgent_count'] as int? ?? 0,
    );
  }
}

class AssignmentSummaryModel {
  final int totalAssignments;
  final int pendingCount;
  final int inProgressCount;
  final int submittedCount;
  final int gradedCount;
  final int overdueCount;
  final int dueThisWeekCount;

  AssignmentSummaryModel({
    required this.totalAssignments,
    required this.pendingCount,
    required this.inProgressCount,
    required this.submittedCount,
    required this.gradedCount,
    required this.overdueCount,
    required this.dueThisWeekCount,
  });

  factory AssignmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSummaryModel(
      totalAssignments: json['total_assignments'] as int? ?? 0,
      pendingCount: json['pending_count'] as int? ?? 0,
      inProgressCount: json['in_progress_count'] as int? ?? 0,
      submittedCount: json['submitted_count'] as int? ?? 0,
      gradedCount: json['graded_count'] as int? ?? 0,
      overdueCount: json['overdue_count'] as int? ?? 0,
      dueThisWeekCount: json['due_this_week_count'] as int? ?? 0,
    );
  }
}
