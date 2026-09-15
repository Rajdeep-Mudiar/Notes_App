import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/exams/models/exam_model.dart';
import 'package:frontend/features/exams/providers/exams_provider.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

class CreateEditExamDialog extends ConsumerStatefulWidget {
  final ExamModel? exam;
  final String? initialSubjectId;
  final DateTime? initialDateTime;

  const CreateEditExamDialog({
    super.key,
    this.exam,
    this.initialSubjectId,
    this.initialDateTime,
  });

  @override
  ConsumerState<CreateEditExamDialog> createState() => _CreateEditExamDialogState();
}

class _CreateEditExamDialogState extends ConsumerState<CreateEditExamDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _durationController;
  late TextEditingController _weightController;
  late TextEditingController _topicInputController;

  String? _selectedSubjectId;
  late ExamTypeEnum _selectedExamType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late List<String> _syllabusTopics;
  bool _isLoading = false;

  bool get isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _titleController = TextEditingController(text: e?.title ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _durationController = TextEditingController(text: '${e?.durationMinutes ?? 120}');
    _weightController = TextEditingController(
        text: e?.weightPercentage != null ? e!.weightPercentage!.toString() : '');
    _topicInputController = TextEditingController();

    _selectedSubjectId = e?.subjectId ?? widget.initialSubjectId;
    _selectedExamType = e?.examType ?? ExamTypeEnum.midterm;

    final initialDt = e?.dateTime.toLocal() ??
        widget.initialDateTime?.toLocal() ??
        DateTime.now().add(const Duration(days: 7));
    _selectedDate = DateTime(initialDt.year, initialDt.month, initialDt.day);
    _selectedTime = TimeOfDay(hour: initialDt.hour, minute: initialDt.minute);

    _syllabusTopics = List<String>.from(e?.syllabusTopics ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _weightController.dispose();
    _topicInputController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
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
                        color: _selectedExamType.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedExamType.icon,
                        color: _selectedExamType.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Exam Schedule' : 'Schedule Examination',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'Update date, room location, syllabus scope, or score'
                                : 'Set up exam countdown, room venue, syllabus coverage & target grade',
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

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Scrollable Body
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title input
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Exam Title *',
                            hintText: 'e.g. Midterm 1: Microarchitecture & Caches',
                            prefixIcon: const Icon(Icons.event_note_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter exam title';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Subject & Exam Type
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Subject dropdown
                            Expanded(
                              flex: 3,
                              child: subjectsAsync.when(
                                data: (subjects) {
                                  return DropdownButtonFormField<String?>(
                                    initialValue: _selectedSubjectId,
                                    decoration: InputDecoration(
                                      labelText: 'Subject',
                                      prefixIcon: const Icon(Icons.book_outlined, size: 20),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('General Exam'),
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
                            ),
                            const SizedBox(width: 12),

                            // Weight percentage input
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Weight (%)',
                                  hintText: 'e.g. 30',
                                  prefixIcon: const Icon(Icons.percent_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Exam Type Choice Chips
                        Text(
                          'Assessment Type',
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
                            children: ExamTypeEnum.values.map((t) {
                              final isSelected = _selectedExamType == t;
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  showCheckmark: false,
                                  avatar: Icon(t.icon, size: 14, color: isSelected ? Colors.white : t.color),
                                  label: Text(
                                    t.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: t.color,
                                  backgroundColor: t.color.withValues(alpha: 0.1),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedExamType = t;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Date, Time, Duration
                        Row(
                          children: [
                            // Date selector
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: _pickDate,
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
                                        DateFormat('EEE, MMM d, y').format(_selectedDate),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Time selector
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: _pickTime,
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
                                        _selectedTime.format(context),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Duration input
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _durationController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Duration (m)',
                                  hintText: '120',
                                  prefixIcon: const Icon(Icons.timer_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Location / Room / Venue
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'Room / Venue / Hall / Link (Optional)',
                            hintText: 'e.g. Turing Hall, Room 302 or Zoom link',
                            prefixIcon: const Icon(Icons.place_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Syllabus Topics Tag Builder
                        Text(
                          'Syllabus Modules Covered',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _topicInputController,
                                onSubmitted: (_) => _addSyllabusTopic(),
                                decoration: InputDecoration(
                                  hintText: 'Add topic / chapter (e.g. Chapter 4: Memory Hierarchy)...',
                                  prefixIcon: const Icon(Icons.label_outline_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _addSyllabusTopic,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add'),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        if (_syllabusTopics.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _syllabusTopics.map((topic) {
                              return Chip(
                                label: Text(topic, style: const TextStyle(fontSize: 12)),
                                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                                onDeleted: () {
                                  setState(() {
                                    _syllabusTopics.remove(topic);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

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
                        backgroundColor: _selectedExamType.color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      onPressed: _isLoading ? null : _saveExam,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Update Exam' : 'Schedule Exam'),
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

  void _addSyllabusTopic() {
    final text = _topicInputController.text.trim();
    if (text.isNotEmpty && !_syllabusTopics.contains(text)) {
      setState(() {
        _syllabusTopics.add(text);
        _topicInputController.clear();
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ).toUtc();

      final duration = int.tryParse(_durationController.text.trim()) ?? 60;
      final weight = double.tryParse(_weightController.text.trim());

      if (isEditing) {
        await ref.read(examsProvider.notifier).updateExam(
              widget.exam!.id,
              title: _titleController.text.trim(),
              subjectId: _selectedSubjectId,
              examType: _selectedExamType,
              dateTime: combinedDateTime,
              durationMinutes: duration,
              location: _locationController.text.trim().isNotEmpty
                  ? _locationController.text.trim()
                  : null,
              syllabusTopics: _syllabusTopics,
              weightPercentage: weight,
            );
      } else {
        await ref.read(examsProvider.notifier).createExam(
              title: _titleController.text.trim(),
              subjectId: _selectedSubjectId,
              examType: _selectedExamType,
              dateTime: combinedDateTime,
              durationMinutes: duration,
              location: _locationController.text.trim(),
              syllabusTopics: _syllabusTopics,
              weightPercentage: weight,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Exam updated!' : 'Exam scheduled successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving exam: $e'),
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
