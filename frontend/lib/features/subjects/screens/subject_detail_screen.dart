import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/router/route_names.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/text_styles.dart';
import 'package:frontend/features/assignments/models/assignment_model.dart';
import 'package:frontend/features/assignments/providers/assignments_provider.dart';
import 'package:frontend/features/assignments/widgets/assignment_card.dart';
import 'package:frontend/features/assignments/widgets/create_edit_assignment_dialog.dart';
import 'package:frontend/features/exams/models/exam_model.dart';
import 'package:frontend/features/exams/providers/exams_provider.dart';
import 'package:frontend/features/exams/widgets/create_edit_exam_dialog.dart';
import 'package:frontend/features/exams/widgets/exam_card.dart';
import 'package:frontend/features/files/providers/files_provider.dart';
import 'package:frontend/features/files/widgets/file_card.dart';
import 'package:frontend/features/files/widgets/folder_card.dart';
import 'package:frontend/features/files/widgets/upload_file_dialog.dart';
import 'package:frontend/features/notes/providers/notes_provider.dart';
import 'package:frontend/features/notes/widgets/note_card.dart';
import 'package:frontend/features/subjects/models/subject_model.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';
import 'package:frontend/features/subjects/widgets/create_edit_subject_dialog.dart';
import 'package:frontend/features/timetable/models/timetable_model.dart';
import 'package:frontend/features/timetable/providers/timetable_provider.dart';
import 'package:frontend/features/timetable/widgets/attendance_meter_widget.dart';
import 'package:frontend/features/timetable/widgets/class_slot_card.dart';
import 'package:frontend/features/timetable/widgets/create_edit_slot_dialog.dart';
import 'package:frontend/features/timetable/widgets/log_attendance_dialog.dart';
import 'package:frontend/shared/widgets/status_badge.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectAsync = ref.watch(singleSubjectProvider(widget.subjectId));

    return subjectAsync.when(
      data: (subject) => _buildContent(context, subject),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load subject: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(singleSubjectProvider(widget.subjectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SubjectModel subject) {
    final subjectColor = subject.color;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: subjectColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(subject.iconData, color: subjectColor, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subject.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Subject',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await CreateEditSubjectDialog.show(
                context,
                existingSubject: subject,
              );
              if (updated == true) {
                ref.invalidate(singleSubjectProvider(widget.subjectId));
                ref.read(subjectsProvider.notifier).loadSubjects();
              }
            },
          ),
          IconButton(
            tooltip: 'Delete Subject',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () => _confirmDelete(context, subject),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: subjectColor,
          labelColor: subjectColor,
          unselectedLabelColor: AppColors.lightTextSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined, size: 16)),
            Tab(text: 'Notes', icon: Icon(Icons.article_outlined, size: 16)),
            Tab(text: 'Files & PDFs', icon: Icon(Icons.folder_outlined, size: 16)),
            Tab(text: 'Assignments', icon: Icon(Icons.assignment_outlined, size: 16)),
            Tab(text: 'Exams', icon: Icon(Icons.event_note_outlined, size: 16)),
            Tab(text: 'Timetable & Attendance', icon: Icon(Icons.schedule_rounded, size: 16)),
            Tab(text: 'Resources', icon: Icon(Icons.link_rounded, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, subject),
          _buildNotesTab(context, subject),
          _buildFilesTab(context, subject),
          _buildAssignmentsTab(context, subject),
          _buildExamsTab(context, subject),
          _buildTimetableTab(context, subject),
          _buildPlaceholderTab(
            icon: Icons.auto_awesome_rounded,
            title: 'Subject AI Tutor & Resources',
            desc: 'Ask AI questions directly grounded in your ${subject.code} lecture notes and uploaded materials.',
            phaseBadge: 'Unlocking in Phases 10-12',
            buttonLabel: 'Ask AI Tutor',
            buttonColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsTab(BuildContext context, SubjectModel subject) {
    final examsRepo = ref.watch(examRepositoryProvider);

    return FutureBuilder<ExamListResponseModel>(
      future: examsRepo.getExams(subjectId: subject.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final exams = snapshot.data?.items ?? [];

        return Scaffold(
          body: exams.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_outlined, size: 40, color: Color(0xFFF59E0B)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No exams scheduled for ${subject.code}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Schedule midterms, finals, room venues, and track target grade scores.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => CreateEditExamDialog(
                                initialSubjectId: subject.id,
                              ),
                            ).then((_) {
                              ref.invalidate(singleSubjectProvider(subject.id));
                              setState(() {});
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: Text('Schedule Exam for ${subject.code}'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return ExamCard(exam: exam);
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => CreateEditExamDialog(
                  initialSubjectId: subject.id,
                ),
              ).then((_) {
                ref.invalidate(singleSubjectProvider(subject.id));
                setState(() {});
              });
            },
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Schedule Exam'),
          ),
        );
      },
    );
  }

  Widget _buildTimetableTab(BuildContext context, SubjectModel subject) {
    final timetableRepo = ref.watch(timetableRepositoryProvider);

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        timetableRepo.getSlots(subjectId: subject.id),
        timetableRepo.getAttendanceSummary(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final slots = (snapshot.data?[0] as List<TimetableSlotModel>?) ?? [];
        final summary = snapshot.data?[1] as AttendanceSummaryModel?;

        SubjectAttendanceStatsModel? subjectStats;
        if (summary != null) {
          final match = summary.subjectsStats.where((s) => s.subjectId == subject.id);
          if (match.isNotEmpty) {
            subjectStats = match.first;
          }
        }

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Attendance Health Card if available
              if (subjectStats != null) ...[
                const Text(
                  'Subject Attendance Health',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                AttendanceMeterWidget(stats: subjectStats),
                const SizedBox(height: 16),
              ],

              // Schedule Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Weekly Class Schedule (${slots.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.how_to_reg_outlined, size: 16),
                    label: const Text('Log Attendance'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => LogAttendanceDialog(subjectId: subject.id),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (slots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: subject.color.withAlpha(10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: subject.color.withAlpha(30)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.schedule_rounded, size: 48, color: subject.color),
                      const SizedBox(height: 12),
                      Text(
                        'No class slots scheduled for ${subject.code}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add lecture, lab, and tutorial slots to build your weekly schedule and track attendance.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: subject.color,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => CreateEditSlotDialog(
                              slot: TimetableSlotModel(
                                id: '',
                                userId: '',
                                subjectId: subject.id,
                                title: subject.name,
                                startTime: '09:00',
                                endTime: '10:30',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: Text('Schedule ${subject.code} Class'),
                      ),
                    ],
                  ),
                )
              else
                ...slots.map((s) => ClassSlotCard(slot: s)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CreateEditSlotDialog(
                  slot: TimetableSlotModel(
                    id: '',
                    userId: '',
                    subjectId: subject.id,
                    title: subject.name,
                    startTime: '09:00',
                    endTime: '10:30',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ),
              ).then((_) => setState(() {}));
            },
            backgroundColor: subject.color,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Class Slot'),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTab(BuildContext context, SubjectModel subject) {
    final assignmentsRepo = ref.watch(assignmentRepositoryProvider);

    return FutureBuilder<AssignmentListResponseModel>(
      future: assignmentsRepo.getAssignments(subjectId: subject.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = snapshot.data?.items ?? [];

        return Scaffold(
          body: assignments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.assignment_turned_in_outlined, size: 40, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No assignments for ${subject.code} yet',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Keep track of problem sets, lab reports, midterm essays, and projects.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => CreateEditAssignmentDialog(
                                initialSubjectId: subject.id,
                              ),
                            ).then((_) {
                              ref.invalidate(singleSubjectProvider(subject.id));
                              setState(() {});
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: Text('Add Assignment for ${subject.code}'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return AssignmentCard(assignment: assignment);
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => CreateEditAssignmentDialog(
                  initialSubjectId: subject.id,
                ),
              ).then((_) {
                ref.invalidate(singleSubjectProvider(subject.id));
                setState(() {});
              });
            },
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Task'),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(BuildContext context, SubjectModel subject) {
    final subjectColor = subject.color;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [subjectColor, subjectColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: subjectColor.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subject.code,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Semester ${subject.semester}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subject.name,
                      style: AppTextStyles.displayMedium(context).copyWith(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Professor: ${subject.professor}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${subject.credits} Credits',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Description / Syllabus Section
              Text('About this Course', style: AppTextStyles.titleLarge(context)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Text(
                  subject.description.isNotEmpty
                      ? subject.description
                      : 'No detailed syllabus entered yet. You can edit the subject description to add topics, recommended textbooks, and grading policy.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: subject.description.isNotEmpty ? AppColors.lightTextPrimary : AppColors.lightTextMuted,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Resource Counters Grid
              Text('Subject Workspace Contents', style: AppTextStyles.titleLarge(context)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 460;
                  final tiles = [
                    _buildMetricTile(
                      icon: Icons.article_outlined,
                      label: 'Notes',
                      count: '${subject.notesCount}',
                      color: AppColors.primary,
                      onTap: () => _tabController.animateTo(1),
                    ),
                    _buildMetricTile(
                      icon: Icons.folder_outlined,
                      label: 'Files',
                      count: '${subject.filesCount}',
                      color: const Color(0xFF0EA5E9),
                      onTap: () => _tabController.animateTo(2),
                    ),
                    _buildMetricTile(
                      icon: Icons.assignment_outlined,
                      label: 'Assignments',
                      count: '${subject.assignmentsCount}',
                      color: const Color(0xFF10B981),
                      onTap: () => _tabController.animateTo(3),
                    ),
                    _buildMetricTile(
                      icon: Icons.event_note_outlined,
                      label: 'Exams',
                      count: '${subject.examsCount}',
                      color: const Color(0xFFF59E0B),
                      onTap: () => _tabController.animateTo(4),
                    ),
                  ];

                  if (isNarrow) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: tiles[0]),
                            const SizedBox(width: 12),
                            Expanded(child: tiles[1]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: tiles[2]),
                            const SizedBox(width: 12),
                            Expanded(child: tiles[3]),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: 12),
                      Expanded(child: tiles[1]),
                      const SizedBox(width: 12),
                      Expanded(child: tiles[2]),
                      const SizedBox(width: 12),
                      Expanded(child: tiles[3]),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context, SubjectModel subject) {
    final notesRepo = ref.watch(noteRepositoryProvider);

    return FutureBuilder<List<dynamic>>(
      future: notesRepo.getNotes(subjectId: subject.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notes = snapshot.data ?? [];

        return Scaffold(
          body: notes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: subject.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.article_outlined, size: 40, color: subject.color),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notes for ${subject.code} yet',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Capture lecture notes, formulas, checklists, and code snippets.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/notes/new?subject_id=${subject.id}'),
                          icon: const Icon(Icons.add_rounded),
                          label: Text('Create Note for ${subject.code}'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NoteCard(
                        note: note,
                        onTap: () => context.push('/notes/${note.id}'),
                        onDelete: () async {
                          await ref.read(noteRepositoryProvider).deleteNote(note.id);
                          ref.invalidate(singleSubjectProvider(subject.id));
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/notes/new?subject_id=${subject.id}'),
            backgroundColor: subject.color,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Note'),
          ),
        );
      },
    );
  }

  Widget _buildFilesTab(BuildContext context, SubjectModel subject) {
    final filesAsync = ref.watch(subjectFilesProvider(subject.id));

    return filesAsync.when(
      data: (data) {
        final files = data.items;
        final folders = data.folders;

        if (files.isEmpty && folders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF10B981), size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No files uploaded for ${subject.code}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Store lecture slides, syllabus, reference textbooks, past papers, and worksheets.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => UploadFileDialog.show(context, initialSubjectId: subject.id),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Upload First File'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (folders.isNotEmpty) ...[
                  Text('Folders (${folders.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final count = constraints.maxWidth > 650 ? 3 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: count,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 70,
                        ),
                        itemCount: folders.length,
                        itemBuilder: (ctx, i) => FolderCard(
                          folder: folders[i],
                          onTap: () => context.push(RouteNames.files),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                if (files.isNotEmpty) ...[
                  Text('Course Documents (${files.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final count = constraints.maxWidth > 750 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: count,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 175,
                        ),
                        itemCount: files.length,
                        itemBuilder: (ctx, i) {
                          final f = files[i];
                          return FileCard(
                            file: f,
                            onFavoriteToggle: () {
                              ref.read(fileOperationsProvider.notifier).toggleFavorite(f.id, subjectId: subject.id);
                            },
                            onDelete: () {
                              ref.read(fileOperationsProvider.notifier).deleteFile(f.id, subjectId: subject.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => UploadFileDialog.show(context, initialSubjectId: subject.id),
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('Upload File'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading files: $err')),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab({
    required IconData icon,
    required String title,
    required String desc,
    required String phaseBadge,
    required String buttonLabel,
    required Color buttonColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: buttonColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: buttonColor),
              ),
              const SizedBox(height: 20),
              StatusBadge(label: phaseBadge, color: buttonColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title will be implemented in $phaseBadge.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(buttonLabel, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SubjectModel subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${subject.code}?'),
        content: Text('Are you sure you want to delete "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(subjectsProvider.notifier).deleteSubject(subject.id);
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
