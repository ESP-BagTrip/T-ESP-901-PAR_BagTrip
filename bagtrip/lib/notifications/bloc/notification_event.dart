part of 'notification_bloc.dart';

sealed class NotificationEvent {}

class LoadNotifications extends NotificationEvent {
  final int page;
  LoadNotifications({this.page = 1});
}

class LoadUnreadCount extends NotificationEvent {}

class MarkNotificationRead extends NotificationEvent {
  final String notificationId;
  MarkNotificationRead({required this.notificationId});
}

class MarkAllRead extends NotificationEvent {}

class LoadMoreNotifications extends NotificationEvent {}

class NotificationReceived extends NotificationEvent {
  final String title;
  final String body;
  NotificationReceived({required this.title, required this.body});
}

class ResetNotifications extends NotificationEvent {}
