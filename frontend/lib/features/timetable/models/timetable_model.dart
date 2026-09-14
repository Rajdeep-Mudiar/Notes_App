import 'package:flutter/material.dart';

enum DayOfWeekEnum {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  static DayOfWeekEnum fromString(String val) {
    switch (val.toLowerCase()) {
      case 'tuesday':
        return DayOfWeekEnum.tuesday;
      case 'wednesday':
        return DayOfWeekEnum.wednesday;
      case 'thursday':
        return DayOfWeekEnum.thursday;
      case 'friday':
        return DayOfWeekEnum.friday;
      case 'saturday':
        return DayOfWeekEnum.saturday;
      case 'sunday':
        return DayOfWeekEnum.sunday;
      case 'monday':
      default:
        return DayOfWeekEnum.monday;
    }
  }

  String get value => name;

  String get label {
    switch (this) {
      case DayOfWeekEnum.monday:
        return 'Monday';
      case DayOfWeekEnum.tuesday:
        return 'Tuesday';
      case DayOfWeekEnum.wednesday:
        return 'Wednesday';
      case DayOfWeekEnum.thursday:
        return 'Thursday';
      case DayOfWeekEnum.friday:
        return 'Friday';
      case DayOfWeekEnum.saturday:
        return 'Saturday';
      case DayOfWeekEnum.sunday:
        return 'Sunday';
    }
  }

  String get shortLabel {
    switch (this) {
      case DayOfWeekEnum.monday:
        return 'Mon';
      case DayOfWeekEnum.tuesday:
        return 'Tue';
      case DayOfWeekEnum.wednesday:
        return 'Wed';
      case DayOfWeekEnum.thursday:
        return 'Thu';
      case DayOfWeekEnum.friday:
        return 'Fri';
      case DayOfWeekEnum.saturday:
        return 'Sat';
      case DayOfWeekEnum.sunday:
        return 'Sun';
    }
  }
}

enum ClassTypeEnum {
  lecture,
  lab,
  tutorial,
  seminar,
  workshop,
  other;

  static ClassTypeEnum fromString(String val) {
    switch (val.toLowerCase()) {
      case 'lab':
        return ClassTypeEnum.lab;
      case 'tutorial':
        return ClassTypeEnum.tutorial;
      case 'seminar':
        return ClassTypeEnum.seminar;
      case 'workshop':
        return ClassTypeEnum.workshop;
      case 'other':
        return ClassTypeEnum.other;
      case 'lecture':
      default:
        return ClassTypeEnum.lecture;
    }
  }

  String get value => name;

  String get label {
    switch (this) {
      case ClassTypeEnum.lecture:
        return 'Lecture';
      case ClassTypeEnum.lab:
        return 'Lab';
      case ClassTypeEnum.tutorial:
        return 'Tutorial';
      case ClassTypeEnum.seminar:
        return 'Seminar';
      case ClassTypeEnum.workshop:
        return 'Workshop';
      case ClassTypeEnum.other:
        return 'Class';
    }
  }

