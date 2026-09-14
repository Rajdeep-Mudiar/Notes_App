import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/assignments/models/assignment_model.dart';
import 'package:frontend/features/assignments/providers/assignments_provider.dart';
import 'package:frontend/features/assignments/widgets/assignment_card.dart';
import 'package:frontend/features/assignments/widgets/create_edit_assignment_dialog.dart';

class AssignmentKanbanColumn extends ConsumerWidget {
  final AssignmentStatus status;
  final List<AssignmentModel> items;

  const AssignmentKanbanColumn({
    super.key,
    required this.status,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DragTarget<AssignmentModel>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) {
        ref.read(assignmentsProvider.notifier).updateStatus(details.data.id, status);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          width: 320,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isHovered
                ? status.color.withValues(alpha: 0.08)
                : (isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : AppColors.lightBg),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? status.color
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(status.icon, size: 16, color: status.color),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Add task to ${status.label}',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => CreateEditAssignmentDialog(
                            initialStatus: status,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Items List or Empty State
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                status.icon,
                                size: 36,
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No ${status.label} tasks',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final assignment = items[index];
                          return Draggable<AssignmentModel>(
                            data: assignment,
                            feedback: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 300,
                                child: AssignmentCard(
                                  assignment: assignment,
                                  isCompact: true,
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: AssignmentCard(
                                assignment: assignment,
                                isCompact: true,
                              ),
                            ),
                            child: AssignmentCard(
                              assignment: assignment,
                              isCompact: true,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
