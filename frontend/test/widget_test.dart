import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/auth/models/user_model.dart';
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

  test('AppColors brand identity check', () {
    expect(AppColors.primary.toARGB32(), isNotNull);
    expect(AppColors.success.toARGB32(), isNotNull);
  });
}
