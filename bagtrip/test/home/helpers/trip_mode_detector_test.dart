import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/helpers/trip_mode_detector.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  late MockTripRepository mockTripRepo;

  setUp(() {
    mockTripRepo = MockTripRepository();
  });

  final today = DateTime(2024, 6, 15);

  group('detectAndTransitionTrips', () {
    test('empty list returns empty result', () async {
      final result = await detectAndTransitionTrips(
        plannedTrips: [],
        tripRepository: mockTripRepo,
        isOnline: true,
        now: today,
      );

      expect(result.transitionedTrips, isEmpty);
      expect(result.failedTrips, isEmpty);
      expect(result.hasTransitions, isFalse);
    });

    test('future trip (startDate = tomorrow) is not detected', () async {
      final trip = makeTrip(
        id: 'future',
        status: TripStatus.planned,
        startDate: DateTime(2024, 6, 16),
        endDate: DateTime(2024, 6, 20),
      );

      final result = await detectAndTransitionTrips(
        plannedTrips: [trip],
        tripRepository: mockTripRepo,
        isOnline: true,
        now: today,
      );

      expect(result.transitionedTrips, isEmpty);
      expect(result.failedTrips, isEmpty);
      verifyNever(() => mockTripRepo.updateTripStatus(any(), any()));
    });

    test('trip with startDate == today is detected and API called', () async {
      final trip = makeTrip(
        id: 'today-trip',
        status: TripStatus.planned,
        startDate: DateTime(2024, 6, 15),
        endDate: DateTime(2024, 6, 20),
      );

      when(
        () => mockTripRepo.updateTripStatus('today-trip', 'ongoing'),
      ).thenAnswer(
        (_) async => Success(trip.copyWith(status: TripStatus.ongoing)),
      );

      final result = await detectAndTransitionTrips(
        plannedTrips: [trip],
        tripRepository: mockTripRepo,
        isOnline: true,
        now: today,
      );

      expect(result.transitionedTrips, hasLength(1));
      expect(result.failedTrips, isEmpty);
      verify(
        () => mockTripRepo.updateTripStatus('today-trip', 'ongoing'),
      ).called(1);
    });

    test('trip with startDate past and endDate future is detected', () async {
      final trip = makeTrip(
        id: 'mid-trip',
        status: TripStatus.planned,
        startDate: DateTime(2024, 6, 10),
        endDate: DateTime(2024, 6, 20),
      );

      when(
        () => mockTripRepo.updateTripStatus('mid-trip', 'ongoing'),
      ).thenAnswer(
        (_) async => Success(trip.copyWith(status: TripStatus.ongoing)),
      );

      final result = await detectAndTransitionTrips(
        plannedTrips: [trip],
        tripRepository: mockTripRepo,
        isOnline: true,
        now: today,
      );

      expect(result.transitionedTrips, hasLength(1));
    });

    test('trip with endDate past is NOT detected', () async {
      final trip = makeTrip(
        id: 'past-trip',
        status: TripStatus.planned,
        startDate: DateTime(2024, 6, 2),
        endDate: DateTime(2024, 6, 10),
      );

      final result = await detectAndTransitionTrips(
        plannedTrips: [trip],
        tripRepository: mockTripRepo,
        isOnline: true,
        now: today,
      );

      expect(result.transitionedTrips, isEmpty);
      expect(result.failedTrips, isEmpty);
      verifyNever(() => mockTripRepo.updateTripStatus(any(), any()));
    });

    test('trip with startDate null is skipped', () async {
      const trip = Trip(id: 'no-start', status: TripStatus.planned);

      final result = await detectAndTransitionTrips(
        plannedTrips: [trip],
        tripRepository: mockTripRepo,
        isOnline: true,
        now: today,
      );

      expect(result.transitionedTrips, isEmpty);
      verifyNever(() => mockTripRepo.updateTripStatus(any(), any()));
    });

    test('trip with endDate null and startDate <= today is detected', () async {
      final trip = Trip(
        id: 'no-end',
        status: TripStatus.planned,
        startDate: DateTime(2024, 6, 15),
      );

      when(() => mockTripRepo.updateTripStatus('no-end', 'ongoing')).thenAnswer(
        (_) async => Success(trip.copyWith(status: TripStatus.ongoing)),
      );

      final result = await detectAndTransitionTrips(
        plannedTrips: [trip],
        tripRepository: mockTripRepo,
        isOnline: true,
        now: today,
      );

      expect(result.transitionedTrips, hasLength(1));
    });

    test('offline returns candidates without API call', () async {
      final trip = makeTrip(
        id: 'offline-trip',
        status: TripStatus.planned,
        startDate: DateTime(2024, 6, 15),
        endDate: DateTime(2024, 6, 20),
      );

      final result = await detectAndTransitionTrips(
        plannedTrips: [trip],
        tripRepository: mockTripRepo,
        isOnline: false,
        now: today,
      );

      expect(result.transitionedTrips, hasLength(1));
      expect(result.failedTrips, isEmpty);
      verifyNever(() => mockTripRepo.updateTripStatus(any(), any()));
    });

    test('API failure puts trip in failedTrips', () async {
      final trip = makeTrip(
        id: 'fail-trip',
        status: TripStatus.planned,
        startDate: DateTime(2024, 6, 15),
        endDate: DateTime(2024, 6, 20),
      );

      when(
        () => mockTripRepo.updateTripStatus('fail-trip', 'ongoing'),
      ).thenAnswer(
        (_) async => const Failure(ServerError('Internal server error')),
      );

      final result = await detectAndTransitionTrips(
        plannedTrips: [trip],
        tripRepository: mockTripRepo,
        isOnline: true,
        now: today,
      );

      expect(result.transitionedTrips, isEmpty);
      expect(result.failedTrips, hasLength(1));
    });

    test('mix of success and failure across 3 trips', () async {
      final trip1 = makeTrip(
        id: 'trip-ok-1',
        status: TripStatus.planned,
        startDate: DateTime(2024, 6, 15),
        endDate: DateTime(2024, 6, 20),
      );
      final trip2 = makeTrip(
        id: 'trip-fail',
        status: TripStatus.planned,
        startDate: DateTime(2024, 6, 10),
        endDate: DateTime(2024, 6, 18),
      );
      final trip3 = makeTrip(
        id: 'trip-ok-2',
        status: TripStatus.planned,
        startDate: DateTime(2024, 6, 14),
        endDate: DateTime(2024, 6, 16),
      );

      when(
        () => mockTripRepo.updateTripStatus('trip-ok-1', 'ongoing'),
      ).thenAnswer(
        (_) async => Success(trip1.copyWith(status: TripStatus.ongoing)),
      );
      when(
        () => mockTripRepo.updateTripStatus('trip-fail', 'ongoing'),
      ).thenAnswer(
        (_) async => const Failure(ServerError('Internal server error')),
      );
      when(
        () => mockTripRepo.updateTripStatus('trip-ok-2', 'ongoing'),
      ).thenAnswer(
        (_) async => Success(trip3.copyWith(status: TripStatus.ongoing)),
      );

      final result = await detectAndTransitionTrips(
        plannedTrips: [trip1, trip2, trip3],
        tripRepository: mockTripRepo,
        isOnline: true,
        now: today,
      );

      expect(result.transitionedTrips, hasLength(2));
      expect(result.failedTrips, hasLength(1));
      expect(result.failedTrips.first.id, 'trip-fail');
    });

    test('now parameter is injectable for deterministic tests', () async {
      final trip = makeTrip(
        id: 'injectable',
        status: TripStatus.planned,
        startDate: DateTime(2025, 1, 2),
        endDate: DateTime(2025, 1, 10),
      );

      when(
        () => mockTripRepo.updateTripStatus('injectable', 'ongoing'),
      ).thenAnswer(
        (_) async => Success(trip.copyWith(status: TripStatus.ongoing)),
      );

      // With now = Jan 5, 2025 → detected
      final result1 = await detectAndTransitionTrips(
        plannedTrips: [trip],
        tripRepository: mockTripRepo,
        isOnline: true,
        now: DateTime(2025, 1, 5),
      );
      expect(result1.hasTransitions, isTrue);

      // With now = Dec 31, 2024 → not detected
      final result2 = await detectAndTransitionTrips(
        plannedTrips: [trip],
        tripRepository: mockTripRepo,
        isOnline: true,
        now: DateTime(2024, 12, 31),
      );
      expect(result2.hasTransitions, isFalse);
    });
  });
}
