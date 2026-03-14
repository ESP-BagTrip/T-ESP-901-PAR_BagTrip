import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/service/notification_service.dart';
import 'package:bloc/bloc.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationApiService _notificationService;

  NotificationBloc({NotificationApiService? notificationService})
    : _notificationService =
          notificationService ?? getIt<NotificationApiService>(),
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
    try {
      final result = await _notificationService.getNotifications(
        page: event.page,
      );
      emit(
        NotificationsLoaded(
          notifications: result['items'] as List<AppNotification>,
          unreadCount: result['unreadCount'] as int,
          totalPages: result['totalPages'] as int,
          currentPage: result['page'] as int,
          total: result['total'] as int,
        ),
      );
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onLoadUnreadCount(
    LoadUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final count = await _notificationService.getUnreadCount();
      emit(UnreadCountLoaded(count: count));
    } catch (e) {
      // Silently fail for badge count
    }
  }

  Future<void> _onMarkNotificationRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.markAsRead(event.notificationId);
      // Reload the list
      add(LoadNotifications());
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.markAllAsRead();
      add(LoadNotifications());
    } catch (e) {
      emit(NotificationError(message: e.toString()));
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
