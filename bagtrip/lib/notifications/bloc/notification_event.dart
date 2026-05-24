part of 'notification_bloc.dart';

sealed class NotificationEvent {}

class LoadNotifications extends NotificationEvent {
  final int page;
  LoadNotifications({this.page = 1});
}

class LoadMoreNotifications extends NotificationEvent {}

class MarkNotificationRead extends NotificationEvent {
  final String notificationId;
  MarkNotificationRead({required this.notificationId});
}

class MarkAllRead extends NotificationEvent {}

class DeleteNotification extends NotificationEvent {
  final String notificationId;
  DeleteNotification({required this.notificationId});
}

class ResetNotifications extends NotificationEvent {}
