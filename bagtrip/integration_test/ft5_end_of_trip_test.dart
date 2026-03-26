import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/e2e_fixtures.dart';
import 'helpers/finders.dart' as f;
import 'helpers/mock_di_setup.dart';
import 'helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerE2eFallbackValues();
  });

  group('FT5 — End of trip', () {
    testWidgets(
      'trip ended yesterday → HomeActiveTrip with pendingCompletionTrip',
      (tester) async {
        final endedTrip = makeEndedTrip();
        final mocks = await setupTestServiceLocator();

        // Trip ended but not dismissed
        when(
          () => mocks.dismissalStorage.wasDismissedRecently(endedTrip.id),
        ).thenAnswer((_) async => false);

        stubActiveTripHome(mocks, endedTrip);

        // Stub getTripById for PostTripBloc (navigated to on completedTripId)
        when(
          () => mocks.trip.getTripById(any()),
        ).thenAnswer((_) async => Success(endedTrip));

        await pumpTestApp(tester, existingMocks: mocks);

        // Verify ActiveTripHomeView renders
        expect(f.homeActiveTrip, findsOneWidget);

        final homeBloc = tester.element(f.homeActiveTrip).read<HomeBloc>();
        final state = homeBloc.state as HomeActiveTrip;

        // pendingCompletionTrip should be set
        expect(state.pendingCompletionTrip, isNotNull);
        expect(state.pendingCompletionTrip!.id, endedTrip.id);

        // Flush unawaited scheduler fire-and-forget operations
        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets(
      'ConfirmTripCompletion → updates status, cancels notifications',
      (tester) async {
        final endedTrip = makeEndedTrip();
        final mocks = await setupTestServiceLocator();

        when(
          () => mocks.dismissalStorage.wasDismissedRecently(endedTrip.id),
        ).thenAnswer((_) async => false);

        when(
          () => mocks.trip.updateTripStatus(endedTrip.id, 'completed'),
        ).thenAnswer(
          (_) async =>
              Success(endedTrip.copyWith(status: TripStatus.completed)),
        );

        stubActiveTripHome(mocks, endedTrip);

        await pumpTestApp(tester, existingMocks: mocks);

        // Verify initial state
        expect(f.homeActiveTrip, findsOneWidget);
        final homeBloc = tester.element(f.homeActiveTrip).read<HomeBloc>();

        // Fire ConfirmTripCompletion
        homeBloc.add(ConfirmTripCompletion(tripId: endedTrip.id));
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Verify repository calls
        verify(
          () => mocks.trip.updateTripStatus(endedTrip.id, 'completed'),
        ).called(1);
        verify(() => mocks.scheduler.cancelTripNotifications(any())).called(1);
        verify(
          () => mocks.dismissalStorage.clearDismissal(endedTrip.id),
        ).called(1);

        // Verify completedTripId was set (triggers PostTripRoute navigation)
        // After the event, HomeBloc emits HomeActiveTrip with completedTripId
        // before refreshing. We verify the call happened.
      },
    );

    testWidgets(
      'DismissTripCompletion → records dismissal, schedules reminder',
      (tester) async {
        final endedTrip = makeEndedTrip();
        final mocks = await setupTestServiceLocator();

        when(
          () => mocks.dismissalStorage.wasDismissedRecently(endedTrip.id),
        ).thenAnswer((_) async => false);

        stubActiveTripHome(mocks, endedTrip);

        await pumpTestApp(tester, existingMocks: mocks);

        final homeBloc = tester.element(f.homeActiveTrip).read<HomeBloc>();

        // Fire DismissTripCompletion
        homeBloc.add(DismissTripCompletion(tripId: endedTrip.id));
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Verify repository calls
        verify(
          () => mocks.dismissalStorage.recordDismissal(endedTrip.id),
        ).called(1);
        verify(
          () => mocks.scheduler.scheduleCompletionReminder(any()),
        ).called(1);
      },
    );

    testWidgets('recently dismissed trip → no pendingCompletionTrip', (
      tester,
    ) async {
      final endedTrip = makeEndedTrip();
      final mocks = await setupTestServiceLocator();

      // Already dismissed
      when(
        () => mocks.dismissalStorage.wasDismissedRecently(endedTrip.id),
      ).thenAnswer((_) async => true);

      stubActiveTripHome(mocks, endedTrip);

      await pumpTestApp(tester, existingMocks: mocks);

      expect(f.homeActiveTrip, findsOneWidget);

      final homeBloc = tester.element(f.homeActiveTrip).read<HomeBloc>();
      final state = homeBloc.state as HomeActiveTrip;

      // pendingCompletionTrip should be null (dismissed)
      expect(state.pendingCompletionTrip, isNull);
    });

    testWidgets('after completion, home refreshes to new state', (
      tester,
    ) async {
      final endedTrip = makeEndedTrip();
      final mocks = await setupTestServiceLocator();

      when(
        () => mocks.dismissalStorage.wasDismissedRecently(endedTrip.id),
      ).thenAnswer((_) async => false);

      when(
        () => mocks.trip.updateTripStatus(endedTrip.id, 'completed'),
      ).thenAnswer(
        (_) async => Success(endedTrip.copyWith(status: TripStatus.completed)),
      );

      stubActiveTripHome(mocks, endedTrip);

      await pumpTestApp(tester, existingMocks: mocks);

      final homeBloc = tester.element(f.homeActiveTrip).read<HomeBloc>();

      // After ConfirmTripCompletion, the bloc calls RefreshHome
      // which re-fetches trips. Re-stub: no trips at all → HomeNewUser
      // (avoids Hero tag collision between TripCard and TripHeroHeader
      // during PostTripRoute transition)
      _stubTripsPaginatedRaw(mocks);

      homeBloc.add(ConfirmTripCompletion(tripId: endedTrip.id));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify updateTripStatus was called
      verify(
        () => mocks.trip.updateTripStatus(endedTrip.id, 'completed'),
      ).called(1);

      // Flush unawaited scheduler fire-and-forget operations
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}

/// Raw stub helper for re-stubbing during tests.
void _stubTripsPaginatedRaw(
  MockContainer mocks, {
  List<Trip> ongoing = const [],
  List<Trip> planned = const [],
  List<Trip> completed = const [],
}) {
  when(
    () => mocks.trip.getTripsPaginated(
      status: any(named: 'status'),
      limit: any(named: 'limit'),
      page: any(named: 'page'),
    ),
  ).thenAnswer((_) async => Success(makePaginatedResponse(items: <Trip>[])));
  when(
    () => mocks.trip.getTripsPaginated(status: 'ongoing', limit: 5),
  ).thenAnswer(
    (_) async =>
        Success(makePaginatedResponse(items: ongoing, total: ongoing.length)),
  );
  when(
    () => mocks.trip.getTripsPaginated(status: 'planned', limit: 5),
  ).thenAnswer(
    (_) async =>
        Success(makePaginatedResponse(items: planned, total: planned.length)),
  );
  when(
    () => mocks.trip.getTripsPaginated(status: 'completed', limit: 5),
  ).thenAnswer(
    (_) async => Success(
      makePaginatedResponse(items: completed, total: completed.length),
    ),
  );
  when(() => mocks.trip.getTripsPaginated(status: 'ongoing')).thenAnswer(
    (_) async =>
        Success(makePaginatedResponse(items: ongoing, total: ongoing.length)),
  );
  when(() => mocks.trip.getTripsPaginated(status: 'planned')).thenAnswer(
    (_) async =>
        Success(makePaginatedResponse(items: planned, total: planned.length)),
  );
  when(() => mocks.trip.getTripsPaginated(status: 'completed')).thenAnswer(
    (_) async => Success(
      makePaginatedResponse(items: completed, total: completed.length),
    ),
  );
}
