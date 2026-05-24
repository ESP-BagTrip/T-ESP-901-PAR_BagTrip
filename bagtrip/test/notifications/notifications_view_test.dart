import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:bagtrip/notifications/view/notifications_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_widget.dart';
import '../helpers/test_fixtures.dart';

class _MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

void main() {
  late _MockNotificationBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoadNotifications());
    registerFallbackValue(NotificationInitial());
  });

  setUp(() {
    mockBloc = _MockNotificationBloc();
  });

  Future<void> pump(WidgetTester tester, NotificationState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<NotificationState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<NotificationBloc>.value(
        value: mockBloc,
        child: const NotificationsView(),
      ),
    );
    await tester.pump();
  }

  group('NotificationsView', () {
    testWidgets('renders initial state', (tester) async {
      await pump(tester, NotificationInitial());
      expect(find.byType(NotificationsView), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await pump(tester, NotificationLoading());
      expect(find.byType(NotificationsView), findsOneWidget);
    });

    testWidgets('renders empty loaded state', (tester) async {
      await pump(
        tester,
        NotificationsLoaded(
          notifications: const [],
          unreadCount: 0,
          totalPages: 1,
          currentPage: 1,
          total: 0,
        ),
      );
      expect(find.byType(NotificationsView), findsOneWidget);
    });

    testWidgets('renders loaded with notifications and unread count', (
      tester,
    ) async {
      await pump(
        tester,
        NotificationsLoaded(
          notifications: [
            makeAppNotification(id: 'n-1', createdAt: DateTime.now()),
            makeAppNotification(
              id: 'n-2',
              isRead: true,
              createdAt: DateTime.now(),
            ),
          ],
          unreadCount: 1,
          totalPages: 1,
          currentPage: 1,
          total: 2,
        ),
      );
      expect(find.byType(NotificationsView), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await pump(
        tester,
        NotificationError(error: const NetworkError('offline')),
      );
      expect(find.byType(NotificationsView), findsOneWidget);
    });
  });
}
