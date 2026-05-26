import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

class _FakePendingWriteOperation extends Fake
    implements PendingWriteOperation {}

void main() {
  late MockHomeRepository mockHomeRepo;
  late MockTripRepository mockTripRepo;
  late MockActivityRepository mockActivityRepo;
  late MockConnectivityService mockConnectivityService;
  late MockPostTripDismissalStorage mockDismissalStorage;
  late MockOfflineWriteQueue mockOfflineWriteQueue;

  setUpAll(() {
    registerFallbackValue(makeTrip());
    registerFallbackValue(PreferIdleHomeOverview());
    registerFallbackValue(ResumeActiveTripHome());
    registerFallbackValue(CompleteActiveTrip());
    registerFallbackValue(_FakePendingWriteOperation());
    registerFallbackValue((Map<String, dynamic> _) async => true);
  });

  setUp(() {
    mockHomeRepo = MockHomeRepository();
    mockTripRepo = MockTripRepository();
    mockActivityRepo = MockActivityRepository();
    mockConnectivityService = MockConnectivityService();
    mockDismissalStorage = MockPostTripDismissalStorage();
    mockOfflineWriteQueue = MockOfflineWriteQueue();

    when(() => mockConnectivityService.isOnline).thenReturn(true);
    when(
      () => mockConnectivityService.onConnectivityChanged,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(
      () => mockDismissalStorage.wasDismissedRecently(any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockOfflineWriteQueue.registerHandler(any(), any()),
    ).thenReturn(null);
    when(() => mockOfflineWriteQueue.enqueue(any())).thenAnswer((_) async {});
    when(
      () => mockActivityRepo.getActivities(any()),
    ).thenAnswer((_) async => const Success([]));
  });

  /// Stub the aggregated `/home` read with the given grouped payload.
  void stubHome({
    List<Trip>? ongoing,
    List<Trip>? planned,
    List<Trip>? completed,
    List<dynamic>? activeTripActivities,
    dynamic activeTripWeather,
  }) {
    when(() => mockHomeRepo.getHome()).thenAnswer(
      (_) async => Success(
        makeHomeSummary(
          ongoingTrips: ongoing,
          plannedTrips: planned,
          completedTrips: completed,
          activeTripActivities: activeTripActivities?.cast(),
          activeTripWeather: activeTripWeather,
        ),
      ),
    );
  }

  HomeBloc buildBloc() => HomeBloc(
    homeRepository: mockHomeRepo,
    tripRepository: mockTripRepo,
    activityRepository: mockActivityRepo,
    connectivityService: mockConnectivityService,
    dismissalStorage: mockDismissalStorage,
    offlineWriteQueue: mockOfflineWriteQueue,
  );

  group('HomeBloc', () {
    // ── Test 1: New user — 0 trips → HomeIdle ────────────────────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeIdle] when there are no trips',
      build: () {
        stubHome();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeIdle>().having(
          (s) => s.user.email,
          'user.email',
          'test@example.com',
        ),
      ],
    );

    // ── Test 2: Active trip — ongoing exists → HomeActiveTrip ───────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeActiveTrip] with todayActivities when ongoing trip exists',
      build: () {
        final trip = makeTrip(
          id: 'trip-ongoing',
          status: TripStatus.ongoing,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 5)),
        );
        final todayActivity = makeActivity(
          id: 'act-today',
          tripId: 'trip-ongoing',
          date: DateTime.now(),
          startTime: '10:00',
        );
        stubHome(ongoing: [trip], activeTripActivities: [todayActivity]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeActiveTrip>()
            .having((s) => s.activeTrip.id, 'activeTrip.id', 'trip-ongoing')
            .having(
              (s) => s.todayActivities.length,
              'todayActivities.length',
              1,
            ),
      ],
    );

    // ── Test 2b: weather from aggregated payload is mapped ──────────

    blocTest<HomeBloc, HomeState>(
      'maps activeTripWeather from /home into weatherData/weatherSummary',
      build: () {
        final trip = makeTrip(
          id: 'trip-ongoing',
          status: TripStatus.ongoing,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 5)),
        );
        stubHome(
          ongoing: [trip],
          activeTripWeather: makeWeatherSummary(avgTempC: 21.0),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeActiveTrip>()
            .having(
              (s) => s.weatherData?.avgTempC,
              'weatherData.avgTempC',
              21.0,
            )
            .having((s) => s.weatherSummary, 'weatherSummary', '21°C · Sunny'),
      ],
    );

    // ── Test 3: Trip manager planned — no ongoing, planned exists ───

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeIdle] with nextTrip when only planned trips exist',
      build: () {
        final plannedTrip = makeTrip(
          id: 'planned-1',
          status: TripStatus.planned,
          startDate: DateTime.now().add(const Duration(days: 10)),
        );
        stubHome(planned: [plannedTrip]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeIdle>()
            .having((s) => s.nextTrip?.id, 'nextTrip.id', 'planned-1')
            .having(
              (s) => s.nextTripCompletion,
              'nextTripCompletion',
              equals(0),
            ),
      ],
    );

    // ── Test 4: Trip manager completed only ─────────────────────────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeIdle] with nextTrip == null when only completed trips exist',
      build: () {
        final completedTrip = makeTrip(
          id: 'completed-1',
          status: TripStatus.completed,
        );
        stubHome(completed: [completedTrip]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeIdle>()
            .having((s) => s.nextTrip, 'nextTrip', isNull)
            .having((s) => s.nextTripCompletion, 'nextTripCompletion', 0)
            .having((s) => s.completedTrips.length, 'completedTrips.length', 1),
      ],
    );

    // ── Test 5: Error — aggregated read fails → HomeError ───────────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeError] when /home fails',
      build: () {
        when(
          () => mockHomeRepo.getHome(),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [isA<HomeLoading>(), isA<HomeError>()],
    );

    // ── Test 6: RefreshHome emits state without HomeLoading ─────────

    blocTest<HomeBloc, HomeState>(
      'RefreshHome emits contextual state without HomeLoading',
      build: () {
        stubHome();
        return buildBloc();
      },
      act: (bloc) => bloc.add(RefreshHome()),
      expect: () => [isA<HomeIdle>()],
    );

    // ── Test 7: Auth failure → HomeError ────────────────────────────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeError] when /home fails with AuthenticationError',
      build: () {
        when(() => mockHomeRepo.getHome()).thenAnswer(
          (_) async => const Failure(AuthenticationError('Session expired')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [isA<HomeLoading>(), isA<HomeError>()],
    );

    // ── Test 8: Retry after error ───────────────────────────────────

    blocTest<HomeBloc, HomeState>(
      'retry after HomeError succeeds',
      build: () {
        var callCount = 0;
        when(() => mockHomeRepo.getHome()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return const Failure(AuthenticationError('expired'));
          }
          return Success(makeHomeSummary());
        });
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadHome());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(LoadHome());
      },
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>(),
        isA<HomeLoading>(),
        isA<HomeIdle>(),
      ],
    );

    // ── Test 9: No activities in payload → empty todayActivities ────

    blocTest<HomeBloc, HomeState>(
      'emits HomeActiveTrip with empty todayActivities when payload has none',
      build: () {
        final trip = makeTrip(
          id: 'trip-ongoing',
          status: TripStatus.ongoing,
          startDate: DateTime.now(),
        );
        stubHome(ongoing: [trip]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeActiveTrip>().having(
          (s) => s.todayActivities,
          'todayActivities',
          isEmpty,
        ),
      ],
    );

    // ── Test 10: Single aggregated call (no fan-out) ────────────────

    blocTest<HomeBloc, HomeState>(
      'loads home with a single getHome() call (no fan-out)',
      build: () {
        stubHome();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      verify: (_) {
        verify(() => mockHomeRepo.getHome()).called(1);
        verifyNoMoreInteractions(mockHomeRepo);
        // No per-status paginated reads anymore.
        verifyNever(() => mockTripRepo.getTripsPaginated());
      },
    );

    blocTest<HomeBloc, HomeState>(
      'PreferIdleHomeOverview emits HomeIdle with backgroundOngoingTrip',
      build: () {
        final trip = makeTrip(
          id: 'trip-ongoing',
          status: TripStatus.ongoing,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 5)),
        );
        stubHome(ongoing: [trip]);
        return buildBloc();
      },
      seed: () {
        final trip = makeTrip(
          id: 'trip-ongoing',
          status: TripStatus.ongoing,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 5)),
        );
        return HomeActiveTrip(user: makeUser(), activeTrip: trip);
      },
      act: (bloc) => bloc.add(PreferIdleHomeOverview()),
      expect: () => [
        isA<HomeIdle>().having(
          (s) => s.backgroundOngoingTrip?.id,
          'backgroundOngoingTrip',
          'trip-ongoing',
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'ResumeActiveTripHome emits HomeActiveTrip when ongoing exists',
      build: () {
        final trip = makeTrip(
          id: 'trip-og',
          status: TripStatus.ongoing,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 3)),
        );
        stubHome(ongoing: [trip]);
        return buildBloc();
      },
      seed: () {
        final trip = makeTrip(
          id: 'trip-og',
          status: TripStatus.ongoing,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 3)),
        );
        return HomeIdle(user: makeUser(), backgroundOngoingTrip: trip);
      },
      act: (bloc) => bloc.add(ResumeActiveTripHome()),
      expect: () => [
        isA<HomeActiveTrip>().having(
          (s) => s.activeTrip.id,
          'activeTrip.id',
          'trip-og',
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'CompleteActiveTrip calls updateTripStatus',
      build: () {
        final trip = makeTrip(
          id: 'trip-end',
          status: TripStatus.ongoing,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 2)),
        );
        when(
          () => mockTripRepo.updateTripStatus('trip-end', 'completed'),
        ).thenAnswer((_) async => Success(trip));
        stubHome();
        return buildBloc();
      },
      seed: () {
        final trip = makeTrip(
          id: 'trip-end',
          status: TripStatus.ongoing,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 2)),
        );
        return HomeActiveTrip(user: makeUser(), activeTrip: trip);
      },
      act: (bloc) => bloc.add(CompleteActiveTrip()),
      expect: () => [
        isA<HomeIdle>().having(
          (s) => s.backgroundOngoingTrip,
          'backgroundOngoingTrip',
          isNull,
        ),
      ],
      verify: (_) {
        verify(
          () => mockTripRepo.updateTripStatus('trip-end', 'completed'),
        ).called(1);
      },
    );

    // ── ConfirmTripCompletion sets completedTripId for navigation ───

    blocTest<HomeBloc, HomeState>(
      'ConfirmTripCompletion emits HomeActiveTrip with completedTripId then refreshes',
      build: () {
        when(
          () => mockTripRepo.updateTripStatus('trip-done', 'completed'),
        ).thenAnswer((_) async => Success(makeTrip(id: 'trip-done')));
        when(
          () => mockDismissalStorage.clearDismissal(any()),
        ).thenAnswer((_) async {});
        stubHome();
        return buildBloc();
      },
      seed: () {
        final trip = makeTrip(
          id: 'trip-done',
          status: TripStatus.ongoing,
          startDate: DateTime.now().subtract(const Duration(days: 3)),
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        return HomeActiveTrip(user: makeUser(), activeTrip: trip);
      },
      act: (bloc) => bloc.add(ConfirmTripCompletion(tripId: 'trip-done')),
      expect: () => [
        isA<HomeActiveTrip>().having(
          (s) => s.completedTripId,
          'completedTripId',
          'trip-done',
        ),
        // RefreshHome → idle (no trips left in stubbed payload).
        isA<HomeIdle>(),
      ],
      verify: (_) {
        verify(
          () => mockTripRepo.updateTripStatus('trip-done', 'completed'),
        ).called(1);
      },
    );

    // ── Offline persistence: registers replay handler at init ───────

    test('registers trip:updateTripStatus replay handler on init', () {
      stubHome();
      buildBloc();
      verify(
        () => mockOfflineWriteQueue.registerHandler(
          kHomeTripStatusReplayKey,
          any(),
        ),
      ).called(1);
    });

    // ── Offline persistence: enqueues PendingWriteOperation ─────────

    blocTest<HomeBloc, HomeState>(
      'offline PLANNED→ONGOING transition enqueues a PendingWriteOperation',
      build: () {
        when(() => mockConnectivityService.isOnline).thenReturn(false);
        final plannedNow = makeTrip(
          id: 'planned-now',
          status: TripStatus.planned,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 3)),
        );
        stubHome(planned: [plannedNow]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      verify: (_) {
        final captured = verify(
          () => mockOfflineWriteQueue.enqueue(captureAny()),
        ).captured;
        expect(captured.length, 1);
        final op = captured.first as PendingWriteOperation;
        expect(op.repository, 'trip');
        expect(op.method, 'updateTripStatus');
        expect(op.arguments['tripId'], 'planned-now');
        expect(op.arguments['status'], 'ongoing');
        // The deferred PATCH must NOT run inline while offline — only the
        // queue replay does it later. updateTripStatus is never called here.
        verifyNever(() => mockTripRepo.updateTripStatus(any(), any()));
      },
    );

    // ── Online PLANNED→ONGOING transition PATCHes immediately ───────

    blocTest<HomeBloc, HomeState>(
      'online PLANNED→ONGOING transition calls updateTripStatus directly',
      build: () {
        final plannedNow = makeTrip(
          id: 'planned-now',
          status: TripStatus.planned,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 3)),
        );
        when(
          () => mockTripRepo.updateTripStatus('planned-now', 'ongoing'),
        ).thenAnswer((_) async => Success(plannedNow));
        stubHome(planned: [plannedNow]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      verify: (_) {
        verify(
          () => mockTripRepo.updateTripStatus('planned-now', 'ongoing'),
        ).called(1);
        verifyNever(() => mockOfflineWriteQueue.enqueue(any()));
      },
    );

    // ── Offline persistence: replay handler calls updateTripStatus ──

    test(
      'registered replay handler calls updateTripStatus and returns success',
      () async {
        ReplayHandler? capturedHandler;
        when(
          () => mockOfflineWriteQueue.registerHandler(
            kHomeTripStatusReplayKey,
            any(),
          ),
        ).thenAnswer((invocation) {
          capturedHandler = invocation.positionalArguments[1] as ReplayHandler;
        });
        when(
          () => mockTripRepo.updateTripStatus('planned-now', 'ongoing'),
        ).thenAnswer((_) async => Success(makeTrip(id: 'planned-now')));

        buildBloc();

        expect(capturedHandler, isNotNull);
        final ok = await capturedHandler!({
          'tripId': 'planned-now',
          'status': 'ongoing',
        });
        expect(ok, isTrue);
        verify(
          () => mockTripRepo.updateTripStatus('planned-now', 'ongoing'),
        ).called(1);
      },
    );

    test(
      'replay handler returns false when updateTripStatus fails (keeps op queued)',
      () async {
        ReplayHandler? capturedHandler;
        when(
          () => mockOfflineWriteQueue.registerHandler(
            kHomeTripStatusReplayKey,
            any(),
          ),
        ).thenAnswer((invocation) {
          capturedHandler = invocation.positionalArguments[1] as ReplayHandler;
        });
        when(
          () => mockTripRepo.updateTripStatus('planned-now', 'ongoing'),
        ).thenAnswer((_) async => const Failure(NetworkError('offline')));

        buildBloc();

        final ok = await capturedHandler!({
          'tripId': 'planned-now',
          'status': 'ongoing',
        });
        expect(ok, isFalse);
      },
    );
  });
}
