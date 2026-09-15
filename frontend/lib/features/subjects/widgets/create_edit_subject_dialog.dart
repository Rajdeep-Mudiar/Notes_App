import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/validators.dart';
import 'package:frontend/features/subjects/models/subject_model.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';
import 'package:frontend/shared/widgets/custom_button.dart';
import 'package:frontend/shared/widgets/custom_text_field.dart';

class CreateEditSubjectDialog extends ConsumerStatefulWidget {
  final SubjectModel? existingSubject;
  final int? initialSemester;

  const CreateEditSubjectDialog({
    super.key,
    this.existingSubject,
    this.initialSemester,
  });

  static Future<bool?> show(
    BuildContext context, {
    SubjectModel? existingSubject,
    int? initialSemester,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateEditSubjectDialog(
        existingSubject: existingSubject,
        initialSemester: initialSemester,
      ),
    );
  }

  @override
  ConsumerState<CreateEditSubjectDialog> createState() => _CreateEditSubjectDialogState();
}

class _CreateEditSubjectDialogState extends ConsumerState<CreateEditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _professorController;
  late final TextEditingController _descriptionController;
  late int _credits;
  late int _semester;
  late String _selectedColor;
  late String _selectedIcon;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _colorPresets = [
    '#4F46E5', // Indigo
    '#0EA5E9', // Sky Blue
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EC4899', // Pink
    '#8B5CF6', // Purple
  ];

  final List<({String key, IconData icon, String label})> _iconPresets = [
    (key: 'book', icon: Icons.menu_book_rounded, label: 'Theory'),
    (key: 'practical', icon: Icons.science_rounded, label: 'Practical'),
  ];

  @override
  void initState() {
    super.initState();
    final sub = widget.existingSubject;
    _nameController = TextEditingController(text: sub?.name ?? '');
    _codeController = TextEditingController(text: sub?.code ?? '');
    _professorController = TextEditingController(text: sub?.professor ?? '');
    _descriptionController = TextEditingController(text: sub?.description ?? '');
    _credits = sub?.credits ?? 4;
    _semester = sub?.semester ?? widget.initialSemester ?? 1;
    _selectedColor = sub?.colorHex ?? _colorPresets.first;
    _selectedIcon = sub?.icon ?? 'book';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _professorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      bool success;
      if (widget.existingSubject != null) {
        success = await ref.read(subjectsProvider.notifier).updateSubject(
              widget.existingSubject!.id,
              name: _nameController.text.trim(),
              code: _codeController.text.trim().toUpperCase(),
              professor: _professorController.text.trim(),
              credits: _credits,
              color: _selectedColor,
              icon: _selectedIcon,
              description: _descriptionController.text.trim(),
              semester: _semester,
            );
      } else {
        success = await ref.read(subjectsProvider.notifier).createSubject(
              name: _nameController.text.trim(),
              code: _codeController.text.trim().toUpperCase(),
              professor: _professorController.text.trim(),
              credits: _credits,
              color: _selectedColor,
              icon: _selectedIcon,
              description: _descriptionController.text.trim(),
              semester: _semester,
            );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _errorMessage = 'Failed to save subject. Make sure course code is unique for this semester.';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existingSubject != null;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Subject' : 'Add New Subject',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFF8FAFC) : AppColors.lightTextPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Subject Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Subject Name',
                  hint: 'e.g. Data Structures & Algorithms',
                  prefixIcon: Icons.menu_book_rounded,
                  validator: (v) => Validators.required(v, message: 'Subject name is required'),
                ),
                const SizedBox(height: 14),

                // Code & Professor Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _codeController,
                        label: 'Course Code',
                        hint: 'e.g. CS204',
                        prefixIcon: Icons.tag_rounded,
                        validator: (v) => Validators.required(v, message: 'Code required'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: _professorController,
                        label: 'Professor / Teacher',
                        hint: 'e.g. Dr. Alan Turing',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Credits & Semester Steppers
                Row(
                  children: [
                    Expanded(
                      child: _buildCounterPicker(
                        context,
                        label: 'Credits',
                        value: _credits,
                        min: 1,
                        max: 12,
                        onChanged: (val) => setState(() => _credits = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCounterPicker(
                        context,
                        label: 'Semester',
                        value: _semester,
                        min: 1,
                        max: 16,
                        onChanged: (val) => setState(() => _semester = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Color Theme Selector
                Text(
                  'Color Theme',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _colorPresets.map((hex) {
                    final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                    final isSelected = _selectedColor == hex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2.5)
                              : Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 1),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Icon Selector
                Text(
                  'Subject Category Icon',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconPresets.map((preset) {
                    final isSelected = _selectedIcon == preset.key;
                    return ChoiceChip(
                      selected: isSelected,
                      avatar: Icon(preset.icon, size: 16),
                      label: Text(preset.label),
                      onSelected: (val) {
                        if (val) setState(() => _selectedIcon = preset.key);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Description
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Syllabus / Overview (Optional)',
                  hint: 'Course objectives, textbook references, and topics...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Submit Button
                CustomButton(
                  text: isEditing ? 'Save Changes' : 'Create Subject',
                  isLoading: _isLoading,
                  icon: isEditing ? Icons.save_rounded : Icons.add_rounded,
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterPicker(
    BuildContext context, {
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF8FAFC) : AppColors.lightTextPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
