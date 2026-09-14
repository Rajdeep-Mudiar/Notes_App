import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/assignments/models/assignment_model.dart';
import 'package:frontend/features/auth/models/user_model.dart';
import 'package:frontend/features/exams/models/exam_model.dart';
import 'package:frontend/features/files/models/file_model.dart';
import 'package:frontend/features/notes/models/note_model.dart';
import 'package:frontend/features/subjects/models/subject_model.dart';

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

  test('AppColors brand identity check', () {
    expect(AppColors.primary.toARGB32(), isNotNull);
    expect(AppColors.success.toARGB32(), isNotNull);
  });
}
