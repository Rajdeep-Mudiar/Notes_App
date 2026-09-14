import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/router/route_names.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/text_styles.dart';
import 'package:frontend/features/files/models/file_model.dart';
import 'package:frontend/features/files/providers/files_provider.dart';
import 'package:frontend/features/files/widgets/create_folder_dialog.dart';
import 'package:frontend/features/files/widgets/file_card.dart';
import 'package:frontend/features/files/widgets/folder_card.dart';
import 'package:frontend/features/files/widgets/storage_meter_card.dart';
import 'package:frontend/features/files/widgets/upload_file_dialog.dart';
import 'package:frontend/features/subjects/providers/subjects_provider.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  late final TextEditingController _searchController;

  final List<Map<String, String>> _typeFilters = [
    {'key': 'all', 'label': 'All Files'},
    {'key': 'pdf', 'label': 'PDFs'},
    {'key': 'document', 'label': 'Docs'},
    {'key': 'presentation', 'label': 'Slides'},
    {'key': 'spreadsheet', 'label': 'Sheets'},
    {'key': 'image', 'label': 'Images'},
    {'key': 'video', 'label': 'Videos'},
    {'key': 'code', 'label': 'Code'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeType = ref.watch(activeFileTypeFilterProvider);
    final selectedSubjectId = ref.watch(fileSubjectFilterProvider);
    final isFavFilter = ref.watch(fileFavoriteFilterProvider);
    final navStack = ref.watch(folderNavStackProvider);

    final filesAsync = ref.watch(filesListProvider);
    final storageAsync = ref.watch(storageSummaryProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Academic Cloud Drive',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'All Subjects',
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => context.push(RouteNames.subjects),
          ),
          IconButton(
            tooltip: 'Refresh Files',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(filesListProvider);
              ref.invalidate(storageSummaryProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(filesListProvider);
            ref.invalidate(storageSummaryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storage Quota Card
                    storageAsync.when(
                      data: (storage) => StorageMeterCard(storage: storage),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    // Search and Filters Bar
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search files across courses...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(fileSearchQueryProvider.notifier).state = '';
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.lightBorder),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (val) {
                              ref.read(fileSearchQueryProvider.notifier).state = val.trim();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Favorite filter toggle
                        IconButton.filledTonal(
                          tooltip: 'Show Favorites Only',
                          style: IconButton.styleFrom(
                            backgroundColor: isFavFilter == true ? AppColors.warning.withValues(alpha: 0.15) : Colors.white,
                            side: BorderSide(
                              color: isFavFilter == true ? AppColors.warning : AppColors.lightBorder,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: Icon(
                            isFavFilter == true ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isFavFilter == true ? AppColors.warning : AppColors.lightTextSecondary,
                            size: 22,
                          ),
                          onPressed: () {
                            ref.read(fileFavoriteFilterProvider.notifier).state =
                                isFavFilter == true ? null : true;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Type filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _typeFilters.map((tf) {
                          final isSelected = activeType == tf['key'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(tf['label']!),
                              selected: isSelected,
                              showCheckmark: false,
                              selectedColor: AppColors.primary.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.primary : AppColors.lightTextPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                              onSelected: (_) {
                                ref.read(activeFileTypeFilterProvider.notifier).state = tf['key']!;
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subject Dropdown Filter
                    subjectsAsync.when(
                      data: (subjects) {
                        if (subjects.isEmpty) return const SizedBox.shrink();
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('All Courses'),
                                selected: selectedSubjectId == null,
                                onSelected: (sel) {
                                  if (sel) ref.read(fileSubjectFilterProvider.notifier).state = null;
                                },
                              ),
                              const SizedBox(width: 8),
                              ...subjects.map((s) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      avatar: Icon(s.iconData, size: 16, color: s.color),
                                      label: Text(s.code),
                                      selected: selectedSubjectId == s.id,
                                      onSelected: (sel) {
                                        ref.read(fileSubjectFilterProvider.notifier).state = sel ? s.id : null;
                                      },
                                    ),
                                  )),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    // Folder Breadcrumbs
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                ref.read(folderNavStackProvider.notifier).state = [];
                              },
                              child: Row(
                                children: const [
                                  Icon(Icons.home_rounded, size: 18, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Root Drive',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            for (int i = 0; i < navStack.length; i++) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.lightTextMuted),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  ref.read(folderNavStackProvider.notifier).state = navStack.sublist(0, i + 1);
                                },
                                child: Text(
                                  navStack[i].name,
                                  style: TextStyle(
                                    fontWeight: i == navStack.length - 1 ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                    color: i == navStack.length - 1 ? AppColors.lightTextPrimary : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Main Files & Folders Content
                    filesAsync.when(
                      data: (data) {
                        final folders = data.folders;
                        final files = data.items;

                        if (folders.isEmpty && files.isEmpty) {
                          return _buildEmptyDriveState(context);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Folders Section
                            if (folders.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Folders (${folders.length})',
                                    style: AppTextStyles.titleMedium(context),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => CreateFolderDialog.show(
                                      context,
                                      initialSubjectId: selectedSubjectId,
                                      parentFolderId: navStack.isNotEmpty ? navStack.last.id : null,
                                    ),
                                    icon: const Icon(Icons.create_new_folder_rounded, size: 16),
                                    label: const Text('New Folder'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final count = constraints.maxWidth > 750 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: count,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent: 74,
                                    ),
                                    itemCount: folders.length,
                                    itemBuilder: (ctx, i) {
                                      final f = folders[i];
                                      return FolderCard(
                                        folder: f,
                                        onTap: () {
                                          ref.read(folderNavStackProvider.notifier).state = [...navStack, f];
                                        },
                                        onDelete: () => _confirmDeleteFolder(context, f),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Files Section
                            if (files.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Files (${files.length})',
                                    style: AppTextStyles.titleMedium(context),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => UploadFileDialog.show(
                                      context,
                                      initialSubjectId: selectedSubjectId,
                                      initialFolderId: navStack.isNotEmpty ? navStack.last.id : null,
                                    ),
                                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                                    label: const Text('Upload File'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final count = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 520 ? 2 : 1);
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: count,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      mainAxisExtent: 180,
                                    ),
                                    itemCount: files.length,
                                    itemBuilder: (ctx, i) {
                                      final file = files[i];
                                      return FileCard(
                                        file: file,
                                        onTap: () => _viewFileDetails(context, file),
                                        onFavoriteToggle: () {
                                          ref.read(fileOperationsProvider.notifier).toggleFavorite(
                                                file.id,
                                                subjectId: file.subjectId,
                                              );
                                        },
                                        onDelete: () => _confirmDeleteFile(context, file),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Error loading files: $err', style: const TextStyle(color: AppColors.error)),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => UploadFileDialog.show(
          context,
          initialSubjectId: selectedSubjectId,
          initialFolderId: navStack.isNotEmpty ? navStack.last.id : null,
        ),
        icon: const Icon(Icons.cloud_upload_rounded),
        label: const Text('Upload File'),
      ),
    );
  }

  Widget _buildEmptyDriveState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'No files in this location',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload lecture slides, research papers, assignment PDFs, images, and videos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => CreateFolderDialog.show(context),
                icon: const Icon(Icons.create_new_folder_rounded, size: 18),
                label: const Text('New Folder'),
              ),
              ElevatedButton.icon(
                onPressed: () => UploadFileDialog.show(context),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Upload File'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewFileDetails(BuildContext context, FileModel file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(file.fileType.iconData, color: file.fileType.color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file.originalName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('File Type', file.fileType.label),
            _buildDetailRow('Size', file.sizeFormatted),
            _buildDetailRow('MIME', file.mimeType),
            _buildDetailRow('Stored Name', file.filename),
            _buildDetailRow('Download URL', file.downloadUrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.lightTextSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFile(BuildContext context, FileModel file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text('Are you sure you want to delete "${file.originalName}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(fileOperationsProvider.notifier).deleteFile(file.id, subjectId: file.subjectId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(BuildContext context, FolderModel folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${folder.name}?'),
        content: const Text('Are you sure you want to delete this folder? Files inside will be unlinked to root.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(fileOperationsProvider.notifier).deleteFolder(folder.id, subjectId: folder.subjectId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
