import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  group('tripDetailCompletion', () {
    test('returns 0 when nothing is set', () {
      const trip = Trip(id: 'empty');
      final result = tripDetailCompletion(
        trip: trip,
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [],
      );
      expect(result.percentage, 0);
      expect(result.segments[CompletionSegmentType.dates], false);
      expect(result.segments[CompletionSegmentType.flights], false);
      expect(result.segments[CompletionSegmentType.accommodation], false);
      expect(result.segments[CompletionSegmentType.activities], false);
      expect(result.segments[CompletionSegmentType.baggage], false);
      expect(result.segments[CompletionSegmentType.budget], false);
    });

    test('returns 17 when only dates are set', () {
      final trip = makeTrip(); // has startDate + endDate by default
      final result = tripDetailCompletion(
        trip: trip,
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [],
      );
      expect(result.percentage, 17);
      expect(result.segments[CompletionSegmentType.dates], true);
    });

    test('returns 33 when dates + 1 flight', () {
      final trip = makeTrip();
      final result = tripDetailCompletion(
        trip: trip,
        flights: [makeManualFlight()],
        accommodations: [],
        activities: [],
        baggageItems: [],
      );
      expect(result.percentage, 33);
      expect(result.segments[CompletionSegmentType.flights], true);
    });

    test('returns 50 when dates + flight + accommodation', () {
      final trip = makeTrip();
      final result = tripDetailCompletion(
        trip: trip,
        flights: [makeManualFlight()],
        accommodations: [makeAccommodation()],
        activities: [],
        baggageItems: [],
      );
      expect(result.percentage, 50);
      expect(result.segments[CompletionSegmentType.accommodation], true);
    });

    test('returns 67 when dates + flight + accommodation + 3 activities', () {
      final trip = makeTrip();
      final result = tripDetailCompletion(
        trip: trip,
        flights: [makeManualFlight()],
        accommodations: [makeAccommodation()],
        activities: [
          makeActivity(id: 'a1'),
          makeActivity(id: 'a2'),
          makeActivity(id: 'a3'),
        ],
        baggageItems: [],
      );
      expect(result.percentage, 67);
      expect(result.segments[CompletionSegmentType.activities], true);
    });

    test('returns 83 when all except budget', () {
      final trip = makeTrip();
      final result = tripDetailCompletion(
        trip: trip,
        flights: [makeManualFlight()],
        accommodations: [makeAccommodation()],
        activities: [
          makeActivity(id: 'a1'),
          makeActivity(id: 'a2'),
          makeActivity(id: 'a3'),
        ],
        baggageItems: [
          makeBaggageItem(id: 'b1'),
          makeBaggageItem(id: 'b2'),
          makeBaggageItem(id: 'b3'),
          makeBaggageItem(id: 'b4'),
          makeBaggageItem(id: 'b5'),
        ],
      );
      expect(result.percentage, 83);
      expect(result.segments[CompletionSegmentType.baggage], true);
      expect(result.segments[CompletionSegmentType.budget], false);
    });

    test('returns 100 when all criteria met including budget', () {
      final trip = makeTrip();
      final result = tripDetailCompletion(
        trip: trip,
        flights: [makeManualFlight()],
        accommodations: [makeAccommodation()],
        activities: [
          makeActivity(id: 'a1'),
          makeActivity(id: 'a2'),
          makeActivity(id: 'a3'),
        ],
        baggageItems: [
          makeBaggageItem(id: 'b1'),
          makeBaggageItem(id: 'b2'),
          makeBaggageItem(id: 'b3'),
          makeBaggageItem(id: 'b4'),
          makeBaggageItem(id: 'b5'),
        ],
        budgetSummary: makeBudgetSummary(),
      );
      expect(result.percentage, 100);
      expect(result.segments[CompletionSegmentType.budget], true);
    });

    test('budget segment is not filled when budgetSummary is null', () {
      final trip = makeTrip();
      final result = tripDetailCompletion(
        trip: trip,
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [],
        // budgetSummary defaults to null
      );
      expect(result.segments[CompletionSegmentType.budget], false);
    });

    test('budget segment is filled when budgetSummary is non-null', () {
      const trip = Trip(id: 'empty');
      final result = tripDetailCompletion(
        trip: trip,
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [],
        budgetSummary: makeBudgetSummary(),
      );
      expect(result.percentage, 17);
      expect(result.segments[CompletionSegmentType.budget], true);
    });

    test('2 activities does not count', () {
      const trip = Trip(id: 'empty');
      final result = tripDetailCompletion(
        trip: trip,
        flights: [],
        accommodations: [],
        activities: [
          makeActivity(id: 'a1'),
          makeActivity(id: 'a2'),
        ],
        baggageItems: [],
      );
      expect(result.percentage, 0);
      expect(result.segments[CompletionSegmentType.activities], false);
    });

    test('4 baggage items does not count', () {
      const trip = Trip(id: 'empty');
      final result = tripDetailCompletion(
        trip: trip,
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [
          makeBaggageItem(id: 'b1'),
          makeBaggageItem(id: 'b2'),
          makeBaggageItem(id: 'b3'),
          makeBaggageItem(id: 'b4'),
        ],
      );
      expect(result.percentage, 0);
      expect(result.segments[CompletionSegmentType.baggage], false);
    });

    test('startDate only (no endDate) does not count', () {
      final trip = Trip(id: 't', startDate: DateTime(2024, 6));
      final result = tripDetailCompletion(
        trip: trip,
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [],
      );
      expect(result.percentage, 0);
      expect(result.segments[CompletionSegmentType.dates], false);
    });

    test('endDate only (no startDate) does not count', () {
      final trip = Trip(id: 't', endDate: DateTime(2024, 6, 7));
      final result = tripDetailCompletion(
        trip: trip,
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [],
      );
      expect(result.percentage, 0);
      expect(result.segments[CompletionSegmentType.dates], false);
    });

    test('segments map always has all 6 keys', () {
      const trip = Trip(id: 'empty');
      final result = tripDetailCompletion(
        trip: trip,
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [],
      );
      expect(result.segments.length, 6);
      for (final type in CompletionSegmentType.values) {
        expect(result.segments.containsKey(type), true);
      }
    });
  });
}
