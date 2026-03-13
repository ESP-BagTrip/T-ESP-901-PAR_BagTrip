part of 'notification_bloc.dart';

sealed class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final int totalPages;
  final int currentPage;
  final int total;

  NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
    required this.totalPages,
    required this.currentPage,
    required this.total,
  });
}

class UnreadCountLoaded extends NotificationState {
  final int count;
  UnreadCountLoaded({required this.count});
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError({required this.message});
}
