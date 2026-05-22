import 'package:bagtrip/models/notification.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_page.freezed.dart';
part 'notification_page.g.dart';

/// One page of the notification history plus the account-wide unread count.
///
/// `totalPages` / `unreadCount` serialize to `total_pages` / `unread_count`
/// (global `field_rename: snake`), matching the API envelope.
@freezed
abstract class NotificationPage with _$NotificationPage {
  const factory NotificationPage({
    @Default(<AppNotification>[]) List<AppNotification> items,
    @Default(0) int total,
    @Default(1) int page,
    @Default(20) int limit,
    @Default(0) int totalPages,
    @Default(0) int unreadCount,
  }) = _NotificationPage;

  const NotificationPage._();

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      _$NotificationPageFromJson(json);

  bool get hasMore => page < totalPages;
}
