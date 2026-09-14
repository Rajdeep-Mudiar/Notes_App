import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/files/providers/files_provider.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

class UploadFileDialog extends ConsumerStatefulWidget {
  final String? initialSubjectId;
  final String? initialFolderId;

  const UploadFileDialog({
    super.key,
    this.initialSubjectId,
    this.initialFolderId,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialSubjectId,
    String? initialFolderId,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => UploadFileDialog(
        initialSubjectId: initialSubjectId,
        initialFolderId: initialFolderId,
      ),
    );
  }

  @override
  ConsumerState<UploadFileDialog> createState() => _UploadFileDialogState();
}

class _UploadFileDialogState extends ConsumerState<UploadFileDialog> {
  PlatformFile? _pickedFile;
  late String? _selectedSubjectId;
  late String? _selectedFolderId;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
    _selectedFolderId = widget.initialFolderId;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        withData: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick file: $e');
    }
  }

  Future<void> _handleUpload() async {
    if (_pickedFile == null) {
      setState(() => _errorMessage = 'Please select a file to upload');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      await ref.read(fileOperationsProvider.notifier).uploadFile(
        fileName: _pickedFile!.name,
        bytes: _pickedFile!.bytes,
        filePath: _pickedFile!.path,
        subjectId: _selectedSubjectId,
        folderId: _selectedFolderId,
        onProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploaded "${_pickedFile!.name}" successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Upload failed: $e';
          _isUploading = false;
        });
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Upload Document or File',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // File Selection Box
              InkWell(
                onTap: _isUploading ? null : _pickFile,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.lightBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _pickedFile != null ? AppColors.primary : AppColors.lightBorder,
                      width: _pickedFile != null ? 1.5 : 1,
                    ),
                  ),
                  child: _pickedFile == null
                      ? Column(
                          children: [
                            const Icon(Icons.file_upload_outlined, color: AppColors.primary, size: 36),
                            const SizedBox(height: 8),
                            const Text(
                              'Click to Browse & Select File',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'PDF, PPT, DOCX, Images, Videos, Audio, ZIP',
                              style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFile!.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatSize(_pickedFile!.size),
                                    style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _isUploading ? null : _pickFile,
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Subject selector
              if (widget.initialSubjectId == null) ...[
                subjectsAsync.when(
                  data: (subjects) => DropdownButtonFormField<String?>(
                    initialValue: _selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: 'Assign to Subject (Optional)',
                      prefixIcon: const Icon(Icons.menu_book_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('General Files (No Subject)'),
                      ),
                      ...subjects.map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.code} — ${s.name}'),
                          )),
                    ],
                    onChanged: _isUploading ? null : (val) => setState(() => _selectedSubjectId = val),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
              ],

              // Upload progress indicator
              if (_isUploading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                    minHeight: 6,
                    backgroundColor: AppColors.lightBg,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Uploading... ${(_uploadProgress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isUploading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isUploading || _pickedFile == null ? null : _handleUpload,
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('Upload File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
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
