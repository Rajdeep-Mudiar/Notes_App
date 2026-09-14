import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/text_styles.dart';
import 'package:frontend/features/notifications/providers/notification_provider.dart';
import 'package:frontend/features/notifications/widgets/notification_card.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsListProvider);
    final selectedFilter = ref.watch(selectedNotificationFilterProvider);

    final filters = [
      {'id': 'all', 'label': 'All', 'icon': Icons.notifications_none_rounded},
      {'id': 'unread', 'label': 'Unread', 'icon': Icons.mark_email_unread_outlined},
      {'id': 'assignment_due', 'label': 'Deadlines', 'icon': Icons.assignment_late_rounded},
      {'id': 'exam_upcoming', 'label': 'Exams', 'icon': Icons.event_note_rounded},
      {'id': 'class_starting', 'label': 'Classes', 'icon': Icons.schedule_rounded},
      {'id': 'attendance_warning', 'label': 'Attendance', 'icon': Icons.warning_amber_rounded},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Notifications & Alerts',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Run Smart Alert Scanner',
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            onPressed: () async {
              final count = await ref.read(notificationControllerProvider.notifier).scanAndGenerateAlerts();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(count > 0
                        ? 'Smart scan generated $count new alert(s)!'
                        : 'All reminders and alerts are up to date.'),
                    backgroundColor: count > 0 ? AppColors.success : AppColors.primary,
                  ),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'mark_all') {
                ref.read(notificationControllerProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              } else if (val == 'clear_read') {
                ref.read(notificationControllerProvider.notifier).clearReadNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cleared read notifications')),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'mark_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_read',
                child: Row(
                  children: [
                    Icon(Icons.clear_all_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Clear read notifications'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter chips horizontal list
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((f) {
                    final isSelected = selectedFilter == f['id'];
                    final icon = f['icon'] as IconData;
                    final label = f['label'] as String;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        avatar: Icon(
                          icon,
                          size: 16,
                          color: isSelected ? Colors.white : (isDark ? Colors.grey : AppColors.primary),
                        ),
                        label: Text(label),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (_) {
                          ref.read(selectedNotificationFilterProvider.notifier).state = f['id'] as String;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Notifications List Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(notificationsListProvider);
                  ref.invalidate(unreadCountProvider);
                },
                child: notificationsAsync.when(
                  data: (data) {
                    if (data.items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Notifications Found',
                                style: AppTextStyles.titleMedium(context).copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selectedFilter == 'unread'
                                    ? 'You have read all your notifications!'
                                    : 'You have no alerts matching the selected filter.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => ref.read(notificationControllerProvider.notifier).scanAndGenerateAlerts(),
                                icon: const Icon(Icons.sync_rounded, size: 16),
                                label: const Text('Run Smart Alert Scanner'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: data.items.length,
                      itemBuilder: (context, index) {
                        final notification = data.items[index];
                        return NotificationCard(notification: notification);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Error loading notifications: $err'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
