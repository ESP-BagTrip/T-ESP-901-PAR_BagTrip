import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockNotificationRepository mockNotifRepo;

  setUp(() {
    mockNotifRepo = MockNotificationRepository();
  });

  /// Helper to stub getNotifications with a standard success response.
  void stubLoadNotificationsSuccess({
    int page = 1,
    int totalPages = 1,
    int total = 1,
    List<AppNotification>? items,
  }) {
    when(
      () => mockNotifRepo.getNotifications(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => Success(<String, dynamic>{
        'items': items ?? <AppNotification>[makeAppNotification()],
        'unreadCount': 1,
        'totalPages': totalPages,
        'page': page,
        'total': total,
      }),
    );
  }

  void stubLoadNotificationsPage(
    int page, {
    int totalPages = 2,
    List<AppNotification>? items,
  }) {
    when(
      () => mockNotifRepo.getNotifications(
        page: page,
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => Success(<String, dynamic>{
        'items':
            items ??
            <AppNotification>[makeAppNotification(id: 'notif-page-$page')],
        'unreadCount': 0,
        'totalPages': totalPages,
        'page': page,
        'total': 2,
      }),
    );
  }

  group('NotificationBloc', () {
    // ── LoadNotifications ───────────────────────────────────────────────

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationLoading, NotificationsLoaded] when LoadNotifications succeeds',
      build: () {
        stubLoadNotificationsSuccess();
        return NotificationBloc(notificationRepository: mockNotifRepo);
      },
      act: (bloc) => bloc.add(LoadNotifications()),
      expect: () => [isA<NotificationLoading>(), isA<NotificationsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as NotificationsLoaded;
        expect(state.notifications.length, 1);
        expect(state.unreadCount, 1);
        expect(state.totalPages, 1);
        expect(state.currentPage, 1);
        expect(state.total, 1);
        expect(state.isLoadingMore, false);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationLoading, NotificationError] when LoadNotifications fails',
      build: () {
        when(
          () => mockNotifRepo.getNotifications(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return NotificationBloc(notificationRepository: mockNotifRepo);
      },
      act: (bloc) => bloc.add(LoadNotifications()),
      expect: () => [isA<NotificationLoading>(), isA<NotificationError>()],
    );

    // ── LoadMoreNotifications ─────────────────────────────────────────

    blocTest<NotificationBloc, NotificationState>(
      'LoadMoreNotifications appends items from next page',
      build: () {
        stubLoadNotificationsPage(1);
        stubLoadNotificationsPage(2);
        return NotificationBloc(notificationRepository: mockNotifRepo);
      },
      seed: () => NotificationsLoaded(
        notifications: [makeAppNotification(id: 'notif-page-1')],
        unreadCount: 1,
        totalPages: 2,
        currentPage: 1,
        total: 2,
      ),
      act: (bloc) => bloc.add(LoadMoreNotifications()),
      expect: () => [
        // isLoadingMore = true
        isA<NotificationsLoaded>().having(
          (s) => s.isLoadingMore,
          'isLoadingMore',
          true,
        ),
        // Loaded with appended items
        isA<NotificationsLoaded>().having(
          (s) => s.notifications.length,
          'notifications.length',
          2,
        ),
      ],
      verify: (bloc) {
        final state = bloc.state as NotificationsLoaded;
        expect(state.currentPage, 2);
        expect(state.isLoadingMore, false);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'LoadMoreNotifications does nothing when hasMore is false',
      build: () {
        return NotificationBloc(notificationRepository: mockNotifRepo);
      },
      seed: () => NotificationsLoaded(
        notifications: [makeAppNotification()],
        unreadCount: 0,
        totalPages: 1,
        currentPage: 1,
        total: 1,
      ),
      act: (bloc) => bloc.add(LoadMoreNotifications()),
      expect: () => <NotificationState>[],
    );

    blocTest<NotificationBloc, NotificationState>(
      'LoadMoreNotifications does nothing when already loading',
      build: () {
        return NotificationBloc(notificationRepository: mockNotifRepo);
      },
      seed: () => NotificationsLoaded(
        notifications: [makeAppNotification()],
        unreadCount: 0,
        totalPages: 2,
        currentPage: 1,
        total: 2,
        isLoadingMore: true, // ignore: avoid_redundant_argument_values
      ),
      act: (bloc) => bloc.add(LoadMoreNotifications()),
      expect: () => <NotificationState>[],
    );

    blocTest<NotificationBloc, NotificationState>(
      'LoadMoreNotifications preserves data on failure',
      build: () {
        when(
          () => mockNotifRepo.getNotifications(
            page: 2,
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return NotificationBloc(notificationRepository: mockNotifRepo);
      },
      seed: () => NotificationsLoaded(
        notifications: [makeAppNotification()],
        unreadCount: 1,
        totalPages: 2,
        currentPage: 1,
        total: 2,
      ),
      act: (bloc) => bloc.add(LoadMoreNotifications()),
      expect: () => [
        isA<NotificationsLoaded>().having(
          (s) => s.isLoadingMore,
          'isLoadingMore',
          true,
        ),
        isA<NotificationsLoaded>().having(
          (s) => s.notifications.length,
          'notifications preserved',
          1,
        ),
      ],
      verify: (bloc) {
        final state = bloc.state as NotificationsLoaded;
        expect(state.currentPage, 1);
        expect(state.isLoadingMore, false);
      },
    );

    // ── LoadUnreadCount ─────────────────────────────────────────────────

    blocTest<NotificationBloc, NotificationState>(
      'emits [UnreadCountLoaded] when LoadUnreadCount succeeds',
      build: () {
        when(
          () => mockNotifRepo.getUnreadCount(),
        ).thenAnswer((_) async => const Success(5));
        return NotificationBloc(notificationRepository: mockNotifRepo);
      },
      act: (bloc) => bloc.add(LoadUnreadCount()),
      expect: () => [isA<UnreadCountLoaded>()],
      verify: (bloc) {
        final state = bloc.state as UnreadCountLoaded;
        expect(state.count, 5);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits nothing when LoadUnreadCount fails (silent failure)',
      build: () {
        when(
          () => mockNotifRepo.getUnreadCount(),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return NotificationBloc(notificationRepository: mockNotifRepo);
      },
      act: (bloc) => bloc.add(LoadUnreadCount()),
      expect: () => <NotificationState>[],
    );

    // ── MarkNotificationRead ────────────────────────────────────────────

    blocTest<NotificationBloc, NotificationState>(
      'triggers LoadNotifications after MarkNotificationRead succeeds',
      build: () {
        when(
          () => mockNotifRepo.markAsRead(any()),
        ).thenAnswer((_) async => Success(makeAppNotification(isRead: true)));
        stubLoadNotificationsSuccess();
        return NotificationBloc(notificationRepository: mockNotifRepo);
      },
      act: (bloc) => bloc.add(MarkNotificationRead(notificationId: 'notif-1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<NotificationLoading>(), isA<NotificationsLoaded>()],
      verify: (_) {
        verify(() => mockNotifRepo.markAsRead('notif-1')).called(1);
      },
    );

    // ── MarkAllRead ─────────────────────────────────────────────────────

    blocTest<NotificationBloc, NotificationState>(
      'triggers LoadNotifications after MarkAllRead succeeds',
      build: () {
        when(
          () => mockNotifRepo.markAllAsRead(),
        ).thenAnswer((_) async => const Success(3));
        stubLoadNotificationsSuccess();
        return NotificationBloc(notificationRepository: mockNotifRepo);
      },
      act: (bloc) => bloc.add(MarkAllRead()),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<NotificationLoading>(), isA<NotificationsLoaded>()],
      verify: (_) {
        verify(() => mockNotifRepo.markAllAsRead()).called(1);
      },
    );
  });
}
