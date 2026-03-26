import 'package:bagtrip/home/helpers/trip_end_detector.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/service/post_trip_dismissal_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class MockPostTripDismissalStorage extends Mock
    implements PostTripDismissalStorage {}

void main() {
  late MockPostTripDismissalStorage mockStorage;

  setUp(() {
    mockStorage = MockPostTripDismissalStorage();
  });

  group('detectEndedTrips', () {
    test('empty list returns empty result', () async {
      final result = await detectEndedTrips(
        ongoingTrips: [],
        dismissalStorage: mockStorage,
      );
      expect(result.endedTrips, isEmpty);
      expect(result.dismissedTrips, isEmpty);
    });

    test('trip with endDate in the future is not detected', () async {
      final trip = makeTrip(
        status: TripStatus.ongoing,
        endDate: DateTime.now().add(const Duration(days: 3)),
      );
      final result = await detectEndedTrips(
        ongoingTrips: [trip],
        dismissalStorage: mockStorage,
      );
      expect(result.endedTrips, isEmpty);
    });

    test('trip with endDate == yesterday is detected', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final trip = makeTrip(
        status: TripStatus.ongoing,
        startDate: yesterday.subtract(const Duration(days: 5)),
        endDate: yesterday,
      );
      when(
        () => mockStorage.wasDismissedRecently(trip.id),
      ).thenAnswer((_) async => false);

      final result = await detectEndedTrips(
        ongoingTrips: [trip],
        dismissalStorage: mockStorage,
      );
      expect(result.endedTrips.length, 1);
      expect(result.endedTrips.first.id, trip.id);
    });

    test('recently dismissed trip is skipped', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final trip = makeTrip(
        status: TripStatus.ongoing,
        startDate: yesterday.subtract(const Duration(days: 5)),
        endDate: yesterday,
      );
      when(
        () => mockStorage.wasDismissedRecently(trip.id),
      ).thenAnswer((_) async => true);

      final result = await detectEndedTrips(
        ongoingTrips: [trip],
        dismissalStorage: mockStorage,
      );
      expect(result.endedTrips, isEmpty);
      expect(result.dismissedTrips.length, 1);
    });

    test('trip dismissed >24h ago is detected again', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final trip = makeTrip(
        status: TripStatus.ongoing,
        startDate: yesterday.subtract(const Duration(days: 5)),
        endDate: yesterday,
      );
      when(
        () => mockStorage.wasDismissedRecently(trip.id),
      ).thenAnswer((_) async => false);

      final result = await detectEndedTrips(
        ongoingTrips: [trip],
        dismissalStorage: mockStorage,
      );
      expect(result.endedTrips.length, 1);
    });

    test('trip without endDate is not detected', () async {
      final trip = makeTrip(status: TripStatus.ongoing).copyWith(endDate: null);
      final result = await detectEndedTrips(
        ongoingTrips: [trip],
        dismissalStorage: mockStorage,
      );
      expect(result.endedTrips, isEmpty);
    });
  });
}
