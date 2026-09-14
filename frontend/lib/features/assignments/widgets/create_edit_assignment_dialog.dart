import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/assignments/models/assignment_model.dart';
import 'package:frontend/features/assignments/providers/assignments_provider.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

class CreateEditAssignmentDialog extends ConsumerStatefulWidget {
  final AssignmentModel? assignment;
  final String? initialSubjectId;
  final AssignmentStatus? initialStatus;

  const CreateEditAssignmentDialog({
    super.key,
    this.assignment,
    this.initialSubjectId,
    this.initialStatus,
  });

  @override
  ConsumerState<CreateEditAssignmentDialog> createState() => _CreateEditAssignmentDialogState();
}

class _CreateEditAssignmentDialogState extends ConsumerState<CreateEditAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _gradeController;
  late TextEditingController _feedbackController;

  String? _selectedSubjectId;
  late DateTime _selectedDueDate;
  late TimeOfDay _selectedDueTime;
  late AssignmentPriority _selectedPriority;
  late AssignmentStatus _selectedStatus;
  bool _isLoading = false;

  bool get isEditing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    _titleController = TextEditingController(text: a?.title ?? '');
    _descController = TextEditingController(text: a?.description ?? '');
    _gradeController = TextEditingController(
        text: a?.gradeReceived != null ? a!.gradeReceived!.toString() : '');
    _feedbackController = TextEditingController(text: a?.feedback ?? '');

    _selectedSubjectId = a?.subjectId ?? widget.initialSubjectId;

    final initialDue = a?.dueDate.toLocal() ?? DateTime.now().add(const Duration(days: 3));
    _selectedDueDate = DateTime(initialDue.year, initialDue.month, initialDue.day);
    _selectedDueTime = TimeOfDay(hour: initialDue.hour, minute: initialDue.minute);

    _selectedPriority = a?.priority ?? AssignmentPriority.medium;
    _selectedStatus = a?.status ?? widget.initialStatus ?? AssignmentStatus.pending;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectsAsync = ref.watch(subjectsProvider);

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.add_task_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Assignment' : 'Create Assignment / Task',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'Update deadline, workflow status, or grading feedback'
                                : 'Track deadlines, milestones, and grading weights',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 18),

                // Scrollable Body
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Input
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Assignment Title *',
                            hintText: 'e.g. Midterm Project, Lab 3, Research Paper',
                            prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter assignment title';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Subject Picker & Due Date
                        // Course / Subject selector (Full-width)
                        subjectsAsync.when(
                          data: (subjects) {
                            return DropdownButtonFormField<String?>(
                              initialValue: _selectedSubjectId,
                              decoration: InputDecoration(
                                labelText: 'Subject / Course',
                                prefixIcon: const Icon(Icons.book_outlined, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('No Subject (General Task)'),
                                ),
                                ...subjects.map(
                                  (sub) => DropdownMenuItem<String?>(
                                    value: sub.id,
                                    child: Text('${sub.code} - ${sub.name}'),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedSubjectId = val;
                                });
                              },
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox(),
                        ),

                        const SizedBox(height: 16),

                        // Due Date & Due Time Pickers
                        Row(
                          children: [
                            // Date selector
                            Expanded(
                              child: InkWell(
                                onTap: _pickDueDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('EEE, MMM d, y').format(_selectedDueDate),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Time selector
                            Expanded(
                              child: InkWell(
                                onTap: _pickDueTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedDueTime.format(context),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Priority Selector (Responsive Wrap to prevent overflow)
                        Text(
                          'Priority Level',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AssignmentPriority.values.map((p) {
                            final isSelected = _selectedPriority == p;
                            return ChoiceChip(
                              showCheckmark: false,
                              avatar: Icon(p.icon, size: 14, color: isSelected ? Colors.white : p.color),
                              label: Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: p.color,
                              backgroundColor: p.color.withValues(alpha: 0.1),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedPriority = p;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Status Selector
                        Text(
                          'Workflow Status',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: AssignmentStatus.values.map((s) {
                              final isSelected = _selectedStatus == s;
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  showCheckmark: false,
                                  avatar: Icon(s.icon, size: 14, color: isSelected ? Colors.white : s.color),
                                  label: Text(
                                    s.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: s.color,
                                  backgroundColor: s.color.withValues(alpha: 0.1),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedStatus = s;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Description / Instructions
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Instructions / Description (Optional)',
                            hintText: 'Add requirements, reference links, submission guidelines...',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),

                        // Grading & Feedback (if Graded or Submitted)
                        if (_selectedStatus == AssignmentStatus.graded ||
                            _selectedStatus == AssignmentStatus.submitted ||
                            isEditing) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _gradeController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Grade Received (%)',
                                    hintText: 'e.g. 95.0',
                                    prefixIcon: const Icon(Icons.grade_outlined, size: 18),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _feedbackController,
                                  decoration: InputDecoration(
                                    labelText: 'Feedback / Comments',
                                    hintText: 'e.g. Great work on testing',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      onPressed: _isLoading ? null : _saveAssignment,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Update Assignment' : 'Create Assignment'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate.isBefore(now) ? now : _selectedDueDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime,
    );
    if (picked != null) {
      setState(() {
        _selectedDueTime = picked;
      });
    }
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final combinedDueDate = DateTime(
        _selectedDueDate.year,
        _selectedDueDate.month,
        _selectedDueDate.day,
        _selectedDueTime.hour,
        _selectedDueTime.minute,
      ).toUtc();

      final grade = double.tryParse(_gradeController.text.trim());
      final feedback = _feedbackController.text.trim().isNotEmpty
          ? _feedbackController.text.trim()
          : null;

      if (isEditing) {
        await ref.read(assignmentsProvider.notifier).updateAssignment(
              widget.assignment!.id,
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              subjectId: _selectedSubjectId,
              dueDate: combinedDueDate,
              priority: _selectedPriority,
              status: _selectedStatus,
              weightPercentage: widget.assignment?.weightPercentage,
              gradeReceived: grade,
              feedback: feedback,
            );
      } else {
        await ref.read(assignmentsProvider.notifier).createAssignment(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              subjectId: _selectedSubjectId,
              dueDate: combinedDueDate,
              priority: _selectedPriority,
              status: _selectedStatus,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Assignment updated!' : 'Assignment created successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving assignment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
