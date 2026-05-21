import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/models/notification_page.dart';

abstract class NotificationRepository {
  Future<Result<NotificationPage>> getNotifications({
    int page = 1,
    int limit = 20,
  });
  Future<Result<int>> getUnreadCount();
  Future<Result<AppNotification>> markAsRead(String notificationId);
  Future<Result<int>> markAllAsRead();
  Future<Result<void>> registerDeviceToken(
    String fcmToken, {
    String? platform,
    String? locale,
  });
  Future<Result<void>> unregisterDeviceToken(String fcmToken);
}
