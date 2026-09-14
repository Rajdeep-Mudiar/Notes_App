import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/analytics/models/analytics_model.dart';
import 'package:frontend/features/analytics/providers/analytics_provider.dart';

class UpdateGradeDialog extends ConsumerStatefulWidget {
  final SubjectGradeModel subjectGrade;

  const UpdateGradeDialog({super.key, required this.subjectGrade});

  static Future<void> show(BuildContext context, SubjectGradeModel subjectGrade) {
    return showDialog(
      context: context,
      builder: (ctx) => UpdateGradeDialog(subjectGrade: subjectGrade),
    );
  }

  @override
  ConsumerState<UpdateGradeDialog> createState() => _UpdateGradeDialogState();
}

class _UpdateGradeDialogState extends ConsumerState<UpdateGradeDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedLetter;
  late TextEditingController _numericalController;
  late String? _selectedTarget;
  bool _isSaving = false;

  final List<String> _letterGrades = [
    'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'O', 'P'
  ];

  @override
  void initState() {
    super.initState();
    _selectedLetter = widget.subjectGrade.letterGrade;
    _numericalController = TextEditingController(
      text: widget.subjectGrade.numericalGrade != null
          ? widget.subjectGrade.numericalGrade!.toStringAsFixed(1)
          : '',
    );
    _selectedTarget = widget.subjectGrade.targetGrade ?? 'A';
  }

  @override
  void dispose() {
    _numericalController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    double? numerical;
    if (_numericalController.text.trim().isNotEmpty) {
      numerical = double.tryParse(_numericalController.text.trim());
    }

    final success = await ref.read(analyticsControllerProvider.notifier).updateGrade(
          subjectId: widget.subjectGrade.subjectId,
          letterGrade: _selectedLetter,
          numericalGrade: numerical,
          targetGrade: _selectedTarget,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grade updated for ${widget.subjectGrade.subjectName}'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update grade. Please try again.'),
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

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grade_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Grade',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.subjectGrade.subjectCode} • ${widget.subjectGrade.subjectName} (${widget.subjectGrade.credits} cr)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Received Letter Grade',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedLetter,
                decoration: InputDecoration(
                  hintText: 'Select Letter Grade (e.g. A, B+)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Not yet graded'),
                  ),
                  ..._letterGrades.map((grade) => DropdownMenuItem(
                        value: grade,
                        child: Text(grade, style: const TextStyle(fontWeight: FontWeight.bold)),
                      )),
                ],
                onChanged: (val) {
                  setState(() => _selectedLetter = val);
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Percentage Score (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _numericalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g. 88.5',
                  suffixText: '%',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final num = double.tryParse(val.trim());
                    if (num == null || num < 0 || num > 100) {
                      return 'Enter a valid percentage between 0 and 100';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Target Grade Goal',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedTarget,
                decoration: InputDecoration(
                  hintText: 'Goal Grade',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _letterGrades.map((grade) => DropdownMenuItem(
                      value: grade,
                      child: Text(grade, style: const TextStyle(fontWeight: FontWeight.bold)),
                    )).toList(),
                onChanged: (val) {
                  setState(() => _selectedTarget = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Grade'),
        ),
      ],
    );
  }
}
