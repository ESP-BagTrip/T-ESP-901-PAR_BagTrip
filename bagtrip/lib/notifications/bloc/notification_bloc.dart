import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/notification_repository.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:bloc/bloc.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationBloc({NotificationRepository? notificationRepository})
    : _notificationRepository =
          notificationRepository ?? getIt<NotificationRepository>(),
      super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadUnreadCount>(_onLoadUnreadCount);
    on<MarkNotificationRead>(_onMarkNotificationRead);
    on<MarkAllRead>(_onMarkAllRead);
    on<NotificationReceived>(_onNotificationReceived);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await _notificationRepository.getNotifications(
      page: event.page,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          NotificationsLoaded(
            notifications: data['items'] as List<AppNotification>,
            unreadCount: data['unreadCount'] as int,
            totalPages: data['totalPages'] as int,
            currentPage: data['page'] as int,
            total: data['total'] as int,
          ),
        );
      case Failure(:final error):
        emit(NotificationError(message: toUserFriendlyMessage(error)));
    }
  }

  Future<void> _onLoadUnreadCount(
    LoadUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _notificationRepository.getUnreadCount();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(UnreadCountLoaded(count: data));
      case Failure():
        // Silently fail for badge count
        break;
    }
  }

  Future<void> _onMarkNotificationRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _notificationRepository.markAsRead(
      event.notificationId,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadNotifications());
      case Failure(:final error):
        emit(NotificationError(message: toUserFriendlyMessage(error)));
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _notificationRepository.markAllAsRead();
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadNotifications());
      case Failure(:final error):
        emit(NotificationError(message: toUserFriendlyMessage(error)));
    }
  }

  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    // Refresh unread count when a new notification arrives
    add(LoadUnreadCount());
  }
}
