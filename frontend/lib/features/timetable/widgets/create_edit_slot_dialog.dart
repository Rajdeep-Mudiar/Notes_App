import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';
import 'package:frontend/features/timetable/models/timetable_model.dart';
import 'package:frontend/features/timetable/providers/timetable_provider.dart';

class CreateEditSlotDialog extends ConsumerStatefulWidget {
  final TimetableSlotModel? slot;
  final DayOfWeekEnum? initialDay;

  const CreateEditSlotDialog({
    super.key,
    this.slot,
    this.initialDay,
  });

  @override
  ConsumerState<CreateEditSlotDialog> createState() => _CreateEditSlotDialogState();
}

class _CreateEditSlotDialogState extends ConsumerState<CreateEditSlotDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedSubjectId;
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _professorController;
  late TextEditingController _notesController;

  late DayOfWeekEnum _selectedDay;
  late ClassTypeEnum _selectedClassType;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final slot = widget.slot;
    _selectedSubjectId = slot?.subjectId;
    _titleController = TextEditingController(text: slot?.title ?? '');
    _locationController = TextEditingController(text: slot?.location ?? '');
    _professorController = TextEditingController(text: slot?.professorName ?? '');
    _notesController = TextEditingController(text: slot?.notes ?? '');

    _selectedDay = slot?.dayOfWeek ?? widget.initialDay ?? DayOfWeekEnum.monday;
    _selectedClassType = slot?.classType ?? ClassTypeEnum.lecture;

    if (slot != null) {
      final sParts = slot.startTime.split(':');
      final eParts = slot.endTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(sParts[0]), minute: int.parse(sParts[1]));
      _endTime = TimeOfDay(hour: int.parse(eParts[0]), minute: int.parse(eParts[1]));
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 30);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _professorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // If end time is before or equal to start time, auto adjust end time by 1 hour
        final sMin = picked.hour * 60 + picked.minute;
        final eMin = _endTime.hour * 60 + _endTime.minute;
        if (eMin <= sMin) {
          final newEndMin = (sMin + 60) % (24 * 60);
          _endTime = TimeOfDay(hour: newEndMin ~/ 60, minute: newEndMin % 60);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final startStr = _formatTimeOfDay(_startTime);
    final endStr = _formatTimeOfDay(_endTime);

    final sMin = _startTime.hour * 60 + _startTime.minute;
    final eMin = _endTime.hour * 60 + _endTime.minute;
    if (eMin <= sMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    if (widget.slot == null) {
      success = await ref.read(timetableControllerProvider.notifier).createSlot(
            subjectId: _selectedSubjectId,
            title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
            dayOfWeek: _selectedDay,
            startTime: startStr,
            endTime: endStr,
            classType: _selectedClassType,
            location: _locationController.text.trim(),
            professorName: _professorController.text.trim().isNotEmpty ? _professorController.text.trim() : null,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          );
    } else {
      success = await ref.read(timetableControllerProvider.notifier).updateSlot(
            id: widget.slot!.id,
            subjectId: _selectedSubjectId,
            title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
            dayOfWeek: _selectedDay,
            startTime: startStr,
            endTime: endStr,
            classType: _selectedClassType,
            location: _locationController.text.trim(),
            professorName: _professorController.text.trim().isNotEmpty ? _professorController.text.trim() : null,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.slot == null
                  ? 'Class scheduled successfully'
                  : 'Class updated successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save slot. Check for overlapping time collision.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjectsAsync = ref.watch(subjectsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.schedule_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.slot == null ? 'Schedule Class Slot' : 'Edit Class Slot',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Add recurring weekly class session to your timetable',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Subject Selector
                subjectsAsync.when(
                  data: (subjects) => DropdownButtonFormField<String?>(
                    initialValue: _selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: 'Select Course / Subject',
                      prefixIcon: const Icon(Icons.school_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No Subject (General Class)'),
                      ),
                      ...subjects.map(
                        (s) => DropdownMenuItem<String?>(
                          value: s.id,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: s.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${s.code} - ${s.name}'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedSubjectId = val;
                        if (val != null) {
                          final sub = subjects.firstWhere((s) => s.id == val);
                          if (_titleController.text.isEmpty) {
                            _titleController.text = sub.name;
                          }
                          if (_professorController.text.isEmpty && sub.professor.isNotEmpty) {
                            _professorController.text = sub.professor;
                          }
                        }
                      });
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 16),

                // Title Input
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Session Title (e.g. Operating Systems Lecture)',
                    prefixIcon: const Icon(Icons.title_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 16),

                // Day of Week Chips
                const Text(
                  'Day of the Week',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: DayOfWeekEnum.values.map((day) {
                      final isSelected = _selectedDay == day;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(day.shortLabel),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedDay = day);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Class Type Selector
                const Text(
                  'Class Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ClassTypeEnum.values.map((type) {
                    final isSelected = _selectedClassType == type;
                    return ChoiceChip(
                      avatar: Icon(type.icon, size: 14, color: isSelected ? Colors.white : type.color),
                      label: Text(type.label),
                      selected: isSelected,
                      selectedColor: type.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedClassType = type);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Time Pickers (Start & End)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartTime,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Start Time',
                            prefixIcon: const Icon(Icons.access_time_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _formatTimeOfDay(_startTime),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndTime,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Time',
                            prefixIcon: const Icon(Icons.alarm_on_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _formatTimeOfDay(_endTime),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Location & Professor
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Room / Venue (e.g. Hall 101)',
                          prefixIcon: const Icon(Icons.place_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _professorController,
                        decoration: InputDecoration(
                          labelText: 'Professor / Instructor',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(widget.slot == null ? 'Add to Timetable' : 'Save Changes'),
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
}
