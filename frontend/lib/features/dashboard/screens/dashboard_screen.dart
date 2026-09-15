import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/router/route_names.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/text_styles.dart';
import 'package:frontend/features/assignments/providers/assignments_provider.dart';
import 'package:frontend/features/assignments/widgets/assignment_card.dart';
import 'package:frontend/features/assignments/widgets/create_edit_assignment_dialog.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/exams/providers/exams_provider.dart';
import 'package:frontend/features/exams/widgets/create_edit_exam_dialog.dart';
import 'package:frontend/features/exams/widgets/exam_card.dart';
import 'package:frontend/features/files/providers/files_provider.dart';
import 'package:frontend/features/files/widgets/upload_file_dialog.dart';
import 'package:frontend/features/notes/providers/notes_provider.dart';
import 'package:frontend/features/notes/widgets/note_card.dart';
import 'package:frontend/features/subjects/models/subject_model.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';
import 'package:frontend/features/subjects/widgets/create_edit_subject_dialog.dart';
import 'package:frontend/features/subjects/widgets/subject_card.dart';
import 'package:frontend/features/timetable/providers/timetable_provider.dart';
import 'package:frontend/features/timetable/widgets/create_edit_slot_dialog.dart';
import 'package:frontend/features/timetable/widgets/today_schedule_card.dart';
import 'package:frontend/features/notifications/widgets/notification_badge_button.dart';
import 'package:frontend/features/ingestion/providers/ingestion_provider.dart';
import 'package:frontend/features/ingestion/widgets/ai_knowledge_stats_card.dart';
import 'package:frontend/shared/widgets/status_badge.dart';
import 'package:frontend/core/theme/theme_provider.dart';
import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/services/app_update_service.dart';
import 'package:frontend/shared/widgets/app_update_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _checkForUpdatesInBackground();
  }

  void _checkForUpdatesInBackground() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      try {
        final info = await AppUpdateService().checkForUpdates(
          backendBaseUrl: ApiEndpoints.baseUrl,
        );
        if (mounted && info.hasUpdate) {
          AppUpdateDialog.show(context, info);
        }
      } catch (_) {}
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final summaryAsync = ref.watch(academicSummaryProvider);
    final recentNotesAsync = ref.watch(recentNotesProvider);
    final upcomingAssignmentsAsync = ref.watch(upcomingAssignmentsProvider);
    final upcomingExamsAsync = ref.watch(upcomingExamsProvider);
    final todayClassesAsync = ref.watch(todayScheduleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Notoo',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFFBBF24) : AppColors.primary,
              size: 21,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(context),
          ),
          // AI Study Assistant
          IconButton(
            tooltip: 'AI Study Assistant',
            icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 21),
            onPressed: () => context.push(RouteNames.ai),
          ),
          // Notification Center
          const NotificationBadgeButton(),
          const SizedBox(width: 4),
          // User Profile Avatar
          InkWell(
            onTap: () => context.push(RouteNames.profile),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primary,
                child: Text(
                  (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'S',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(backendHealthProvider);
            ref.invalidate(academicSummaryProvider);
            ref.invalidate(recentNotesProvider);
            ref.invalidate(storageSummaryProvider);
            ref.invalidate(filesListProvider);
            ref.invalidate(ingestionStatsProvider);
            await ref.read(subjectsProvider.notifier).loadSubjects();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting & Student Status Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${_getGreeting()}, ${user?.fullName.split(' ').first ?? 'Student'} 👋',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.displayMedium(context).copyWith(
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Semester ${user?.currentSemester ?? 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${user?.degree ?? 'Undergraduate'} • ${user?.university ?? 'University'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          summaryAsync.when(
                            data: (summary) => Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildHeroMetric('Enrolled Subjects', '${summary.totalSubjects}'),
                                _buildHeroMetric('Total Credits', '${summary.totalCredits}'),
                                _buildHeroMetric('Current Sem', 'Sem ${summary.currentSemester}'),
                              ],
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),



                    // AI Knowledge Base & RAG Index Stats
                    const AiKnowledgeStatsCard(),
                    const SizedBox(height: 24),

                    // Quick Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Quick Actions',
                            style: AppTextStyles.titleLarge(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(RouteNames.subjects),
                          child: const Text('View Courses'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionButton(
                          context: context,
                          icon: Icons.auto_awesome_rounded,
                          label: 'AI Assistant',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.push(RouteNames.ai),
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.add_rounded,
                          label: 'Add Subject',
                          color: AppColors.primary,
                          onTap: () => CreateEditSubjectDialog.show(
                            context,
                            initialSemester: user?.currentSemester ?? 1,
                          ),
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.note_add_rounded,
                          label: 'New Note',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.push('/notes/new'),
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.cloud_upload_rounded,
                          label: 'Upload File',
                          color: const Color(0xFF10B981),
                          onTap: () => UploadFileDialog.show(context),
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.folder_zip_rounded,
                          label: 'Subject Vaults',
                          color: const Color(0xFF0EA5E9),
                          onTap: () => context.push(RouteNames.files),
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.assignment_turned_in_rounded,
                          label: 'Add Task',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => const CreateEditAssignmentDialog(),
                          ),
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.event_note_rounded,
                          label: 'Add Exam',
                          color: const Color(0xFFF59E0B),
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => const CreateEditExamDialog(),
                          ),
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.schedule_rounded,
                          label: 'Add Class',
                          color: const Color(0xFF14B8A6),
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => const CreateEditSlotDialog(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Course Vaults & Materials Hub (PDFs, PPT, Word, Media)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Subject Vaults & Materials', style: AppTextStyles.titleLarge(context)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PDF • PPT • Word • Media',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0EA5E9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(RouteNames.files),
                          child: const Text('Open Drive'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    subjectsAsync.when(
                      data: (subjects) {
                        if (subjects.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: subjects.map((s) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () => context.push('/subjects/${s.id}'),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 170,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : AppColors.lightBorder,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
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
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: s.color.withValues(alpha: isDark ? 0.25 : 0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(s.iconData, color: s.color, size: 20),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${s.filesCount} files',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          s.code,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDark ? const Color(0xFFF8FAFC) : AppColors.lightTextPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          s.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Open Vault',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: s.color,
                                              ),
                                            ),
                                            Icon(Icons.arrow_forward_rounded, size: 14, color: s.color),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 28),

                    // Today's Classes & Live Timeline Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text("Today's Classes", style: AppTextStyles.titleLarge(context)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Live Schedule',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => context.push(RouteNames.timetable),
                          child: const Text('Timetable'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    todayClassesAsync.when(
                      data: (todayClasses) {
                        if (todayClasses.isEmpty) {
                          return _buildEmptyTodayCard(context);
                        }

                        return Column(
                          children: todayClasses.map((c) => TodayScheduleCard(todayClass: c)).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Error loading today\'s schedule: $err'),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Upcoming Exams & Assessments Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Upcoming Exams', style: AppTextStyles.titleLarge(context)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Assessments',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => context.push(RouteNames.exams),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    upcomingExamsAsync.when(
                      data: (upcomingExams) {
                        if (upcomingExams.isEmpty) {
                          return _buildEmptyExamsCard(context);
                        }

                        return Column(
                          children: upcomingExams.map((e) => ExamCard(exam: e)).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Error loading upcoming exams: $err'),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Upcoming Deadlines & Planner Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Upcoming Deadlines', style: AppTextStyles.titleLarge(context)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Planner',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0EA5E9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => context.push(RouteNames.assignments),
                          child: const Text('View Tasks'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    upcomingAssignmentsAsync.when(
                      data: (upcoming) {
                        if (upcoming.isEmpty) {
                          return _buildEmptyAssignmentsCard(context);
                        }

                        return Column(
                          children: upcoming.map((asgn) => AssignmentCard(assignment: asgn)).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Error loading upcoming assignments: $err'),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Semester Subjects Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Semester ${user?.currentSemester ?? 1} Courses',
                            style: AppTextStyles.titleLarge(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Add Subject',
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                          onPressed: () => CreateEditSubjectDialog.show(
                            context,
                            initialSemester: user?.currentSemester ?? 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    subjectsAsync.when(
                      data: (subjects) {
                        if (subjects.isEmpty) {
                          return _buildEmptySubjectsCard(context, user?.currentSemester ?? 1);
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 650 ? 2 : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 175,
                              ),
                              itemCount: subjects.length,
                              itemBuilder: (context, index) {
                                final subject = subjects[index];
                                return SubjectCard(
                                  subject: subject,
                                  onTap: () => context.push('/subjects/${subject.id}'),
                                  onEdit: () => CreateEditSubjectDialog.show(
                                    context,
                                    existingSubject: subject,
                                  ),
                                  onDelete: () => _confirmDelete(context, ref, subject),
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Error loading subjects: $err'),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Recent Notes Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Recent Notes',
                            style: AppTextStyles.titleLarge(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(RouteNames.notes),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    recentNotesAsync.when(
                      data: (notes) {
                        if (notes.isEmpty) {
                          return _buildEmptyNotesCard(context);
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 650 ? 2 : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 175,
                              ),
                              itemCount: notes.length,
                              itemBuilder: (context, index) {
                                final note = notes[index];
                                return NoteCard(
                                  note: note,
                                  onTap: () => context.push('/notes/${note.id}'),
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Error loading recent notes: $err'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    String? phase,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label unlocks in $phase')),
            );
          },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF8FAFC) : AppColors.lightTextPrimary,
              ),
            ),
            if (phase != null) ...[
              const SizedBox(width: 8),
              StatusBadge(label: phase, color: color, isPill: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTodayCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.free_breakfast_outlined, color: Color(0xFF10B981), size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'No classes scheduled for today',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? const Color(0xFFF8FAFC) : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enjoy your free time or configure recurring class sessions in your weekly timetable.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const CreateEditSlotDialog(),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Class Slot'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyExamsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined, color: Color(0xFFF59E0B), size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'No upcoming exams scheduled',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? const Color(0xFFF8FAFC) : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep track of your midterms, finals, room locations, and target scores.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const CreateEditExamDialog(),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Schedule Exam'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAssignmentsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF0EA5E9), size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'No upcoming deadlines',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? const Color(0xFFF8FAFC) : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You are all caught up! Add upcoming assignments, problem sets, or project milestones.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const CreateEditAssignmentDialog(),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Assignment'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySubjectsCard(BuildContext context, int semester) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'No subjects in Semester $semester',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? const Color(0xFFF8FAFC) : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your courses to begin organizing notes, files, assignments, and exam schedules.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => CreateEditSubjectDialog.show(
              context,
              initialSemester: semester,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Subject'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotesCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.note_alt_outlined, color: Color(0xFF6366F1), size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'No notes created yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? const Color(0xFFF8FAFC) : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Take structured lecture notes with headings, checklists, code blocks, and tags.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () => context.push('/notes/new'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create First Note'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SubjectModel subject) {
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
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(subjectsProvider.notifier).deleteSubject(subject.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
