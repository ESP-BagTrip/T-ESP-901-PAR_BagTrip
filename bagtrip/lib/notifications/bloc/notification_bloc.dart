import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/notification_repository.dart';
import 'package:bagtrip/service/crashlytics_service.dart';
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
    on<LoadMoreNotifications>(_onLoadMore);
    on<LoadUnreadCount>(_onLoadUnreadCount);
    on<MarkNotificationRead>(_onMarkNotificationRead);
    on<MarkAllRead>(_onMarkAllRead);
    on<NotificationReceived>(_onNotificationReceived);
    on<ResetNotifications>(_onReset);
  }

  void _onReset(ResetNotifications event, Emitter<NotificationState> emit) {
    emit(NotificationInitial());
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
        emit(NotificationError(error: error));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    emit(
      NotificationsLoaded(
        notifications: current.notifications,
        unreadCount: current.unreadCount,
        totalPages: current.totalPages,
        currentPage: current.currentPage,
        total: current.total,
        isLoadingMore: true,
      ),
    );
    final nextPage = current.currentPage + 1;
    final result = await _notificationRepository.getNotifications(
      page: nextPage,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        final newItems = data['items'] as List<AppNotification>;
        emit(
          NotificationsLoaded(
            notifications: [...current.notifications, ...newItems],
            unreadCount: data['unreadCount'] as int,
            totalPages: data['totalPages'] as int,
            currentPage: nextPage,
            total: data['total'] as int,
          ),
        );
      case Failure(:final error):
        getIt<CrashlyticsService>().recordAppError(error);
        emit(
          NotificationsLoaded(
            notifications: current.notifications,
            unreadCount: current.unreadCount,
            totalPages: current.totalPages,
            currentPage: current.currentPage,
            total: current.total,
          ),
        );
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
      case Failure(:final error):
        getIt<CrashlyticsService>().recordAppError(error);
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
      case Success(:final data):
        final current = state;
        if (current is NotificationsLoaded) {
          final wasUnread = current.notifications.any(
            (n) => n.id == data.id && !n.isRead,
          );
          final updated = current.notifications
              .map((n) => n.id == data.id ? data : n)
              .toList();
          emit(
            NotificationsLoaded(
              notifications: updated,
              unreadCount: wasUnread
                  ? current.unreadCount - 1
                  : current.unreadCount,
              totalPages: current.totalPages,
              currentPage: current.currentPage,
              total: current.total,
            ),
          );
        } else {
          add(LoadNotifications());
        }
      case Failure(:final error):
        emit(NotificationError(error: error));
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
        final current = state;
        if (current is NotificationsLoaded) {
          final updated = current.notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();
          emit(
            NotificationsLoaded(
              notifications: updated,
              unreadCount: 0,
              totalPages: current.totalPages,
              currentPage: current.currentPage,
              total: current.total,
            ),
          );
        } else {
          add(LoadNotifications());
        }
      case Failure(:final error):
        emit(NotificationError(error: error));
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
