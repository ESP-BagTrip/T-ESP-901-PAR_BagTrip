import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/models/notification_page.dart';
import 'package:bagtrip/models/notification_preferences.dart';

abstract class NotificationRepository {
  Future<Result<NotificationPage>> getNotifications({
    int page = 1,
    int limit = 20,
  });
  Future<Result<int>> getUnreadCount();
  Future<Result<AppNotification>> markAsRead(String notificationId);
  Future<Result<int>> markAllAsRead();
  Future<Result<void>> deleteNotification(String notificationId);
  Future<Result<void>> registerDeviceToken(
    String fcmToken, {
    String? platform,
    String? locale,
  });
  Future<Result<void>> unregisterDeviceToken(String fcmToken);

  Future<Result<NotificationPreferences>> getNotificationPreferences();
  Future<Result<NotificationPreferences>> updateNotificationPreferences(
    NotificationPreferences prefs,
  );
}
