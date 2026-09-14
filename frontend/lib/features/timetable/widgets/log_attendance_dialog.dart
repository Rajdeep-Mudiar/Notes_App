import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';
import 'package:frontend/features/timetable/models/timetable_model.dart';
import 'package:frontend/features/timetable/providers/timetable_provider.dart';

class LogAttendanceDialog extends ConsumerStatefulWidget {
  final TimetableSlotModel? slot;
  final String? subjectId;

  const LogAttendanceDialog({
    super.key,
    this.slot,
    this.subjectId,
  });

  @override
  ConsumerState<LogAttendanceDialog> createState() => _LogAttendanceDialogState();
}

class _LogAttendanceDialogState extends ConsumerState<LogAttendanceDialog> {
  late String? _selectedSubjectId;
  late DateTime _selectedDate;
  late AttendanceStatusEnum _selectedStatus;
  late TextEditingController _notesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.slot?.subjectId ?? widget.subjectId;
    _selectedDate = DateTime.now();
    _selectedStatus = AttendanceStatusEnum.present;
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final success = await ref.read(timetableControllerProvider.notifier).logAttendance(
          slotId: widget.slot?.id,
          subjectId: _selectedSubjectId,
          date: _selectedDate,
          status: _selectedStatus,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance recorded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record attendance.'),
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
        width: 480,
        padding: const EdgeInsets.all(24),
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
                      color: const Color(0xFF10B981).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.how_to_reg_rounded, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Record Attendance',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.slot != null ? widget.slot!.title : 'Log attendance for a class session',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

              // Course Selector (if slot is not preselected)
              if (widget.slot == null)
                subjectsAsync.when(
                  data: (subjects) => DropdownButtonFormField<String?>(
                    initialValue: _selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: 'Select Course',
                      prefixIcon: const Icon(Icons.school_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: subjects
                        .map(
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
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedSubjectId = val),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),

              if (widget.slot == null) const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Status Selector
              const Text(
                'Attendance Status',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AttendanceStatusEnum.values.map((status) {
                  final isSelected = _selectedStatus == status;
                  return ChoiceChip(
                    avatar: Icon(
                      status.icon,
                      size: 15,
                      color: isSelected ? Colors.white : status.color,
                    ),
                    label: Text(status.label),
                    selected: isSelected,
                    selectedColor: status.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedStatus = status);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Notes Input
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Session Notes (Optional)',
                  hintText: 'e.g. Covered Chapter 4, missed due to doctor appointment',
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Actions
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
                      backgroundColor: const Color(0xFF10B981),
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
                        : const Text('Save Record'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
