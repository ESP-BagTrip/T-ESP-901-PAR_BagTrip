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

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockAuthRepo = MockAuthRepository();
  });

  // Helper to stub all trip calls as success with given data
  void stubTrips({
    PaginatedResponse<Trip>? ongoing,
    PaginatedResponse<Trip>? planned,
    PaginatedResponse<Trip>? completed,
  }) {
    when(
      () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 1),
    ).thenAnswer(
      (_) async =>
          Success(ongoing ?? makePaginatedResponse<Trip>(items: [], total: 0)),
    );
    when(
      () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 1),
    ).thenAnswer(
      (_) async =>
          Success(planned ?? makePaginatedResponse<Trip>(items: [], total: 0)),
    );
    when(
      () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 1),
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

  group('HomeBloc', () {
    // ── Test 1: All calls succeed ────────────────────────────────────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeLoaded] when all calls succeed',
      build: () {
        stubUserSuccess();
        final trip = makeTrip(
          id: 'trip-ongoing',
          status: TripStatus.ongoing,
          startDate: DateTime.now().add(const Duration(days: 5)),
        );
        stubTrips(
          ongoing: makePaginatedResponse(items: [trip]),
          planned: makePaginatedResponse<Trip>(items: [], total: 2),
          completed: makePaginatedResponse<Trip>(items: [], total: 3),
        );
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>()
            .having((s) => s.user, 'user', isNotNull)
            .having((s) => s.totalTrips, 'totalTrips', 6)
            .having((s) => s.nextTrip, 'nextTrip', isNotNull)
            .having((s) => s.nextTrip!.id, 'nextTrip.id', 'trip-ongoing'),
      ],
    );

    // ── Test 2: Auth fails with AuthenticationError ──────────────────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeError] when auth fails with AuthenticationError',
      build: () {
        when(() => mockAuthRepo.getCurrentUser()).thenAnswer(
          (_) async => const Failure(AuthenticationError('Session expired')),
        );
        stubTrips();
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [isA<HomeLoading>(), isA<HomeError>()],
    );

    // ── Test 3: All 3 trip calls fail ────────────────────────────────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeError] when all trip calls fail',
      build: () {
        stubUserSuccess();
        when(
          () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 1),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 1),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 1),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [isA<HomeLoading>(), isA<HomeError>()],
    );

    // ── Test 4: 1 trip call fails, 2 OK → graceful degradation ──────

    blocTest<HomeBloc, HomeState>(
      'emits [HomeLoading, HomeLoaded] with graceful degradation when 1 trip call fails',
      build: () {
        stubUserSuccess();
        when(
          () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 1),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 1),
        ).thenAnswer(
          (_) async =>
              Success(makePaginatedResponse<Trip>(items: [], total: 2)),
        );
        when(
          () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 1),
        ).thenAnswer(
          (_) async => Success(makePaginatedResponse<Trip>(items: [])),
        );
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having((s) => s.totalTrips, 'totalTrips', 3),
      ],
    );

    // ── Test 5: Exactly 1 call per endpoint (no duplicates) ─────────

    blocTest<HomeBloc, HomeState>(
      'calls each endpoint exactly once (no duplicates)',
      build: () {
        stubUserSuccess();
        stubTrips();
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      verify: (_) {
        verify(() => mockAuthRepo.getCurrentUser()).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 1),
        ).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 1),
        ).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 1),
        ).called(1);
        verifyNoMoreInteractions(mockTripRepo);
      },
    );

    // ── Test 6: Next trip comes from ongoing in priority ─────────────

    blocTest<HomeBloc, HomeState>(
      'next trip comes from ongoing in priority over planned',
      build: () {
        stubUserSuccess();
        final ongoingTrip = makeTrip(
          id: 'ongoing-1',
          status: TripStatus.ongoing,
          startDate: DateTime.now().add(const Duration(days: 10)),
        );
        final plannedTrip = makeTrip(
          id: 'planned-1',
          status: TripStatus.planned,
          startDate: DateTime.now().add(const Duration(days: 3)),
        );
        stubTrips(
          ongoing: makePaginatedResponse(items: [ongoingTrip]),
          planned: makePaginatedResponse(items: [plannedTrip]),
        );
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (s) => s.nextTrip!.id,
          'nextTrip.id',
          'ongoing-1',
        ),
      ],
    );

    // ── Test 7: Fallback to planned if ongoing is empty ──────────────

    blocTest<HomeBloc, HomeState>(
      'fallback to planned if ongoing is empty',
      build: () {
        stubUserSuccess();
        final plannedTrip = makeTrip(
          id: 'planned-1',
          status: TripStatus.planned,
          startDate: DateTime.now().add(const Duration(days: 3)),
        );
        stubTrips(
          ongoing: makePaginatedResponse<Trip>(items: [], total: 0),
          planned: makePaginatedResponse(items: [plannedTrip]),
        );
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (s) => s.nextTrip!.id,
          'nextTrip.id',
          'planned-1',
        ),
      ],
    );

    // ── Test 8: daysUntil = 0 for past dates ─────────────────────────

    blocTest<HomeBloc, HomeState>(
      'daysUntil is 0 for past dates',
      build: () {
        stubUserSuccess();
        final pastTrip = makeTrip(
          id: 'past-trip',
          status: TripStatus.ongoing,
          startDate: DateTime.now().subtract(const Duration(days: 2)),
        );
        stubTrips(ongoing: makePaginatedResponse(items: [pastTrip]));
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having((s) => s.daysUntilNextTrip, 'daysUntil', 0),
      ],
    );

    // ── Test 9: Retry after HomeError succeeds ───────────────────────

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
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
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
        isA<HomeLoaded>(),
      ],
    );
  });
}
