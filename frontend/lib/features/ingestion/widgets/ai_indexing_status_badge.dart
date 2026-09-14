import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/ingestion/models/ingestion_model.dart';
import 'package:frontend/features/ingestion/providers/ingestion_provider.dart';

class AiIndexingStatusBadge extends ConsumerWidget {
  final String sourceId;
  final SourceTypeEnum sourceType;
  final bool compact;

  const AiIndexingStatusBadge({
    super.key,
    required this.sourceId,
    required this.sourceType,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(sourceIngestionStatusProvider(sourceId));
    final controller = ref.read(ingestionControllerProvider.notifier);

    return statusAsync.when(
      data: (statusModel) {
        if (statusModel != null && statusModel.isCompleted) {
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _triggerReindex(context, controller),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 10,
                vertical: compact ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    compact ? 'AI' : 'AI Indexed (${statusModel.chunksCount})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (statusModel != null && statusModel.isProcessing) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 10,
              vertical: compact ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  'Indexing...',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          );
        }

        // Unindexed / default state
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _triggerReindex(context, controller),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 8,
              vertical: compact ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  size: 13,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  compact ? 'Index' : 'Index for AI',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _triggerReindex(BuildContext context, IngestionController controller) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text('Indexing document chunks for AI assistance...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    if (sourceType == SourceTypeEnum.file) {
      await controller.indexFile(sourceId);
    } else {
      await controller.indexNote(sourceId);
    }
  }
}
