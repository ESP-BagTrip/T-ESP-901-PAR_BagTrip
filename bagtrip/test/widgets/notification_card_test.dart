import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:bagtrip/notifications/widgets/notification_card.dart';
import 'package:bagtrip/service/crashlytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockNotificationRepository mockNotifRepo;

  setUp(() {
    mockNotifRepo = MockNotificationRepository();

    if (getIt.isRegistered<CrashlyticsService>()) {
      getIt.unregister<CrashlyticsService>();
    }
    final mockCrashlytics = MockCrashlyticsService();
    getIt.registerLazySingleton<CrashlyticsService>(() => mockCrashlytics);
    registerFallbackValue(const UnknownError(''));
    registerFallbackValue(StackTrace.current);
    when(
      () => mockCrashlytics.recordAppError(
        any(),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() {
    if (getIt.isRegistered<CrashlyticsService>()) {
      getIt.unregister<CrashlyticsService>();
    }
  });

  Widget buildSubject(
    AppNotification notification, {
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<NotificationBloc>(
        create: (_) => NotificationBloc(notificationRepository: mockNotifRepo),
        child: Scaffold(body: NotificationCard(notification: notification)),
      ),
    );
  }

  group('NotificationCard', () {
    // ── Relative time l10n ────────────────────────────────────────────

    group('relative time localization', () {
      testWidgets('displays "Just now" in EN for < 1 min ago', (tester) async {
        final notif = makeAppNotification(
          createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        await tester.pumpWidget(buildSubject(notif));
        await tester.pumpAndSettle();

        expect(find.text('Just now'), findsOneWidget);
      });

      testWidgets('displays "À l\'instant" in FR for < 1 min ago', (
        tester,
      ) async {
        final notif = makeAppNotification(
          createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        await tester.pumpWidget(
          buildSubject(notif, locale: const Locale('fr')),
        );
        await tester.pumpAndSettle();

        expect(find.text('À l\'instant'), findsOneWidget);
      });

      testWidgets('displays minutes ago in EN', (tester) async {
        final notif = makeAppNotification(
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        await tester.pumpWidget(buildSubject(notif));
        await tester.pumpAndSettle();

        expect(find.text('5 min ago'), findsOneWidget);
      });

      testWidgets('displays minutes ago in FR', (tester) async {
        final notif = makeAppNotification(
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        await tester.pumpWidget(
          buildSubject(notif, locale: const Locale('fr')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Il y a 5 min'), findsOneWidget);
      });

      testWidgets('displays hours ago in EN', (tester) async {
        final notif = makeAppNotification(
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        );
        await tester.pumpWidget(buildSubject(notif));
        await tester.pumpAndSettle();

        expect(find.text('3h ago'), findsOneWidget);
      });

      testWidgets('displays hours ago in FR', (tester) async {
        final notif = makeAppNotification(
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        );
        await tester.pumpWidget(
          buildSubject(notif, locale: const Locale('fr')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Il y a 3h'), findsOneWidget);
      });

      testWidgets('displays days ago in EN for < 7 days', (tester) async {
        final notif = makeAppNotification(
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        );
        await tester.pumpWidget(buildSubject(notif));
        await tester.pumpAndSettle();

        expect(find.text('2d ago'), findsOneWidget);
      });

      testWidgets('displays days ago in FR for < 7 days', (tester) async {
        final notif = makeAppNotification(
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        );
        await tester.pumpWidget(
          buildSubject(notif, locale: const Locale('fr')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Il y a 2j'), findsOneWidget);
      });

      testWidgets('displays date for >= 7 days ago', (tester) async {
        final date = DateTime(2026, 1, 15);
        final notif = makeAppNotification(createdAt: date);
        await tester.pumpWidget(buildSubject(notif));
        await tester.pumpAndSettle();

        expect(find.text('15/1/2026'), findsOneWidget);
      });
    });

    // ── Icon mapping ─────────────────────────────────────────────────

    group('icon mapping', () {
      final iconCases = <String, IconData>{
        'DEPARTURE_REMINDER': Icons.flight_takeoff,
        'FLIGHT_H4': Icons.airplanemode_active,
        'FLIGHT_H1': Icons.airplanemode_active,
        'MORNING_SUMMARY': Icons.wb_sunny,
        'ACTIVITY_H1': Icons.event,
        'BUDGET_ALERT': Icons.account_balance_wallet,
        'TRIP_STARTED': Icons.play_circle,
        'TRIP_ENDED': Icons.check_circle,
        'TRIP_SHARED': Icons.group_add,
        'UNKNOWN_TYPE': Icons.notifications,
      };

      for (final entry in iconCases.entries) {
        testWidgets('shows correct icon for ${entry.key}', (tester) async {
          final notif = makeAppNotification(type: entry.key);
          await tester.pumpWidget(buildSubject(notif));
          await tester.pumpAndSettle();

          final icon = tester.widget<Icon>(find.byType(Icon));
          expect(icon.icon, entry.value);
        });
      }
    });

    // ── Unread indicator ─────────────────────────────────────────────

    group('unread indicator', () {
      testWidgets('shows unread dot when isRead is false', (tester) async {
        final notif = makeAppNotification();
        await tester.pumpWidget(buildSubject(notif));
        await tester.pumpAndSettle();

        // Unread dot = 8x8 Container with circle shape
        final containers = tester.widgetList<Container>(find.byType(Container));
        final dotContainer = containers.where((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.shape == BoxShape.circle &&
                c.constraints?.maxWidth == 8;
          }
          return false;
        });
        expect(dotContainer.length, 1);
      });

      testWidgets('hides unread dot when isRead is true', (tester) async {
        final notif = makeAppNotification(isRead: true);
        await tester.pumpWidget(buildSubject(notif));
        await tester.pumpAndSettle();

        final containers = tester.widgetList<Container>(find.byType(Container));
        final dotContainer = containers.where((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.shape == BoxShape.circle &&
                c.constraints?.maxWidth == 8;
          }
          return false;
        });
        expect(dotContainer.length, 0);
      });
    });

    // ── Content display ──────────────────────────────────────────────

    testWidgets('displays title and body', (tester) async {
      final notif = makeAppNotification(
        title: 'Bon voyage !',
        body: 'Votre voyage commence demain',
      );
      await tester.pumpWidget(buildSubject(notif));
      await tester.pumpAndSettle();

      expect(find.text('Bon voyage !'), findsOneWidget);
      expect(find.text('Votre voyage commence demain'), findsOneWidget);
    });

    // ── Tap marks as read ────────────────────────────────────────────

    testWidgets('tapping an unread notification marks it as read', (
      tester,
    ) async {
      when(
        () => mockNotifRepo.markAsRead(any()),
      ).thenAnswer((_) async => Success(makeAppNotification(isRead: true)));
      when(
        () => mockNotifRepo.getNotifications(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => Success(<String, dynamic>{
          'items': <AppNotification>[makeAppNotification(isRead: true)],
          'unreadCount': 0,
          'totalPages': 1,
          'page': 1,
          'total': 1,
        }),
      );

      final notif = makeAppNotification();
      await tester.pumpWidget(buildSubject(notif));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      verify(() => mockNotifRepo.markAsRead('notif-1')).called(1);
    });

    testWidgets('tapping a read notification does not call markAsRead', (
      tester,
    ) async {
      final notif = makeAppNotification(isRead: true);
      await tester.pumpWidget(buildSubject(notif));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      verifyNever(() => mockNotifRepo.markAsRead(any()));
    });
  });
}
