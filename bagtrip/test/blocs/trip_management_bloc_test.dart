import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
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
      'emits [TripDeleting, TripDeleted, TripsLoading, TripsLoaded] when DeleteTrip succeeds',
      build: () {
        when(
          () => mockTripRepo.deleteTrip(any()),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => mockTripRepo.getGroupedTrips(),
        ).thenAnswer((_) async => Success(makeTripGrouped()));
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      act: (bloc) => bloc.add(DeleteTrip(tripId: 'trip-1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<TripDeleting>(),
        isA<TripDeleted>(),
        isA<TripsLoading>(),
        isA<TripsLoaded>(),
      ],
      verify: (_) {
        verify(() => mockTripRepo.deleteTrip('trip-1')).called(1);
        verify(() => mockTripRepo.getGroupedTrips()).called(1);
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
