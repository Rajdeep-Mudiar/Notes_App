import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/notifications/models/notification_model.dart';
import 'package:frontend/features/notifications/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient);
});

// Filter state ('all', 'unread', 'assignment_due', 'exam_upcoming', 'class_starting', 'attendance_warning')
final selectedNotificationFilterProvider = StateProvider<String>((ref) => 'all');

// Notifications List Provider
final notificationsListProvider = FutureProvider.autoDispose<NotificationListResponseModel>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  final filter = ref.watch(selectedNotificationFilterProvider);

  bool? isRead;
  String? type;

  if (filter == 'unread') {
    isRead = false;
  } else if (filter != 'all') {
    type = filter;
  }

  return repository.getNotifications(
    isRead: isRead,
    type: type,
    limit: 50,
  );
});

// Unread Count Provider
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount();
});

// Notification Controller for mutations
class NotificationController extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationController(this._repository, this._ref) : super(const AsyncValue.data(null));

  void _invalidateAll() {
    _ref.invalidate(notificationsListProvider);
    _ref.invalidate(unreadCountProvider);
  }

  Future<int> scanAndGenerateAlerts() async {
    state = const AsyncValue.loading();
    try {
      final newCount = await _repository.generateAlerts();
      state = const AsyncValue.data(null);
      _invalidateAll();
      return newCount;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      _invalidateAll();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAllAsRead();
      state = const AsyncValue.data(null);
      _invalidateAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      _invalidateAll();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearReadNotifications() async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteReadNotifications();
      state = const AsyncValue.data(null);
      _invalidateAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final notificationControllerProvider = StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationController(repository, ref);
});
