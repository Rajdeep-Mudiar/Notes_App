import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/files/providers/files_provider.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

class CreateFolderDialog extends ConsumerStatefulWidget {
  final String? initialSubjectId;
  final String? parentFolderId;

  const CreateFolderDialog({
    super.key,
    this.initialSubjectId,
    this.parentFolderId,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialSubjectId,
    String? parentFolderId,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => CreateFolderDialog(
        initialSubjectId: initialSubjectId,
        parentFolderId: parentFolderId,
      ),
    );
  }

  @override
  ConsumerState<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends ConsumerState<CreateFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String? _selectedSubjectId;
  String _selectedColor = '#4F46E5';
  bool _isLoading = false;

  final List<String> _colorPresets = [
    '#4F46E5', // Indigo
    '#3B82F6', // Blue
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Violet
    '#06B6D4', // Cyan
    '#64748B', // Slate
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedSubjectId = widget.initialSubjectId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(fileOperationsProvider.notifier).createFolder(
        name: _nameController.text.trim(),
        subjectId: _selectedSubjectId,
        parentId: widget.parentFolderId,
        color: _selectedColor,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create folder: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.create_new_folder_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create New Folder',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Folder Name
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Folder Name *',
                    hintText: 'e.g. Lecture Slides, Midterm Papers',
                    prefixIcon: const Icon(Icons.folder_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Folder name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Course / Subject selector (if not already locked to a subject)
                if (widget.initialSubjectId == null) ...[
                  subjectsAsync.when(
                    data: (subjects) => DropdownButtonFormField<String?>(
                      initialValue: _selectedSubjectId,
                      decoration: InputDecoration(
                        labelText: 'Associated Course (Optional)',
                        prefixIcon: const Icon(Icons.menu_book_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('General Folder (No Course)'),
                        ),
                        ...subjects.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.code} — ${s.name}'),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedSubjectId = val),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Color presets
                const Text(
                  'Folder Color',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorPresets.map((hex) {
                    final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                    final isSelected = _selectedColor == hex;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black87, width: 2.5)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleCreate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Create Folder'),
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
