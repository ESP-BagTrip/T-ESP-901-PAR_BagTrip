import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockTripRepository mockTripRepo;
  late MockAuthRepository mockAuthRepo;
  late MockActivityRepository mockActivityRepo;

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockAuthRepo = MockAuthRepository();
    mockActivityRepo = MockActivityRepository();
  });

  // Helper to stub all trip calls as success with given data
  void stubTrips({
    PaginatedResponse<Trip>? ongoing,
    PaginatedResponse<Trip>? planned,
    PaginatedResponse<Trip>? completed,
  }) {
    when(
      () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 5),
    ).thenAnswer(
      (_) async =>
          Success(ongoing ?? makePaginatedResponse<Trip>(items: [], total: 0)),
    );
    when(
      () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 5),
    ).thenAnswer(
      (_) async =>
          Success(planned ?? makePaginatedResponse<Trip>(items: [], total: 0)),
    );
    when(
      () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 5),
    ).thenAnswer(
      (_) async => Success(
        completed ?? makePaginatedResponse<Trip>(items: [], total: 0),
      ),
    );
  }

  void stubUserSuccess() {
    when(
      () => mockAuthRepo.getCurrentUser(),
    ).thenAnswer((_) async => Success(makeUser()));
  }

  void stubActivities() {
    when(
      () => mockActivityRepo.getActivities(any()),
    ).thenAnswer((_) async => const Success([]));
  }

  HomeBloc buildBloc() => HomeBloc(
    tripRepository: mockTripRepo,
    authRepository: mockAuthRepo,
    activityRepository: mockActivityRepo,
  );

  group('HomeBloc', () {
    // ── Test 1: New user — 0 trips → HomeNewUser ────────────────────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeNewUser] when totalTrips is 0',
      build: () {
        stubUserSuccess();
        stubTrips();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeNewUser>().having(
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
        stubUserSuccess();
        final trip = makeTrip(
          id: 'trip-ongoing',
          status: TripStatus.ongoing,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 5)),
        );
        stubTrips(
          ongoing: makePaginatedResponse(items: [trip]),
          planned: makePaginatedResponse<Trip>(items: [], total: 2),
          completed: makePaginatedResponse<Trip>(items: [], total: 3),
        );
        // Return an activity for today
        final todayActivity = makeActivity(
          id: 'act-today',
          tripId: 'trip-ongoing',
          date: DateTime.now(),
          startTime: '10:00',
        );
        when(
          () => mockActivityRepo.getActivities('trip-ongoing'),
        ).thenAnswer((_) async => Success([todayActivity]));
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

    // ── Test 3: Trip manager planned — no ongoing, planned exists ───

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeTripManager] with nextTrip when only planned trips exist',
      build: () {
        stubUserSuccess();
        stubActivities();
        final plannedTrip = makeTrip(
          id: 'planned-1',
          status: TripStatus.planned,
          startDate: DateTime.now().add(const Duration(days: 10)),
        );
        stubTrips(planned: makePaginatedResponse(items: [plannedTrip]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeTripManager>()
            .having((s) => s.nextTrip?.id, 'nextTrip.id', 'planned-1')
            .having(
              (s) => s.nextTripCompletion,
              'nextTripCompletion',
              greaterThan(0),
            ),
      ],
    );

    // ── Test 4: Trip manager completed only ─────────────────────────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeTripManager] with nextTrip == null when only completed trips exist',
      build: () {
        stubUserSuccess();
        stubActivities();
        final completedTrip = makeTrip(
          id: 'completed-1',
          status: TripStatus.completed,
        );
        stubTrips(completed: makePaginatedResponse(items: [completedTrip]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeTripManager>()
            .having((s) => s.nextTrip, 'nextTrip', isNull)
            .having((s) => s.nextTripCompletion, 'nextTripCompletion', 0)
            .having((s) => s.completedTrips.length, 'completedTrips.length', 1),
      ],
    );

    // ── Test 5: Error — all calls fail → HomeError ──────────────────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeError] when all trip calls fail',
      build: () {
        stubUserSuccess();
        when(
          () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 5),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 5),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 5),
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
        stubUserSuccess();
        stubTrips();
        return buildBloc();
      },
      act: (bloc) => bloc.add(RefreshHome()),
      expect: () => [isA<HomeNewUser>()],
    );

    // ── Test 7: Auth failure → HomeError ────────────────────────────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeError] when auth fails with AuthenticationError',
      build: () {
        when(() => mockAuthRepo.getCurrentUser()).thenAnswer(
          (_) async => const Failure(AuthenticationError('Session expired')),
        );
        stubTrips();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [isA<HomeLoading>(), isA<HomeError>()],
    );

    // ── Test 8: Graceful degradation (1 call fails, 2 OK) ──────────

    blocTest<HomeBloc, HomeState>(
      'emits loaded state with graceful degradation when 1 trip call fails',
      build: () {
        stubUserSuccess();
        stubActivities();
        when(
          () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 5),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 5),
        ).thenAnswer(
          (_) async =>
              Success(makePaginatedResponse<Trip>(items: [], total: 2)),
        );
        when(
          () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 5),
        ).thenAnswer(
          (_) async => Success(makePaginatedResponse<Trip>(items: [])),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [isA<HomeLoading>(), isA<HomeTripManager>()],
    );

    // ── Test 9: Retry after error ───────────────────────────────────

    blocTest<HomeBloc, HomeState>(
      'retry after HomeError succeeds',
      build: () {
        var callCount = 0;
        when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return const Failure(AuthenticationError('expired'));
          }
          return Success(makeUser());
        });
        stubTrips();
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
        isA<HomeNewUser>(),
      ],
    );

    // ── Test 10: Fetch activities fails → HomeActiveTrip with empty list

    blocTest<HomeBloc, HomeState>(
      'emits HomeActiveTrip with empty todayActivities when getActivities fails',
      build: () {
        stubUserSuccess();
        final trip = makeTrip(
          id: 'trip-ongoing',
          status: TripStatus.ongoing,
          startDate: DateTime.now(),
        );
        stubTrips(ongoing: makePaginatedResponse(items: [trip]));
        when(
          () => mockActivityRepo.getActivities('trip-ongoing'),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
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

    // ── Test 11: Calls each endpoint exactly once ───────────────────

    blocTest<HomeBloc, HomeState>(
      'calls each endpoint exactly once (no duplicates)',
      build: () {
        stubUserSuccess();
        stubTrips();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      verify: (_) {
        verify(() => mockAuthRepo.getCurrentUser()).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 5),
        ).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 5),
        ).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 5),
        ).called(1);
        verifyNoMoreInteractions(mockTripRepo);
      },
    );
  });
}