  Color get color {
    switch (this) {
      case ClassTypeEnum.lecture:
        return const Color(0xFF4F46E5); // Indigo
      case ClassTypeEnum.lab:
        return const Color(0xFF10B981); // Emerald
      case ClassTypeEnum.tutorial:
        return const Color(0xFF3B82F6); // Blue
      case ClassTypeEnum.seminar:
        return const Color(0xFF8B5CF6); // Purple
      case ClassTypeEnum.workshop:
        return const Color(0xFFF59E0B); // Amber
      case ClassTypeEnum.other:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData get icon {
    switch (this) {
      case ClassTypeEnum.lecture:
        return Icons.menu_book_rounded;
      case ClassTypeEnum.lab:
        return Icons.biotech_rounded;
      case ClassTypeEnum.tutorial:
        return Icons.group_work_outlined;
      case ClassTypeEnum.seminar:
        return Icons.record_voice_over_outlined;
      case ClassTypeEnum.workshop:
        return Icons.handyman_outlined;
      case ClassTypeEnum.other:
        return Icons.schedule_rounded;
    }
  }
}

enum AttendanceStatusEnum {
  present,
  absent,
  late,
  excused;

  static AttendanceStatusEnum fromString(String val) {
    switch (val.toLowerCase()) {
      case 'absent':
        return AttendanceStatusEnum.absent;
      case 'late':
        return AttendanceStatusEnum.late;
      case 'excused':
        return AttendanceStatusEnum.excused;
      case 'present':
      default:
        return AttendanceStatusEnum.present;
    }
  }

  String get value => name;

  String get label {
    switch (this) {
      case AttendanceStatusEnum.present:
        return 'Present';
      case AttendanceStatusEnum.absent:
        return 'Absent';
      case AttendanceStatusEnum.late:
        return 'Late';
      case AttendanceStatusEnum.excused:
        return 'Excused';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatusEnum.present:
        return const Color(0xFF10B981); // Emerald Green
      case AttendanceStatusEnum.absent:
        return const Color(0xFFEF4444); // Crimson Red
      case AttendanceStatusEnum.late:
        return const Color(0xFFF59E0B); // Amber
      case AttendanceStatusEnum.excused:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatusEnum.present:
        return Icons.check_circle_rounded;
      case AttendanceStatusEnum.absent:
        return Icons.cancel_rounded;
      case AttendanceStatusEnum.late:
        return Icons.schedule_rounded;
      case AttendanceStatusEnum.excused:
        return Icons.verified_user_rounded;
    }
  }
}

class TimetableSlotModel {
  final String id;
  final String userId;
  final String? subjectId;
  final String? subjectCode;
  final String? subjectName;
  final String? subjectColor;
  final String title;
  final DayOfWeekEnum dayOfWeek;
  final String startTime;
  final String endTime;
  final ClassTypeEnum classType;
  final String location;
  final String? professorName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimetableSlotModel({
    required this.id,
    required this.userId,
    this.subjectId,
    this.subjectCode,
    this.subjectName,
    this.subjectColor,
    required this.title,
    this.dayOfWeek = DayOfWeekEnum.monday,
    required this.startTime,
    required this.endTime,
    this.classType = ClassTypeEnum.lecture,
    this.location = '',
    this.professorName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get timeRangeFormatted => '$startTime - $endTime';

  Color get color {
    if (subjectColor != null && subjectColor!.isNotEmpty) {
      try {
        final hex = subjectColor!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return classType.color;
  }

  factory TimetableSlotModel.fromJson(Map<String, dynamic> json) {
    return TimetableSlotModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String?,
      subjectCode: json['subject_code'] as String?,
      subjectName: json['subject_name'] as String?,
      subjectColor: json['subject_color'] as String?,
      title: json['title'] as String? ?? '',
      dayOfWeek: DayOfWeekEnum.fromString(json['day_of_week'] as String? ?? 'monday'),
      startTime: json['start_time'] as String? ?? '09:00',
      endTime: json['end_time'] as String? ?? '10:00',
      classType: ClassTypeEnum.fromString(json['class_type'] as String? ?? 'lecture'),
      location: json['location'] as String? ?? '',
      professorName: json['professor_name'] as String?,
      notes: json['notes'] as String?,
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
      'day_of_week': dayOfWeek.value,
      'start_time': startTime,
      'end_time': endTime,
      'class_type': classType.value,
      'location': location,
      'professor_name': professorName,
      'notes': notes,
    };
  }
}

class TodayClassModel {
  final TimetableSlotModel slot;
  final String status; // 'ongoing', 'upcoming', 'completed'
  final String timeStatusText;
  final AttendanceStatusEnum? attendanceToday;
  final String? attendanceLogId;

  TodayClassModel({
    required this.slot,
    required this.status,
    required this.timeStatusText,
    this.attendanceToday,
    this.attendanceLogId,
  });

  bool get isOngoing => status == 'ongoing';
  bool get isUpcoming => status == 'upcoming';
  bool get isCompleted => status == 'completed';

  factory TodayClassModel.fromJson(Map<String, dynamic> json) {
    return TodayClassModel(
      slot: TimetableSlotModel.fromJson(json['slot'] as Map<String, dynamic>),
      status: json['status'] as String? ?? 'upcoming',
      timeStatusText: json['time_status_text'] as String? ?? '',
      attendanceToday: json['attendance_today'] != null
          ? AttendanceStatusEnum.fromString(json['attendance_today'] as String)
          : null,
      attendanceLogId: json['attendance_log_id'] as String?,
    );
  }
}

class TimetableWeeklyModel {
  final List<TimetableSlotModel> monday;
  final List<TimetableSlotModel> tuesday;
  final List<TimetableSlotModel> wednesday;
  final List<TimetableSlotModel> thursday;
  final List<TimetableSlotModel> friday;
  final List<TimetableSlotModel> saturday;
  final List<TimetableSlotModel> sunday;
  final int totalSlots;

  TimetableWeeklyModel({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.totalSlots,
  });

  List<TimetableSlotModel> getSlotsForDay(DayOfWeekEnum day) {
    switch (day) {
      case DayOfWeekEnum.monday:
        return monday;
      case DayOfWeekEnum.tuesday:
        return tuesday;
      case DayOfWeekEnum.wednesday:
        return wednesday;
      case DayOfWeekEnum.thursday:
        return thursday;
      case DayOfWeekEnum.friday:
        return friday;
      case DayOfWeekEnum.saturday:
        return saturday;
      case DayOfWeekEnum.sunday:
        return sunday;
    }
  }

  factory TimetableWeeklyModel.fromJson(Map<String, dynamic> json) {
    List<TimetableSlotModel> parseSlots(String key) {
      return (json[key] as List<dynamic>?)
              ?.map((e) => TimetableSlotModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    }

    return TimetableWeeklyModel(
      monday: parseSlots('monday'),
      tuesday: parseSlots('tuesday'),
      wednesday: parseSlots('wednesday'),
      thursday: parseSlots('thursday'),
      friday: parseSlots('friday'),
      saturday: parseSlots('saturday'),
      sunday: parseSlots('sunday'),
      totalSlots: json['total_slots'] as int? ?? 0,
    );
  }
}

class AttendanceLogModel {
  final String id;
  final String userId;
  final String? slotId;
  final String? subjectId;
  final String? subjectCode;
  final String? subjectName;
  final String? subjectColor;
  final DateTime date;
  final AttendanceStatusEnum status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceLogModel({
    required this.id,
    required this.userId,
    this.slotId,
    this.subjectId,
    this.subjectCode,
    this.subjectName,
    this.subjectColor,
    required this.date,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceLogModel.fromJson(Map<String, dynamic> json) {
    return AttendanceLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      slotId: json['slot_id'] as String?,
      subjectId: json['subject_id'] as String?,
      subjectCode: json['subject_code'] as String?,
      subjectName: json['subject_name'] as String?,
      subjectColor: json['subject_color'] as String?,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatusEnum.fromString(json['status'] as String? ?? 'present'),
      notes: json['notes'] as String?,
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
      'slot_id': slotId,
      'subject_id': subjectId,
      'date': date.toIso8601String().substring(0, 10),
      'status': status.value,
      'notes': notes,
    };
  }
}

class SubjectAttendanceStatsModel {
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String subjectColor;
  final int totalClasses;
  final int attendedClasses;
  final int absentClasses;
  final int lateClasses;
  final int excusedClasses;
  final double attendancePercentage;
  final double targetPercentage;
  final bool isCritical;
  final int safeBunks;
  final int classesNeededToTarget;

  SubjectAttendanceStatsModel({
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.subjectColor,
    required this.totalClasses,
    required this.attendedClasses,
    required this.absentClasses,
    required this.lateClasses,
    required this.excusedClasses,
    required this.attendancePercentage,
    this.targetPercentage = 75.0,
    required this.isCritical,
    required this.safeBunks,
    required this.classesNeededToTarget,
  });

  Color get color {
    try {
      final hex = subjectColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }

  factory SubjectAttendanceStatsModel.fromJson(Map<String, dynamic> json) {
    return SubjectAttendanceStatsModel(
      subjectId: json['subject_id'] as String,
      subjectCode: json['subject_code'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      subjectColor: json['subject_color'] as String? ?? '#4F46E5',
      totalClasses: json['total_classes'] as int? ?? 0,
      attendedClasses: json['attended_classes'] as int? ?? 0,
      absentClasses: json['absent_classes'] as int? ?? 0,
      lateClasses: json['late_classes'] as int? ?? 0,
      excusedClasses: json['excused_classes'] as int? ?? 0,
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble() ?? 100.0,
      targetPercentage: (json['target_percentage'] as num?)?.toDouble() ?? 75.0,
      isCritical: json['is_critical'] as bool? ?? false,
      safeBunks: json['safe_bunks'] as int? ?? 0,
      classesNeededToTarget: json['classes_needed_to_target'] as int? ?? 0,
    );
  }
}

class AttendanceSummaryModel {
  final int overallTotalClasses;
  final int overallAttendedClasses;
  final int overallAbsentClasses;
  final double overallPercentage;
  final double minimumRequiredPercentage;
  final int criticalSubjectsCount;
  final List<SubjectAttendanceStatsModel> subjectsStats;

  AttendanceSummaryModel({
    required this.overallTotalClasses,
    required this.overallAttendedClasses,
    required this.overallAbsentClasses,
    required this.overallPercentage,
    this.minimumRequiredPercentage = 75.0,
    required this.criticalSubjectsCount,
    required this.subjectsStats,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      overallTotalClasses: json['overall_total_classes'] as int? ?? 0,
      overallAttendedClasses: json['overall_attended_classes'] as int? ?? 0,
      overallAbsentClasses: json['overall_absent_classes'] as int? ?? 0,
      overallPercentage: (json['overall_percentage'] as num?)?.toDouble() ?? 100.0,
      minimumRequiredPercentage: (json['minimum_required_percentage'] as num?)?.toDouble() ?? 75.0,
      criticalSubjectsCount: json['critical_subjects_count'] as int? ?? 0,
      subjectsStats: (json['subjects_stats'] as List<dynamic>?)
              ?.map((e) => SubjectAttendanceStatsModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
