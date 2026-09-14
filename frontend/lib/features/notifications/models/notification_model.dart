import 'package:flutter/material.dart';

enum NotificationTypeEnum {
  assignmentDue(
    'assignment_due',
    'Assignment Due',
    Icons.assignment_late_rounded,
    Color(0xFF0EA5E9),
  ),
  examUpcoming(
    'exam_upcoming',
    'Exam Upcoming',
    Icons.event_note_rounded,
    Color(0xFFF59E0B),
  ),
  classStarting(
    'class_starting',
    'Class Starting',
    Icons.schedule_rounded,
    Color(0xFF8B5CF6),
  ),
  attendanceWarning(
    'attendance_warning',
    'Attendance Warning',
    Icons.warning_amber_rounded,
    Color(0xFFEF4444),
  ),
  gpaAlert(
    'gpa_alert',
    'GPA Alert',
    Icons.insights_rounded,
    Color(0xFF10B981),
  ),
  system(
    'system',
    'System Alert',
    Icons.notifications_active_rounded,
    Color(0xFF4F46E5),
  );

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const NotificationTypeEnum(this.value, this.label, this.icon, this.color);

  static NotificationTypeEnum fromString(String val) {
    return NotificationTypeEnum.values.firstWhere(
      (e) => e.value == val,
      orElse: () => NotificationTypeEnum.system,
    );
  }
}

enum NotificationPriorityEnum {
  high('high', 'High', Color(0xFFEF4444)),
  normal('normal', 'Normal', Color(0xFF3B82F6)),
  low('low', 'Low', Color(0xFF6B7280));

  final String value;
  final String label;
  final Color color;

  const NotificationPriorityEnum(this.value, this.label, this.color);

  static NotificationPriorityEnum fromString(String val) {
    return NotificationPriorityEnum.values.firstWhere(
      (e) => e.value == val,
      orElse: () => NotificationPriorityEnum.normal,
    );
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationTypeEnum type;
  final String title;
  final String message;
  final NotificationPriorityEnum priority;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.priority = NotificationPriorityEnum.normal,
    this.isRead = false,
    this.actionRoute,
    this.metadata = const {},
    required this.createdAt,
    this.readAt,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: NotificationTypeEnum.fromString(json['type'] ?? 'system'),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: NotificationPriorityEnum.fromString(json['priority'] ?? 'normal'),
      isRead: json['is_read'] ?? false,
      actionRoute: json['action_route'],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'title': title,
      'message': message,
      'priority': priority.value,
      'is_read': isRead,
      'action_route': actionRoute,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }
}

class NotificationListResponseModel {
  final List<NotificationModel> items;
  final int total;
  final int unreadCount;

  NotificationListResponseModel({
    required this.items,
    required this.total,
    required this.unreadCount,
  });

  factory NotificationListResponseModel.fromJson(Map<String, dynamic> json) {
    return NotificationListResponseModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'total': total,
      'unread_count': unreadCount,
    };
  }
}
