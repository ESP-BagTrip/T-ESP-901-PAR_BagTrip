import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/notification.dart';

abstract class NotificationRepository {
  Future<Result<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 20,
  });
  Future<Result<int>> getUnreadCount();
  Future<Result<AppNotification>> markAsRead(String notificationId);
  Future<Result<int>> markAllAsRead();
  Future<Result<void>> registerDeviceToken(String fcmToken, {String? platform});
  Future<Result<void>> unregisterDeviceToken(String fcmToken);
}
