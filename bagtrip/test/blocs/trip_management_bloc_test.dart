import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockTripRepository mockTripRepo;

  setUpAll(() {
    registerFallbackValue(DateTime(2024));
  });

  setUp(() {
    mockTripRepo = MockTripRepository();
  });

  group('TripManagementBloc', () {
    // ── LoadTrips ───────────────────────────────────────────────────────

    blocTest<TripManagementBloc, TripManagementState>(
      'emits [TripsLoading, TripsLoaded] when LoadTrips succeeds',
      build: () {
        when(
          () => mockTripRepo.getGroupedTrips(),
        ).thenAnswer((_) async => Success(makeTripGrouped()));
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      act: (bloc) => bloc.add(LoadTrips()),
      expect: () => [isA<TripsLoading>(), isA<TripsLoaded>()],
      verify: (_) {
        verify(() => mockTripRepo.getGroupedTrips()).called(1);
      },
    );

    blocTest<TripManagementBloc, TripManagementState>(
      'emits [TripsLoading, TripError] when LoadTrips fails',
      build: () {
        when(
          () => mockTripRepo.getGroupedTrips(),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      act: (bloc) => bloc.add(LoadTrips()),
      expect: () => [isA<TripsLoading>(), isA<TripError>()],
    );

    // ── LoadTripsByStatus ─────────────────────────────────────────────

    blocTest<TripManagementBloc, TripManagementState>(
      'emits [TripsLoading, TripsTabLoaded] when LoadTripsByStatus succeeds',
      build: () {
        when(
          () => mockTripRepo.getTripsPaginated(
            page: any(named: 'page'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async => Success(
            PaginatedResponse<Trip>(
              items: [makeTrip(status: TripStatus.ongoing)],
              total: 1,
              page: 1,
              totalPages: 1,
            ),
          ),
        );
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      act: (bloc) => bloc.add(LoadTripsByStatus(status: 'ongoing')),
      expect: () => [isA<TripsLoading>(), isA<TripsTabLoaded>()],
      verify: (bloc) {
        final state = bloc.state as TripsTabLoaded;
        final tab = state.getTab('ongoing');
        expect(tab.trips.length, 1);
        expect(tab.currentPage, 1);
        expect(tab.hasMore, false);
      },
    );

    blocTest<TripManagementBloc, TripManagementState>(
      'LoadTripsByStatus preserves other tabs data',
      build: () {
        when(
          () => mockTripRepo.getTripsPaginated(
            page: any(named: 'page'),
            status: 'planned',
          ),
        ).thenAnswer(
          (_) async => Success(
            PaginatedResponse<Trip>(
              items: [makeTrip(status: TripStatus.planned)],
              total: 1,
              page: 1,
              totalPages: 1,
            ),
          ),
        );
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      seed: () => TripsTabLoaded(
        tabs: {
          'ongoing': TripTabData(
            trips: [makeTrip(status: TripStatus.ongoing)],
            currentPage: 1,
            totalPages: 1,
          ),
        },
      ),
      act: (bloc) => bloc.add(LoadTripsByStatus(status: 'planned')),
      expect: () => [isA<TripsTabLoaded>()],
      verify: (bloc) {
        final state = bloc.state as TripsTabLoaded;
        // Ongoing tab preserved
        expect(state.getTab('ongoing').trips.length, 1);
        // Planned tab loaded
        expect(state.getTab('planned').trips.length, 1);
      },
    );

    // ── LoadMoreTripsByStatus ─────────────────────────────────────────

    blocTest<TripManagementBloc, TripManagementState>(
      'LoadMoreTripsByStatus appends items',
      build: () {
        when(
          () => mockTripRepo.getTripsPaginated(page: 2, status: 'ongoing'),
        ).thenAnswer(
          (_) async => Success(
            PaginatedResponse<Trip>(
              items: [makeTrip(id: 'trip-2', status: TripStatus.ongoing)],
              total: 2,
              page: 2,
              totalPages: 2,
            ),
          ),
        );
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      seed: () => TripsTabLoaded(
        tabs: {
          'ongoing': TripTabData(
            trips: [makeTrip(status: TripStatus.ongoing)],
            currentPage: 1,
            totalPages: 2,
          ),
        },
      ),
      act: (bloc) => bloc.add(LoadMoreTripsByStatus(status: 'ongoing')),
      expect: () => [
        // isLoadingMore = true
        isA<TripsTabLoaded>().having(
          (s) => s.getTab('ongoing').isLoadingMore,
          'isLoadingMore',
          true,
        ),
        // Appended
        isA<TripsTabLoaded>().having(
          (s) => s.getTab('ongoing').trips.length,
          'trips.length',
          2,
        ),
      ],
      verify: (bloc) {
        final state = bloc.state as TripsTabLoaded;
        expect(state.getTab('ongoing').currentPage, 2);
        expect(state.getTab('ongoing').hasMore, false);
      },
    );

    blocTest<TripManagementBloc, TripManagementState>(
      'LoadMoreTripsByStatus does nothing when hasMore is false',
      build: () => TripManagementBloc(tripRepository: mockTripRepo),
      seed: () => TripsTabLoaded(
        tabs: {
          'ongoing': TripTabData(
            trips: [makeTrip()],
            currentPage: 1,
            totalPages: 1,
          ),
        },
      ),
      act: (bloc) => bloc.add(LoadMoreTripsByStatus(status: 'ongoing')),
      expect: () => <TripManagementState>[],
    );

    blocTest<TripManagementBloc, TripManagementState>(
      'LoadMoreTripsByStatus does nothing when already loading',
      build: () => TripManagementBloc(tripRepository: mockTripRepo),
      seed: () => TripsTabLoaded(
        tabs: {
          'ongoing': TripTabData(
            trips: [makeTrip()],
            currentPage: 1,
            totalPages: 2,
            isLoadingMore: true,
          ),
        },
      ),
      act: (bloc) => bloc.add(LoadMoreTripsByStatus(status: 'ongoing')),
      expect: () => <TripManagementState>[],
    );

    // ── CreateTrip ──────────────────────────────────────────────────────

    blocTest<TripManagementBloc, TripManagementState>(
      'emits [TripCreating, TripCreated] when CreateTrip succeeds',
      build: () {
        when(
          () => mockTripRepo.createTrip(
            title: any(named: 'title'),
            description: any(named: 'description'),
            destinationName: any(named: 'destinationName'),
            nbTravelers: any(named: 'nbTravelers'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => Success(makeTrip()));
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      act: (bloc) => bloc.add(
        CreateTrip(
          title: 'Paris Trip',
          destinationName: 'Paris',
          nbTravelers: 2,
          startDate: DateTime(2024, 6),
          endDate: DateTime(2024, 6, 7),
        ),
      ),
      expect: () => [isA<TripCreating>(), isA<TripCreated>()],
    );

    // ── LoadTripHome ────────────────────────────────────────────────────

    blocTest<TripManagementBloc, TripManagementState>(
      'emits [TripHomeLoading, TripHomeLoaded] when LoadTripHome succeeds',
      build: () {
        when(
          () => mockTripRepo.getTripHome(any()),
        ).thenAnswer((_) async => Success(makeTripHome()));
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      act: (bloc) => bloc.add(LoadTripHome(tripId: 'trip-1')),
      expect: () => [isA<TripHomeLoading>(), isA<TripHomeLoaded>()],
    );

    // ── DeleteTrip ──────────────────────────────────────────────────────

    blocTest<TripManagementBloc, TripManagementState>(
      'emits [TripDeleting, TripDeleted, ...TripsTabLoaded] when DeleteTrip succeeds',
      build: () {
        when(
          () => mockTripRepo.deleteTrip(any()),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => mockTripRepo.getTripsPaginated(
            page: any(named: 'page'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async => const Success(
            PaginatedResponse<Trip>(
              items: [],
              total: 0,
              page: 1,
              totalPages: 0,
            ),
          ),
        );
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      act: (bloc) => bloc.add(DeleteTrip(tripId: 'trip-1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<TripDeleting>(),
        isA<TripDeleted>(),
        // 3 LoadTripsByStatus for ongoing/planned/completed → TripsLoading + TripsTabLoaded emissions
        isA<TripsLoading>(),
        isA<TripsTabLoaded>(),
        isA<TripsTabLoaded>(),
        isA<TripsTabLoaded>(),
      ],
      verify: (_) {
        verify(() => mockTripRepo.deleteTrip('trip-1')).called(1);
      },
    );

    blocTest<TripManagementBloc, TripManagementState>(
      'emits [TripDeleting, TripError] when DeleteTrip fails',
      build: () {
        when(
          () => mockTripRepo.deleteTrip(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      act: (bloc) => bloc.add(DeleteTrip(tripId: 'trip-1')),
      expect: () => [isA<TripDeleting>(), isA<TripError>()],
    );
  });
}
