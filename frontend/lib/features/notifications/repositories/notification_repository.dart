import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/notifications/models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<NotificationListResponseModel> getNotifications({
    bool? isRead,
    String? type,
    int limit = 50,
    int skip = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'skip': skip,
    };
    if (isRead != null) queryParams['is_read'] = isRead;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;

    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: queryParams,
    );

    final data = response['data'] as Map<String, dynamic>;
    return NotificationListResponseModel.fromJson(data);
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(ApiEndpoints.notificationsUnreadCount);
    final data = response['data'] as Map<String, dynamic>;
    return data['unread_count'] as int? ?? 0;
  }

  Future<int> generateAlerts() async {
    final response = await _apiClient.post(ApiEndpoints.notificationsGenerateAlerts);
    final data = response['data'] as Map<String, dynamic>;
    return data['new_notifications_count'] as int? ?? 0;
  }

  Future<NotificationModel> markAsRead(String id) async {
    final response = await _apiClient.patch(ApiEndpoints.notificationRead(id));
    final data = response['data'] as Map<String, dynamic>;
    return NotificationModel.fromJson(data);
  }

  Future<int> markAllAsRead() async {
    final response = await _apiClient.post(ApiEndpoints.notificationsMarkAllRead);
    final data = response['data'] as Map<String, dynamic>;
    return data['marked_read_count'] as int? ?? 0;
  }

  Future<void> deleteNotification(String id) async {
    await _apiClient.delete(ApiEndpoints.notificationById(id));
  }

  Future<int> deleteReadNotifications() async {
    final response = await _apiClient.delete(ApiEndpoints.notificationsDeleteRead);
    final data = response['data'] as Map<String, dynamic>;
    return data['deleted_count'] as int? ?? 0;
  }
}
