import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/assignments/models/assignment_model.dart';
import 'package:frontend/features/auth/models/auth_state.dart';
import 'package:frontend/features/auth/models/user_model.dart';
import 'package:frontend/features/exams/models/exam_model.dart';
import 'package:frontend/features/files/models/file_model.dart';
import 'package:frontend/features/notes/models/note_model.dart';
import 'package:frontend/features/subjects/models/subject_model.dart';
import 'package:frontend/features/timetable/models/timetable_model.dart';
import 'package:frontend/features/analytics/models/analytics_model.dart';
import 'package:frontend/features/notifications/models/notification_model.dart';
import 'package:frontend/features/ingestion/models/ingestion_model.dart';
import 'package:frontend/features/ai/models/ai_model.dart';

void main() {
  test('UserModel serialization and deserialization test', () {

    final user = UserModel(
      id: 'test_id_123',
      email: 'student@stanford.edu',
      fullName: 'Alex Rivera',
      university: 'Stanford University',
      degree: 'B.S. Computer Science',
      currentSemester: 4,
    );

    final json = user.toJson();
    expect(json['id'], 'test_id_123');
    expect(json['email'], 'student@stanford.edu');
    expect(json['full_name'], 'Alex Rivera');
    expect(json['university'], 'Stanford University');
    expect(json['current_semester'], 4);

    final reconstructed = UserModel.fromJson(json);
    expect(reconstructed.id, user.id);
    expect(reconstructed.email, user.email);
    expect(reconstructed.fullName, user.fullName);
    expect(reconstructed.university, user.university);
  });

  test('SubjectModel serialization and helpers test', () {
    final subject = SubjectModel(
      id: 'sub_123',
      userId: 'user_456',
      name: 'Data Structures & Algorithms',
      code: 'CS204',
      professor: 'Dr. Alan Turing',
      credits: 4,
      colorHex: '#4F46E5',
      icon: 'code',
      description: 'Trees, graphs, and complexity.',
      semester: 4,
    );

    final json = subject.toJson();
    expect(json['name'], 'Data Structures & Algorithms');
    expect(json['code'], 'CS204');
    expect(json['credits'], 4);
    expect(json['color'], '#4F46E5');

    final reconstructed = SubjectModel.fromJson({
      'id': 'sub_123',
      'user_id': 'user_456',
      ...json,
      'notes_count': 5,
      'files_count': 2,
    });

    expect(reconstructed.id, 'sub_123');
    expect(reconstructed.code, 'CS204');
    expect(reconstructed.notesCount, 5);
    expect(reconstructed.filesCount, 2);
    expect(reconstructed.color.toARGB32(), isNotNull);
    expect(reconstructed.iconData, isNotNull);
  });

  test('AcademicSummaryModel deserialization test', () {
    final summary = AcademicSummaryModel.fromJson({
      'total_subjects': 5,
      'active_subjects': 4,
      'archived_subjects': 1,
      'total_credits': 16,
      'current_semester': 4,
      'semester_credits': 16,
    });

    expect(summary.totalSubjects, 5);
    expect(summary.activeSubjects, 4);
    expect(summary.totalCredits, 16);
    expect(summary.currentSemester, 4);
  });

  test('NoteBlockModel and NoteModel serialization test', () {
    final block1 = NoteBlockModel(
      id: 'b1',
      type: BlockType.heading1,
      content: 'Binary Search Trees',
      order: 0,
    );
    final block2 = NoteBlockModel(
      id: 'b2',
      type: BlockType.code,
      content: 'def insert(node, val): return Node(val)',
      order: 1,
      properties: {'language': 'python'},
    );
    final block3 = NoteBlockModel(
      id: 'b3',
      type: BlockType.checklist,
      content: 'Review AVL rotation properties',
      order: 2,
      properties: {'checked': true},
    );

    final note = NoteModel(
      id: 'note_999',
      userId: 'user_123',
      subjectId: 'sub_123',
      title: 'Trees and Balanced BSTs',
      blocks: [block1, block2, block3],
      tags: ['midterm', 'algorithms', 'trees'],
      isPinned: true,
      isFavorite: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      previewSnippet: 'Binary Search Trees...',
    );

    final json = note.toJson();
    expect(json['title'], 'Trees and Balanced BSTs');
    expect(json['subject_id'], 'sub_123');
    expect(json['tags'], contains('midterm'));
    expect(json['blocks'].length, 3);
    expect(json['blocks'][1]['properties']['language'], 'python');
    expect(json['blocks'][2]['properties']['checked'], true);

    final reconstructed = NoteModel.fromJson({
      'id': 'note_999',
      'user_id': 'user_123',
      ...json,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    expect(reconstructed.id, 'note_999');
    expect(reconstructed.blocks.length, 3);
    expect(reconstructed.blocks[0].type, BlockType.heading1);
    expect(reconstructed.blocks[1].properties['language'], 'python');
    expect(reconstructed.isPinned, true);
  });

  test('FileModel, FolderModel, and StorageSummaryModel serialization test', () {
    final folder = FolderModel(
      id: 'folder_01',
      userId: 'user_123',
      name: 'Lecture Slides',
      subjectId: 'sub_123',
      colorHex: '#10B981',
      itemsCount: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final folderJson = folder.toJson();
    expect(folderJson['name'], 'Lecture Slides');
    expect(folderJson['subject_id'], 'sub_123');
    expect(folder.color.toARGB32(), isNotNull);

    final file = FileModel(
      id: 'file_01',
      userId: 'user_123',
      subjectId: 'sub_123',
      folderId: 'folder_01',
      filename: 'uuid123_lecture1.pdf',
      originalName: 'Lecture01_Intro.pdf',
      fileType: FileTypeEnum.pdf,
      mimeType: 'application/pdf',
      sizeBytes: 2048576,
      sizeFormatted: '2.0 MB',
      downloadUrl: '/api/v1/files/file_01/download',
      isFavorite: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    expect(file.fileExtension, 'PDF');
    expect(file.fileType.label, 'PDF');
    expect(file.fileType.color.toARGB32(), isNotNull);

    final fileJson = file.toJson();
    final reconstructedFile = FileModel.fromJson(fileJson);
    expect(reconstructedFile.id, 'file_01');
    expect(reconstructedFile.fileType, FileTypeEnum.pdf);
    expect(reconstructedFile.isFavorite, true);

    final storage = StorageSummaryModel.fromJson({
      'used_bytes': 2048576,
      'used_formatted': '2.0 MB',
      'total_limit_bytes': 524288000,
      'total_limit_formatted': '500.0 MB',
      'percentage_used': 0.39,
      'files_count': 1,
      'by_type': {'pdf': 2048576},
    });

    expect(storage.usedBytes, 2048576);
    expect(storage.filesCount, 1);
    expect(storage.byType['pdf'], 2048576);
  });

  test('AssignmentModel, Enums, and Planner Summary serialization test', () {
    final assignment = AssignmentModel(
      id: 'asgn_101',
      userId: 'user_123',
      subjectId: 'sub_123',
      subjectCode: 'CS301',
      subjectName: 'Operating Systems',
      subjectColor: '#3B82F6',
      title: 'Memory Allocator Lab',
      description: 'Implement buddy allocator with slab caching in C.',
      dueDate: DateTime.parse('2026-09-20T23:59:59Z'),
      priority: AssignmentPriority.urgent,
      status: AssignmentStatus.inProgress,
      weightPercentage: 25.0,
      gradeReceived: 95.0,
      feedback: 'Excellent test coverage.',
      fileIds: ['f1', 'f2'],
      isOverdue: false,
      countdownText: 'Due in 6 days',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    expect(assignment.priority, AssignmentPriority.urgent);
    expect(assignment.priority.label, 'Urgent');
    expect(assignment.priority.color.toARGB32(), isNotNull);
    expect(assignment.status, AssignmentStatus.inProgress);
    expect(assignment.status.label, 'In Progress');
    expect(assignment.isCompleted, false);

    final json = assignment.toJson();
    expect(json['title'], 'Memory Allocator Lab');
    expect(json['priority'], 'urgent');
    expect(json['status'], 'in_progress');
    expect(json['weight_percentage'], 25.0);

    final reconstructed = AssignmentModel.fromJson({
      ...json,
      'subject_code': 'CS301',
      'subject_name': 'Operating Systems',
      'subject_color': '#3B82F6',
      'is_overdue': false,
      'countdown_text': 'Due in 6 days',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    expect(reconstructed.id, 'asgn_101');
    expect(reconstructed.subjectCode, 'CS301');
    expect(reconstructed.priority, AssignmentPriority.urgent);
    expect(reconstructed.countdownText, 'Due in 6 days');

    final summary = AssignmentSummaryModel.fromJson({
      'total_assignments': 12,
      'pending_count': 4,
      'in_progress_count': 3,
      'submitted_count': 3,
      'graded_count': 2,
      'overdue_count': 1,
      'due_this_week_count': 2,
    });

    expect(summary.totalAssignments, 12);
    expect(summary.pendingCount, 4);
    expect(summary.inProgressCount, 3);
    expect(summary.overdueCount, 1);
    expect(summary.dueThisWeekCount, 2);
  });

  test('ExamModel, ExamTypeEnum, and Study Calendar serialization test', () {
    final exam = ExamModel(
      id: 'exam_201',
      userId: 'user_123',
      subjectId: 'sub_123',
      subjectCode: 'CS301',
      subjectName: 'Operating Systems',
      subjectColor: '#3B82F6',
      title: 'Operating Systems Midterm Exam',
      examType: ExamTypeEnum.midterm,
      dateTime: DateTime.parse('2026-10-15T09:00:00Z'),
      durationMinutes: 120,
      location: 'Turing Hall A',
      seatNumber: 'B-14',
      syllabusTopics: ['Virtual Memory', 'Page Tables', 'Deadlocks', 'Semaphores'],
      weightPercentage: 30.0,
      targetGrade: 90.0,
      actualGrade: 94.5,
      notes: 'Bring non-programmable calculator.',
      isCompleted: false,
      countdownText: 'In 30 days',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    expect(exam.examType, ExamTypeEnum.midterm);
    expect(exam.examType.label, 'Midterm Exam');
    expect(exam.examType.value, 'midterm');
    expect(exam.examType.color.toARGB32(), isNotNull);
    expect(exam.examType.icon, isNotNull);
    expect(exam.formattedDuration, '2 hrs');

    final json = exam.toJson();
    expect(json['title'], 'Operating Systems Midterm Exam');
    expect(json['exam_type'], 'midterm');
    expect(json['duration_minutes'], 120);
    expect(json['location'], 'Turing Hall A');
    expect(json['seat_number'], 'B-14');
    expect(json['weight_percentage'], 30.0);
    expect(json['target_grade'], 90.0);
    expect(json['actual_grade'], 94.5);

    final reconstructed = ExamModel.fromJson({
      ...json,
      'subject_code': 'CS301',
      'subject_name': 'Operating Systems',
      'subject_color': '#3B82F6',
      'is_completed': false,
      'countdown_text': 'In 30 days',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    expect(reconstructed.id, 'exam_201');
    expect(reconstructed.syllabusTopics.length, 4);
    expect(reconstructed.countdownText, 'In 30 days');

    final examListResp = ExamListResponseModel.fromJson({
      'items': [reconstructed.toJson()],
      'total': 1,
      'upcoming_count': 1,
      'completed_count': 0,
    });
    expect(examListResp.total, 1);
    expect(examListResp.upcomingCount, 1);

    final calendarEvent = CalendarEventItemModel.fromJson({
      'id': 'exam_201',
      'type': 'exam',
      'title': 'Operating Systems Midterm Exam',
      'date_time': '2026-10-15T09:00:00Z',
      'subject_code': 'CS301',
      'subject_name': 'Operating Systems',
      'subject_color': '#3B82F6',
      'priority_or_type': 'midterm',
      'is_completed': false,
      'location_or_desc': 'Turing Hall A (Seat: B-14)',
    });
    expect(calendarEvent.isExam, true);
    expect(calendarEvent.isAssignment, false);
    expect(calendarEvent.locationOrDesc, 'Turing Hall A (Seat: B-14)');

    final calendarResp = ExamCalendarResponseModel.fromJson({
      'start_date': '2026-10-01T00:00:00Z',
      'end_date': '2026-10-31T23:59:59Z',
      'events': [
        {
          'id': 'exam_201',
          'type': 'exam',
          'title': 'Operating Systems Midterm Exam',
          'date_time': '2026-10-15T09:00:00Z',
          'subject_code': 'CS301',
          'subject_name': 'Operating Systems',
          'subject_color': '#3B82F6',
          'priority_or_type': 'midterm',
          'is_completed': false,
          'location_or_desc': 'Turing Hall A (Seat: B-14)',
        }
      ],
      'total_events': 1,
    });
    expect(calendarResp.totalEvents, 1);
    expect(calendarResp.events.first.title, 'Operating Systems Midterm Exam');
  });

  test('TimetableSlotModel, AttendanceLogModel, and AttendanceSummaryModel serialization test', () {
    final slot = TimetableSlotModel(
      id: 'slot_101',
      userId: 'user_123',
      subjectId: 'sub_123',
      subjectCode: 'CS161',
      subjectName: 'Design & Analysis of Algorithms',
      subjectColor: '#4F46E5',
      title: 'Algorithms Lecture',
      dayOfWeek: DayOfWeekEnum.monday,
      startTime: '09:00',
      endTime: '10:30',
      classType: ClassTypeEnum.lecture,
      location: 'Skilling Auditorium 080',
      professorName: 'Dr. Tim Roughgarden',
      notes: 'Bring lecture notebook',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    expect(slot.dayOfWeek, DayOfWeekEnum.monday);
    expect(slot.dayOfWeek.label, 'Monday');
    expect(slot.dayOfWeek.shortLabel, 'Mon');
    expect(slot.classType, ClassTypeEnum.lecture);
    expect(slot.classType.label, 'Lecture');
    expect(slot.timeRangeFormatted, '09:00 - 10:30');
    expect(slot.color.toARGB32(), isNotNull);

    final json = slot.toJson();
    expect(json['title'], 'Algorithms Lecture');
    expect(json['day_of_week'], 'monday');
    expect(json['start_time'], '09:00');
    expect(json['end_time'], '10:30');
    expect(json['class_type'], 'lecture');

    final reconstructedSlot = TimetableSlotModel.fromJson({
      ...json,
      'subject_code': 'CS161',
      'subject_name': 'Design & Analysis of Algorithms',
      'subject_color': '#4F46E5',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    expect(reconstructedSlot.id, 'slot_101');
    expect(reconstructedSlot.subjectCode, 'CS161');

    final todayClass = TodayClassModel.fromJson({
      'slot': reconstructedSlot.toJson(),
      'status': 'ongoing',
      'time_status_text': 'Happening now (ends in 15 mins)',
      'attendance_today': 'present',
      'attendance_log_id': 'att_999',
    });
    expect(todayClass.isOngoing, true);
    expect(todayClass.isUpcoming, false);
    expect(todayClass.attendanceToday, AttendanceStatusEnum.present);
    expect(todayClass.attendanceToday?.label, 'Present');

    final weekly = TimetableWeeklyModel.fromJson({
      'monday': [reconstructedSlot.toJson()],
      'tuesday': [],
      'wednesday': [],
      'thursday': [],
      'friday': [],
      'saturday': [],
      'sunday': [],
      'total_slots': 1,
    });
    expect(weekly.totalSlots, 1);
    expect(weekly.getSlotsForDay(DayOfWeekEnum.monday).length, 1);
    expect(weekly.getSlotsForDay(DayOfWeekEnum.tuesday).length, 0);

    final attLog = AttendanceLogModel.fromJson({
      'id': 'att_001',
      'user_id': 'user_123',
      'slot_id': 'slot_101',
      'subject_id': 'sub_123',
      'subject_code': 'CS161',
      'subject_name': 'Design & Analysis of Algorithms',
      'date': '2026-09-14',
      'status': 'present',
      'notes': 'Attended on time.',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    expect(attLog.id, 'att_001');
    expect(attLog.status, AttendanceStatusEnum.present);
    expect(attLog.status.color.toARGB32(), isNotNull);

    final stats = SubjectAttendanceStatsModel.fromJson({
      'subject_id': 'sub_123',
      'subject_code': 'CS161',
      'subject_name': 'Design & Analysis of Algorithms',
      'subject_color': '#4F46E5',
      'total_classes': 10,
      'attended_classes': 9,
      'absent_classes': 1,
      'late_classes': 0,
      'excused_classes': 0,
      'attendance_percentage': 90.0,
      'target_percentage': 75.0,
      'is_critical': false,
      'safe_bunks': 2,
      'classes_needed_to_target': 0,
    });
    expect(stats.attendancePercentage, 90.0);
    expect(stats.isCritical, false);
    expect(stats.safeBunks, 2);

    final summary = AttendanceSummaryModel.fromJson({
      'overall_total_classes': 10,
      'overall_attended_classes': 9,
      'overall_absent_classes': 1,
      'overall_percentage': 90.0,
      'minimum_required_percentage': 75.0,
      'critical_subjects_count': 0,
      'subjects_stats': [
        {
          'subject_id': 'sub_123',
          'subject_code': 'CS161',
          'subject_name': 'Design & Analysis of Algorithms',
          'subject_color': '#4F46E5',
          'total_classes': 10,
          'attended_classes': 9,
          'absent_classes': 1,
          'late_classes': 0,
          'excused_classes': 0,
          'attendance_percentage': 90.0,
          'target_percentage': 75.0,
          'is_critical': false,
          'safe_bunks': 2,
          'classes_needed_to_target': 0,
        }
      ],
    });
    expect(summary.overallPercentage, 90.0);
    expect(summary.criticalSubjectsCount, 0);
    expect(summary.subjectsStats.length, 1);
  });

  test('SubjectGradeModel, SemesterGpaModel, and GpaSummaryModel serialization test', () {
    final grade = SubjectGradeModel(
      subjectId: 'sub_101',
      subjectCode: 'CS106B',
      subjectName: 'Programming Abstractions',
      subjectColor: '#4F46E5',
      semester: 1,
      credits: 5,
      letterGrade: 'A',
      numericalGrade: 92.0,
      gradePoint: 4.0,
      targetGrade: 'A',
      isGraded: true,
    );

    expect(grade.subjectCode, 'CS106B');
    expect(grade.letterGrade, 'A');
    expect(grade.gradePoint, 4.0);
    expect(grade.isGraded, true);

    final json = grade.toJson();
    expect(json['subject_id'], 'sub_101');
    expect(json['letter_grade'], 'A');
    expect(json['grade_point'], 4.0);

    final reconstructed = SubjectGradeModel.fromJson(json);
    expect(reconstructed.subjectId, 'sub_101');
    expect(reconstructed.credits, 5);
    expect(reconstructed.isGraded, true);

    final semesterGpa = SemesterGpaModel.fromJson({
      'semester': 1,
      'semester_label': 'Semester 1',
      'total_credits': 15,
      'graded_credits': 15,
      'sgpa': 3.85,
      'subjects': [reconstructed.toJson()],
    });

    expect(semesterGpa.semester, 1);
    expect(semesterGpa.sgpa, 3.85);
    expect(semesterGpa.subjects.length, 1);
    expect(semesterGpa.subjects.first.subjectCode, 'CS106B');

    final gpaSummary = GpaSummaryModel.fromJson({
      'current_cgpa': 3.81,
      'target_cgpa': 3.90,
      'scale': 'scale_4_0',
      'total_enrolled_credits': 30,
      'total_earned_credits': 30,
      'graduation_required_credits': 120,
      'credits_progress_percentage': 25.0,
      'honors_standing': 'Magna Cum Laude',
      'academic_status': 'Good Standing',
      'semester_breakdown': [semesterGpa.toJson()],
      'highest_sgpa_semester': 1,
      'lowest_sgpa_semester': 1,
    });

    expect(gpaSummary.currentCgpa, 3.81);
    expect(gpaSummary.honorsStanding, 'Magna Cum Laude');
    expect(gpaSummary.creditsProgressPercentage, 25.0);
    expect(gpaSummary.semesterBreakdown.length, 1);
  });

  test('WhatIfCourseInputModel and WhatIfScenarioResponseModel serialization test', () {
    final whatIfCourse = WhatIfCourseInputModel(
      courseName: 'Deep Learning Lab',
      credits: 4,
      hypotheticalGrade: 'A',
    );

    final json = whatIfCourse.toJson();
    expect(json['course_name'], 'Deep Learning Lab');
    expect(json['credits'], 4);
    expect(json['hypothetical_grade'], 'A');

    final reconstructedCourse = WhatIfCourseInputModel.fromJson(json);
    expect(reconstructedCourse.courseName, 'Deep Learning Lab');
    expect(reconstructedCourse.credits, 4);

    final response = WhatIfScenarioResponseModel.fromJson({
      'baseline_cgpa': 3.81,
      'projected_cgpa': 3.87,
      'cgpa_difference': 0.06,
      'total_projected_credits': 27,
      'target_cgpa': 3.85,
      'target_achieved': true,
      'required_average_grade_point': 3.65,
      'projection_message': 'Target achieved! Your projected CGPA of 3.87 exceeds your goal.',
    });

    expect(response.baselineCgpa, 3.81);
    expect(response.projectedCgpa, 3.87);
    expect(response.cgpaDifference, 0.06);
    expect(response.targetAchieved, true);
    expect(response.projectionMessage, contains('Target achieved!'));
  });

  test('GradingScale enum helper tests', () {
    expect(GradingScale.fromString('scale_4_0'), GradingScale.scale40);
    expect(GradingScale.fromString('scale_10_0'), GradingScale.scale100);
    expect(GradingScale.fromString('percentage'), GradingScale.percentage);
    expect(GradingScale.fromString('unknown'), GradingScale.scale40);
  });

  test('NotificationModel, NotificationTypeEnum, and NotificationListResponseModel test', () {
    final notif = NotificationModel(
      id: 'notif_001',
      userId: 'user_123',
      type: NotificationTypeEnum.assignmentDue,
      priority: NotificationPriorityEnum.high,
      title: 'Assignment Due Tomorrow!',
      message: 'Operating Systems Lab 2 is due in 18 hours.',
      actionRoute: '/assignments',
      isRead: false,
      metadata: {'asgn_id': '101'},
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      readAt: null,
    );

    expect(notif.type, NotificationTypeEnum.assignmentDue);
    expect(notif.type.label, 'Assignment Due');
    expect(notif.type.color.toARGB32(), isNotNull);
    expect(notif.type.icon, isNotNull);

    expect(notif.priority, NotificationPriorityEnum.high);
    expect(notif.priority.label, 'High');
    expect(notif.priority.color.toARGB32(), isNotNull);
    expect(notif.timeAgo, '10m ago');

    final json = notif.toJson();
    expect(json['id'], 'notif_001');
    expect(json['type'], 'assignment_due');
    expect(json['priority'], 'high');
    expect(json['is_read'], false);
    expect(json['action_route'], '/assignments');

    final reconstructed = NotificationModel.fromJson(json);
    expect(reconstructed.id, 'notif_001');
    expect(reconstructed.type, NotificationTypeEnum.assignmentDue);
    expect(reconstructed.priority, NotificationPriorityEnum.high);
    expect(reconstructed.isRead, false);
    expect(reconstructed.actionRoute, '/assignments');

    final listResponse = NotificationListResponseModel.fromJson({
      'items': [json],
      'total': 1,
      'unread_count': 1,
    });
    expect(listResponse.total, 1);
    expect(listResponse.unreadCount, 1);
    expect(listResponse.items.first.title, 'Assignment Due Tomorrow!');

    // Test enum parsing fallbacks
    expect(NotificationTypeEnum.fromString('exam_upcoming'), NotificationTypeEnum.examUpcoming);
    expect(NotificationTypeEnum.fromString('class_starting'), NotificationTypeEnum.classStarting);
    expect(NotificationTypeEnum.fromString('attendance_warning'), NotificationTypeEnum.attendanceWarning);
    expect(NotificationTypeEnum.fromString('gpa_alert'), NotificationTypeEnum.gpaAlert);
    expect(NotificationTypeEnum.fromString('unknown_type'), NotificationTypeEnum.system);

    expect(NotificationPriorityEnum.fromString('high'), NotificationPriorityEnum.high);
    expect(NotificationPriorityEnum.fromString('normal'), NotificationPriorityEnum.normal);
    expect(NotificationPriorityEnum.fromString('low'), NotificationPriorityEnum.low);
    expect(NotificationPriorityEnum.fromString('unknown'), NotificationPriorityEnum.normal);
  });

  test('IngestionStatusModel, IngestionStatsModel, and SemanticSearchResponseModel test', () {
    final status = IngestionStatusModel(
      sourceId: 'src_001',
      sourceType: SourceTypeEnum.file,
      sourceName: 'Lecture01_Intro.pdf',
      status: IngestionStatusEnum.completed,
      chunksCount: 5,
      totalTokens: 620,
      updatedAt: DateTime.parse('2026-09-14T12:00:00Z'),
    );

    expect(status.sourceType, SourceTypeEnum.file);
    expect(status.sourceType.label, 'File');
    expect(status.status, IngestionStatusEnum.completed);
    expect(status.status.label, 'AI Indexed');
    expect(status.isCompleted, true);
    expect(status.isProcessing, false);
    expect(status.isFailed, false);

    final statusJson = status.toJson();
    expect(statusJson['source_id'], 'src_001');
    expect(statusJson['source_type'], 'file');
    expect(statusJson['status'], 'completed');
    expect(statusJson['chunks_count'], 5);

    final reconstructedStatus = IngestionStatusModel.fromJson(statusJson);
    expect(reconstructedStatus.sourceId, 'src_001');
    expect(reconstructedStatus.chunksCount, 5);
    expect(reconstructedStatus.isCompleted, true);

    final stats = IngestionStatsModel.fromJson({
      'total_chunks': 24,
      'total_indexed_files': 3,
      'total_indexed_notes': 5,
      'total_tokens_estimated': 3200,
      'by_subject': {'sub_101': 14, 'sub_102': 10},
      'by_type': {'file': 10, 'note': 14},
    });

    expect(stats.totalChunks, 24);
    expect(stats.totalIndexedFiles, 3);
    expect(stats.totalIndexedNotes, 5);
    expect(stats.totalIndexedSources, 8);
    expect(stats.bySubject['sub_101'], 14);
    expect(stats.byType['note'], 14);

    final searchResp = SemanticSearchResponseModel.fromJson({
      'query': 'gradient descent',
      'results_count': 1,
      'results': [
        {
          'chunk_id': 'chk_999',
          'source_id': 'src_001',
          'source_type': 'note',
          'source_name': 'Convex Optimization Notes',
          'subject_id': 'sub_101',
          'page_or_section': 'Section 2',
          'text_content': 'Gradient descent updates theta in the direction of negative gradient.',
          'similarity_score': 0.88,
          'metadata': {'pinned': true},
        }
      ],
    });

    expect(searchResp.query, 'gradient descent');
    expect(searchResp.resultsCount, 1);
    expect(searchResp.results.first.similarityScore, 0.88);
    expect(searchResp.results.first.sourceType, SourceTypeEnum.note);

    // Test enum fallbacks
    expect(SourceTypeEnum.fromString('file'), SourceTypeEnum.file);
    expect(SourceTypeEnum.fromString('note'), SourceTypeEnum.note);
    expect(SourceTypeEnum.fromString('unknown'), SourceTypeEnum.note);

    expect(IngestionStatusEnum.fromString('pending'), IngestionStatusEnum.pending);
    expect(IngestionStatusEnum.fromString('processing'), IngestionStatusEnum.processing);
    expect(IngestionStatusEnum.fromString('completed'), IngestionStatusEnum.completed);
    expect(IngestionStatusEnum.fromString('failed'), IngestionStatusEnum.failed);
    expect(IngestionStatusEnum.fromString('unknown'), IngestionStatusEnum.pending);
  });

  test('AI StudyModeEnum, CitationItemModel, and ChatMessageModel serialization test', () {
    expect(StudyModeEnum.chat.label, 'Ask AI');
    expect(StudyModeEnum.quiz.label, 'Practice Quiz');
    expect(StudyModeEnum.flashcards.label, 'Flashcards');
    expect(StudyModeEnum.summary.label, 'Exam Summary');
    expect(StudyModeEnum.fromString('quiz'), StudyModeEnum.quiz);
    expect(StudyModeEnum.fromString('flashcards'), StudyModeEnum.flashcards);
    expect(StudyModeEnum.fromString('summary'), StudyModeEnum.summary);
    expect(StudyModeEnum.fromString('unknown'), StudyModeEnum.chat);

    final citation = CitationItemModel(
      chunkId: 'chk_101',
      sourceId: 'file_202',
      sourceName: 'Distributed_Systems_Lec3.pdf',
      sourceType: SourceTypeEnum.file,
      subjectId: 'sub_301',
      pageOrSection: 'Page 12',
      snippet: 'Raft consensus algorithm uses leader election and log replication.',
      similarityScore: 0.92,
    );

    final citationJson = citation.toJson();
    expect(citationJson['chunk_id'], 'chk_101');
    expect(citationJson['source_type'], 'file');
    expect(citationJson['page_or_section'], 'Page 12');

    final reconstructedCitation = CitationItemModel.fromJson(citationJson);
    expect(reconstructedCitation.chunkId, 'chk_101');
    expect(reconstructedCitation.similarityScore, 0.92);
    expect(reconstructedCitation.sourceType, SourceTypeEnum.file);

    final message = ChatMessageModel(
      role: 'assistant',
      content: 'Raft achieves consensus via leader election [1].',
      citations: [reconstructedCitation],
      createdAt: DateTime.parse('2026-09-14T15:00:00Z'),
    );

    expect(message.isAssistant, true);
    expect(message.isUser, false);
    expect(message.citations.length, 1);

    final messageJson = message.toJson();
    expect(messageJson['role'], 'assistant');
    expect(messageJson['content'], contains('Raft achieves'));

    final reconstructedMsg = ChatMessageModel.fromJson(messageJson);
    expect(reconstructedMsg.role, 'assistant');
    expect(reconstructedMsg.citations.first.chunkId, 'chk_101');

    final chatResp = ChatResponseModel.fromJson({
      'session_id': 'sess_abc',
      'reply': 'Here is the explanation...',
      'citations': [citationJson],
      'mode': 'chat',
      'created_at': '2026-09-14T15:00:00Z',
    });
    expect(chatResp.sessionId, 'sess_abc');
    expect(chatResp.mode, StudyModeEnum.chat);
    expect(chatResp.citations.length, 1);
  });

  test('QuizQuestionModel and QuizResponseModel serialization and scoring logic test', () {
    final citation = CitationItemModel(
      chunkId: 'chk_101',
      sourceId: 'file_202',
      sourceName: 'Distributed_Systems_Lec3.pdf',
      sourceType: SourceTypeEnum.file,
      snippet: 'Raft uses leader election.',
      similarityScore: 0.92,
    );

    final question = QuizQuestionModel(
      id: 'q_01',
      question: 'What mechanism does Raft use to maintain state consistency across nodes?',
      options: [
        'Two-Phase Commit',
        'Log Replication and Leader Election',
        'Gossip Protocol',
        'Proof of Work',
      ],
      correctOptionIndex: 1,
      explanation: 'Raft manages replicated logs through an elected leader node.',
      citation: citation,
    );

    expect(question.isAnswered, false);
    expect(question.isCorrect, false);

    question.selectedOptionIndex = 1;
    expect(question.isAnswered, true);
    expect(question.isCorrect, true);

    question.selectedOptionIndex = 0;
    expect(question.isCorrect, false);

    final qJson = question.toJson();
    expect(qJson['id'], 'q_01');
    expect(qJson['correct_option_index'], 1);
    expect(qJson['options'].length, 4);

    final reconstructedQ = QuizQuestionModel.fromJson(qJson);
    expect(reconstructedQ.id, 'q_01');
    expect(reconstructedQ.explanation, contains('replicated logs'));
    expect(reconstructedQ.citation?.sourceName, 'Distributed_Systems_Lec3.pdf');

    final quizResp = QuizResponseModel.fromJson({
      'title': 'Distributed Systems Practice Quiz',
      'subject_id': 'sub_301',
      'questions': [qJson],
      'total_questions': 1,
      'created_at': '2026-09-14T15:00:00Z',
    });

    expect(quizResp.title, 'Distributed Systems Practice Quiz');
    expect(quizResp.totalQuestions, 1);
    expect(quizResp.questions.first.options.length, 4);
  });

  test('FlashcardItemModel, FlashcardResponseModel, and SummaryResponseModel test', () {
    final flashcard = FlashcardItemModel(
      id: 'fc_01',
      front: 'What is theCAP theorem?',
      back: 'A distributed data store can simultaneously provide at most two of Consistency, Availability, and Partition tolerance.',
      category: 'System Design',
      isMastered: false,
    );

    expect(flashcard.isMastered, false);
    flashcard.isMastered = true;
    expect(flashcard.isMastered, true);

    final fcJson = flashcard.toJson();
    expect(fcJson['id'], 'fc_01');
    expect(fcJson['category'], 'System Design');
    expect(fcJson['is_mastered'], true);

    final reconstructedFc = FlashcardItemModel.fromJson(fcJson);
    expect(reconstructedFc.front, contains('CAP theorem'));
    expect(reconstructedFc.isMastered, true);

    final fcDeck = FlashcardResponseModel.fromJson({
      'title': 'Distributed Systems Flashcards',
      'subject_id': 'sub_301',
      'cards': [fcJson],
      'total_cards': 1,
      'created_at': '2026-09-14T15:00:00Z',
    });

    expect(fcDeck.title, 'Distributed Systems Flashcards');
    expect(fcDeck.totalCards, 1);
    expect(fcDeck.cards.first.category, 'System Design');

    final summary = SummaryResponseModel.fromJson({
      'title': 'Exam High-Yield Summary: Distributed Consensus',
      'subject_id': 'sub_301',
      'overview': 'Consensus algorithms guarantee safety and liveness under asynchronous networks.',
      'key_concepts': ['Paxos vs Raft', 'State Machine Replication', 'Byzantine Fault Tolerance'],
      'important_formulas_or_takeaways': ['Quorum size: Q = floor(N/2) + 1', 'F <= (N-1)/2 crash faults tolerated'],
      'exam_tips': ['Remember to calculate quorum size when N is odd vs even.', 'Draw leader election state transition.'],
      'citations': [],
      'created_at': '2026-09-14T15:00:00Z',
    });

    expect(summary.title, contains('Distributed Consensus'));
    expect(summary.keyConcepts.length, 3);
    expect(summary.importantFormulasOrTakeaways.length, 2);
    expect(summary.examTips.length, 2);

    final session = ConversationSessionModel.fromJson({
      'id': 'sess_999',
      'user_id': 'user_123',
      'title': 'Raft Algorithm Review',
      'subject_id': 'sub_301',
      'messages_count': 6,
      'last_message_preview': 'Can you explain leader election?',
      'updated_at': '2026-09-14T15:00:00Z',
    });

    expect(session.id, 'sess_999');
    expect(session.messagesCount, 6);
    expect(session.lastMessagePreview, contains('leader election'));

    final sessionList = ConversationListResponseModel.fromJson({
      'sessions': [session.toJson()],
      'total': 1,
    });
    expect(sessionList.total, 1);
    expect(sessionList.sessions.first.title, 'Raft Algorithm Review');
  });

  test('AppColors brand identity check', () {
    expect(AppColors.primary.toARGB32(), isNotNull);
    expect(AppColors.success.toARGB32(), isNotNull);
  });

  test('UserModel update and serialization test', () {
    final original = UserModel(
      id: 'usr_789',
      email: 'alex.rivera@stanford.edu',
      fullName: 'Alex Rivera',
      university: 'Stanford University',
      degree: 'B.S. Computer Science',
      currentSemester: 4,
    );

    final updated = original.copyWith(
      fullName: 'Alex Rivera, MSc',
      university: 'MIT',
      currentSemester: 5,
    );

    expect(updated.id, 'usr_789');
    expect(updated.fullName, 'Alex Rivera, MSc');
    expect(updated.university, 'MIT');
    expect(updated.currentSemester, 5);
    expect(updated.degree, 'B.S. Computer Science');
  });

  test('AuthState unauthenticated and authenticated transitions test', () {
    final unauth = AuthState.unauthenticated();
    expect(unauth.isAuthenticated, false);
    expect(unauth.isInitial, false);
    expect(unauth.user, isNull);

    final user = UserModel(
      id: 'u1',
      email: 'newstudent@university.edu',
      fullName: 'New Student',
      university: 'Harvard',
      degree: 'B.A. Economics',
      currentSemester: 1,
    );
    final auth = AuthState.authenticated(user);
    expect(auth.isAuthenticated, true);
    expect(auth.user?.fullName, 'New Student');
    expect(auth.user?.email, 'newstudent@university.edu');
  });
}



