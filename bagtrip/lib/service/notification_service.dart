import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/service/api_client.dart';

class NotificationApiService {
  final ApiClient _apiClient;

  NotificationApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List)
            .map(
              (json) => AppNotification.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return {
          'items': items,
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
          'totalPages': data['totalPages'] ?? data['total_pages'] ?? 0,
          'unreadCount': data['unreadCount'] ?? data['unread_count'] ?? 0,
        };
      }
      throw Exception('Failed to fetch notifications: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/notifications/unread-count');
      if (response.statusCode == 200) {
        return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<AppNotification> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.patch(
        '/notifications/$notificationId/read',
      );
      if (response.statusCode == 200) {
        return AppNotification.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to mark notification as read');
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  Future<int> markAllAsRead() async {
    try {
      final response = await _apiClient.post('/notifications/read-all');
      if (response.statusCode == 200) {
        return (response.data as Map<String, dynamic>)['updated'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  Future<void> registerDeviceToken(String fcmToken, {String? platform}) async {
    try {
      await _apiClient.post(
        '/device-tokens',
        data: {
          'fcmToken': fcmToken,
          if (platform != null) 'platform': platform,
        },
      );
    } catch (e) {
      // Silently fail — token registration is best-effort
    }
  }

  Future<void> unregisterDeviceToken(String fcmToken) async {
    try {
      await _apiClient.delete('/device-tokens/$fcmToken');
    } catch (e) {
      // Silently fail
    }
  }
}
