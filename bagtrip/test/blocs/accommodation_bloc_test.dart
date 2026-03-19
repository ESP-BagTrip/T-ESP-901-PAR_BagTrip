import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockAccommodationRepository mockAccommodationRepo;

  setUp(() {
    mockAccommodationRepo = MockAccommodationRepository();
  });

  group('AccommodationBloc', () {
    // ── LoadAccommodations ──────────────────────────────────────────────

    blocTest<AccommodationBloc, AccommodationState>(
      'emits [AccommodationLoading, AccommodationsLoaded] when LoadAccommodations succeeds',
      build: () {
        when(
          () => mockAccommodationRepo.getByTrip(any()),
        ).thenAnswer((_) async => Success([makeAccommodation()]));
        return AccommodationBloc(repository: mockAccommodationRepo);
      },
      act: (bloc) => bloc.add(LoadAccommodations(tripId: 'trip-1')),
      expect: () => [isA<AccommodationLoading>(), isA<AccommodationsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as AccommodationsLoaded;
        expect(state.accommodations.length, 1);
      },
    );

    blocTest<AccommodationBloc, AccommodationState>(
      'emits [AccommodationLoading, AccommodationError] when LoadAccommodations fails',
      build: () {
        when(
          () => mockAccommodationRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return AccommodationBloc(repository: mockAccommodationRepo);
      },
      act: (bloc) => bloc.add(LoadAccommodations(tripId: 'trip-1')),
      expect: () => [isA<AccommodationLoading>(), isA<AccommodationError>()],
    );

    // ── CreateAccommodation ─────────────────────────────────────────────

    blocTest<AccommodationBloc, AccommodationState>(
      'CreateAccommodation appends item to local state without re-fetching',
      build: () {
        final newAcc = makeAccommodation(id: 'acc-new', name: 'Airbnb');
        when(
          () => mockAccommodationRepo.createAccommodation(
            any(),
            name: any(named: 'name'),
            address: any(named: 'address'),
            checkIn: any(named: 'checkIn'),
            checkOut: any(named: 'checkOut'),
            pricePerNight: any(named: 'pricePerNight'),
            currency: any(named: 'currency'),
            bookingReference: any(named: 'bookingReference'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async => Success(newAcc));
        return AccommodationBloc(repository: mockAccommodationRepo);
      },
      seed: () => AccommodationsLoaded(accommodations: [makeAccommodation()]),
      act: (bloc) => bloc.add(
        CreateAccommodation(tripId: 'trip-1', data: {'name': 'Airbnb'}),
      ),
      expect: () => [isA<AccommodationsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as AccommodationsLoaded;
        expect(state.accommodations.length, 2);
        expect(state.accommodations.last.id, 'acc-new');
        verifyNever(() => mockAccommodationRepo.getByTrip(any()));
      },
    );

    blocTest<AccommodationBloc, AccommodationState>(
      'CreateAccommodation falls back to LoadAccommodations when state is not AccommodationsLoaded',
      build: () {
        when(
          () => mockAccommodationRepo.createAccommodation(
            any(),
            name: any(named: 'name'),
            address: any(named: 'address'),
            checkIn: any(named: 'checkIn'),
            checkOut: any(named: 'checkOut'),
            pricePerNight: any(named: 'pricePerNight'),
            currency: any(named: 'currency'),
            bookingReference: any(named: 'bookingReference'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async => Success(makeAccommodation()));
        when(
          () => mockAccommodationRepo.getByTrip(any()),
        ).thenAnswer((_) async => Success([makeAccommodation()]));
        return AccommodationBloc(repository: mockAccommodationRepo);
      },
      act: (bloc) => bloc.add(
        CreateAccommodation(tripId: 'trip-1', data: {'name': 'Hotel'}),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<AccommodationLoading>(), isA<AccommodationsLoaded>()],
    );

    // ── UpdateAccommodation ─────────────────────────────────────────────

    blocTest<AccommodationBloc, AccommodationState>(
      'UpdateAccommodation replaces item in local state without re-fetching',
      build: () {
        final updated = makeAccommodation(name: 'Updated Hotel');
        when(
          () => mockAccommodationRepo.updateAccommodation(any(), any(), any()),
        ).thenAnswer((_) async => Success(updated));
        return AccommodationBloc(repository: mockAccommodationRepo);
      },
      seed: () => AccommodationsLoaded(accommodations: [makeAccommodation()]),
      act: (bloc) => bloc.add(
        UpdateAccommodation(
          tripId: 'trip-1',
          accommodationId: 'acc-1',
          data: {'name': 'Updated Hotel'},
        ),
      ),
      expect: () => [isA<AccommodationsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as AccommodationsLoaded;
        expect(state.accommodations.length, 1);
        expect(state.accommodations.first.name, 'Updated Hotel');
        verifyNever(() => mockAccommodationRepo.getByTrip(any()));
      },
    );

    // ── DeleteAccommodation ─────────────────────────────────────────────

    blocTest<AccommodationBloc, AccommodationState>(
      'DeleteAccommodation removes item from local state without re-fetching',
      build: () {
        when(
          () => mockAccommodationRepo.deleteAccommodation(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        return AccommodationBloc(repository: mockAccommodationRepo);
      },
      seed: () => AccommodationsLoaded(
        accommodations: [
          makeAccommodation(),
          makeAccommodation(id: 'acc-2', name: 'Airbnb'),
        ],
      ),
      act: (bloc) => bloc.add(
        DeleteAccommodation(tripId: 'trip-1', accommodationId: 'acc-1'),
      ),
      expect: () => [isA<AccommodationsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as AccommodationsLoaded;
        expect(state.accommodations.length, 1);
        expect(state.accommodations.first.id, 'acc-2');
        verifyNever(() => mockAccommodationRepo.getByTrip(any()));
      },
    );

    blocTest<AccommodationBloc, AccommodationState>(
      'DeleteAccommodation falls back to LoadAccommodations when state is not AccommodationsLoaded',
      build: () {
        when(
          () => mockAccommodationRepo.deleteAccommodation(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => mockAccommodationRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        return AccommodationBloc(repository: mockAccommodationRepo);
      },
      act: (bloc) => bloc.add(
        DeleteAccommodation(tripId: 'trip-1', accommodationId: 'acc-1'),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<AccommodationLoading>(), isA<AccommodationsLoaded>()],
    );

    // ── Error handling ──────────────────────────────────────────────────

    blocTest<AccommodationBloc, AccommodationState>(
      'emits AccommodationError when DeleteAccommodation fails',
      build: () {
        when(
          () => mockAccommodationRepo.deleteAccommodation(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return AccommodationBloc(repository: mockAccommodationRepo);
      },
      act: (bloc) => bloc.add(
        DeleteAccommodation(tripId: 'trip-1', accommodationId: 'acc-1'),
      ),
      expect: () => [isA<AccommodationError>()],
    );
  });
}
