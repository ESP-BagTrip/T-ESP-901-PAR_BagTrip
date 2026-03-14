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

  group('Trip creation flow', () {
    // ── CreateTrip -> TripCreated -> LoadTripHome -> TripHomeLoaded ────

    blocTest<TripManagementBloc, TripManagementState>(
      'create trip then load trip home',
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
        when(
          () => mockTripRepo.getTripHome(any()),
        ).thenAnswer((_) async => Success(makeTripHome()));
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      act: (bloc) async {
        bloc.add(CreateTrip(title: 'Paris'));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(LoadTripHome(tripId: 'trip-1'));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<TripCreating>(),
        isA<TripCreated>(),
        isA<TripHomeLoading>(),
        isA<TripHomeLoaded>(),
      ],
      verify: (_) {
        verify(() => mockTripRepo.createTrip(title: 'Paris')).called(1);
        verify(() => mockTripRepo.getTripHome('trip-1')).called(1);
      },
    );

    // ── CreateTrip with full params -> TripCreated ────────────────────

    blocTest<TripManagementBloc, TripManagementState>(
      'create trip with all optional parameters',
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
          title: 'Tokyo Adventure',
          description: 'A wonderful trip to Japan',
          destinationName: 'Tokyo',
          nbTravelers: 4,
          startDate: DateTime(2024, 9),
          endDate: DateTime(2024, 9, 14),
        ),
      ),
      expect: () => [isA<TripCreating>(), isA<TripCreated>()],
    );

    // ── CreateTrip failure ────────────────────────────────────────────

    blocTest<TripManagementBloc, TripManagementState>(
      'create trip emits TripError on failure',
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
        ).thenAnswer((_) async => const Failure(ServerError('Internal error')));
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      act: (bloc) => bloc.add(CreateTrip(title: 'Failing Trip')),
      expect: () => [isA<TripCreating>(), isA<TripError>()],
    );
  });

  group('Trip deletion flow', () {
    // ── DeleteTrip -> TripDeleted -> auto LoadTrips -> TripsLoaded ─────

    blocTest<TripManagementBloc, TripManagementState>(
      'delete trip then auto-loads grouped trips',
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

    // ── DeleteTrip failure ────────────────────────────────────────────

    blocTest<TripManagementBloc, TripManagementState>(
      'delete trip emits TripError on failure',
      build: () {
        when(
          () => mockTripRepo.deleteTrip(any()),
        ).thenAnswer((_) async => const Failure(NotFoundError('Not found')));
        return TripManagementBloc(tripRepository: mockTripRepo);
      },
      act: (bloc) => bloc.add(DeleteTrip(tripId: 'nonexistent')),
      expect: () => [isA<TripDeleting>(), isA<TripError>()],
    );

    // ── Delete then auto-reload returns empty lists ───────────────────

    blocTest<TripManagementBloc, TripManagementState>(
      'delete last trip results in empty grouped trips after auto-reload',
      build: () {
        when(
          () => mockTripRepo.deleteTrip(any()),
        ).thenAnswer((_) async => const Success(null));
        when(() => mockTripRepo.getGroupedTrips()).thenAnswer(
          (_) async =>
              Success(makeTripGrouped(ongoing: [], planned: [], completed: [])),
        );
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
      verify: (bloc) {
        final state = bloc.state as TripsLoaded;
        expect(state.groupedTrips.ongoing, isEmpty);
        expect(state.groupedTrips.planned, isEmpty);
        expect(state.groupedTrips.completed, isEmpty);
      },
    );
  });
}
