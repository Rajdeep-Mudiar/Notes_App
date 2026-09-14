import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/text_styles.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/subjects/models/subject_model.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';
import 'package:frontend/features/subjects/widgets/create_edit_subject_dialog.dart';
import 'package:frontend/features/subjects/widgets/subject_card.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final selectedSemester = ref.watch(selectedSemesterFilterProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final summaryAsync = ref.watch(academicSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects & Courses', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Add Subject',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => CreateEditSubjectDialog.show(
              context,
              initialSemester: selectedSemester ?? user?.currentSemester ?? 1,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Bar
            summaryAsync.when(
              data: (summary) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total Subjects', '${summary.totalSubjects}', Icons.menu_book_rounded),
                    _buildVerticalDivider(),
                    _buildSummaryItem('Total Credits', '${summary.totalCredits}', Icons.stars_rounded),
                    _buildVerticalDivider(),
                    _buildSummaryItem('Current Sem', 'Sem ${summary.currentSemester}', Icons.timeline_rounded),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Search Bar & Semester Filter Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search subjects by title, code or professor...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Semester Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Semesters'),
                    selected: selectedSemester == null,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(selectedSemesterFilterProvider.notifier).state = null;
                        ref.read(subjectsProvider.notifier).loadSubjects();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(8, (index) {
                    final sem = index + 1;
                    final isSelected = selectedSemester == sem;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Semester $sem'),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref.read(selectedSemesterFilterProvider.notifier).state = selected ? sem : null;
                          ref.read(subjectsProvider.notifier).loadSubjects();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Subjects List / Grid
            Expanded(
              child: subjectsAsync.when(
                data: (subjects) {
                  final filtered = subjects.where((s) {
                    if (_searchQuery.isEmpty) return true;
                    return s.name.toLowerCase().contains(_searchQuery) ||
                        s.code.toLowerCase().contains(_searchQuery) ||
                        s.professor.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState(context, selectedSemester);
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(subjectsProvider.notifier).loadSubjects(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 175,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final subject = filtered[index];
                            return SubjectCard(
                              subject: subject,
                              onTap: () => context.push('/subjects/${subject.id}'),
                              onEdit: () => CreateEditSubjectDialog.show(
                                context,
                                existingSubject: subject,
                              ),
                              onDelete: () => _confirmDelete(context, subject),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Error loading subjects: $err'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(subjectsProvider.notifier).loadSubjects(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateEditSubjectDialog.show(
          context,
          initialSemester: selectedSemester ?? user?.currentSemester ?? 1,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Subject'),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 28, width: 1, color: Colors.white24);
  }

  Widget _buildEmptyState(BuildContext context, int? semester) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              semester != null ? 'No subjects in Semester $semester' : 'No subjects added yet',
              style: AppTextStyles.headlineMedium(context),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your university courses to organize lecture notes, files, assignments, and exams.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => CreateEditSubjectDialog.show(
                context,
                initialSemester: semester ?? 1,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Subject'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SubjectModel subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${subject.code}?'),
        content: Text(
          'Are you sure you want to delete "${subject.name}"? This action cannot be undone.',
        ),
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
