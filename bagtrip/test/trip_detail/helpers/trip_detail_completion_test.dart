// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/models/validation_status.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  group('tripDetailCompletion (validation-aware, 4 segments)', () {
    test('empty trip scores 0', () {
      final result = tripDetailCompletion(
        trip: makeTrip(),
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [],
      );
      expect(result.percentage, 0);
      for (final seg in CompletionSegmentType.values) {
        expect(result.segment(seg).percentage, 0);
        expect(result.segment(seg).isComplete, isFalse);
      }
    });

    test('freshly-accepted plan (all SUGGESTED) still scores 0', () {
      final result = tripDetailCompletion(
        trip: makeTrip(),
        flights: [
          makeManualFlight(
            id: 'f1',
            validationStatus: ValidationStatus.suggested,
          ),
          makeManualFlight(
            id: 'f2',
            validationStatus: ValidationStatus.suggested,
          ),
        ],
        accommodations: [
          makeAccommodation(validationStatus: ValidationStatus.suggested),
        ],
        activities: [
          makeActivity(id: 'a1', validationStatus: ValidationStatus.suggested),
          makeActivity(id: 'a2', validationStatus: ValidationStatus.suggested),
          makeActivity(id: 'a3', validationStatus: ValidationStatus.suggested),
        ],
        baggageItems: [
          makeBaggageItem(id: 'b1'),
          makeBaggageItem(id: 'b2'),
        ],
      );
      expect(result.percentage, 0);
    });

    test('one validated flight lifts the flights segment to 50%', () {
      final result = tripDetailCompletion(
        trip: makeTrip(),
        flights: [
          makeManualFlight(
            id: 'f1',
            validationStatus: ValidationStatus.validated,
          ),
          makeManualFlight(
            id: 'f2',
            validationStatus: ValidationStatus.suggested,
          ),
        ],
        accommodations: [],
        activities: [],
        baggageItems: [],
      );
      expect(result.segment(CompletionSegmentType.flights).percentage, 50);
      // 50 + 0 + 0 + 0 = 50 / 4 = 12.5 → 13
      expect(result.percentage, 13);
    });

    test('skipped flights contribute a full segment', () {
      final result = tripDetailCompletion(
        trip: makeTrip(flightsTracking: 'SKIPPED'),
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [],
      );
      expect(result.segment(CompletionSegmentType.flights).isSkipped, isTrue);
      expect(result.segment(CompletionSegmentType.flights).percentage, 100);
      // 100 + 0 + 0 + 0 = 100 / 4 = 25
      expect(result.percentage, 25);
    });

    test('skipping both flight-style segments yields 50% alone', () {
      final result = tripDetailCompletion(
        trip: makeTrip(
          flightsTracking: 'SKIPPED',
          accommodationsTracking: 'SKIPPED',
        ),
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [],
      );
      expect(result.percentage, 50);
    });

    test('activities count only when validated', () {
      final result = tripDetailCompletion(
        trip: makeTrip(),
        flights: [],
        accommodations: [],
        activities: [
          makeActivity(id: 'a1', validationStatus: ValidationStatus.validated),
          makeActivity(id: 'a2', validationStatus: ValidationStatus.suggested),
        ],
        baggageItems: [],
      );
      expect(result.segment(CompletionSegmentType.activities).percentage, 50);
    });

    test('baggage counts when packed', () {
      final result = tripDetailCompletion(
        trip: makeTrip(),
        flights: [],
        accommodations: [],
        activities: [],
        baggageItems: [
          makeBaggageItem(id: 'b1', isPacked: true),
          makeBaggageItem(id: 'b2', isPacked: true),
          makeBaggageItem(id: 'b3', isPacked: false),
          makeBaggageItem(id: 'b4', isPacked: false),
        ],
      );
      expect(result.segment(CompletionSegmentType.baggage).percentage, 50);
    });

    test('everything validated scores 100', () {
      final result = tripDetailCompletion(
        trip: makeTrip(),
        flights: [
          makeManualFlight(
            id: 'f1',
            validationStatus: ValidationStatus.validated,
          ),
        ],
        accommodations: [
          makeAccommodation(validationStatus: ValidationStatus.validated),
        ],
        activities: [
          makeActivity(id: 'a1', validationStatus: ValidationStatus.validated),
        ],
        baggageItems: [makeBaggageItem(id: 'b1', isPacked: true)],
      );
      expect(result.percentage, 100);
    });

    test('CompletionSegment.isComplete reflects skip OR total==done', () {
      const empty = CompletionSegment(done: 0, total: 0, isSkipped: false);
      expect(empty.isComplete, isFalse);

      const skipped = CompletionSegment(done: 0, total: 0, isSkipped: true);
      expect(skipped.isComplete, isTrue);
      expect(skipped.percentage, 100);

      const partial = CompletionSegment(done: 1, total: 2, isSkipped: false);
      expect(partial.isComplete, isFalse);
      expect(partial.percentage, 50);

      const done = CompletionSegment(done: 3, total: 3, isSkipped: false);
      expect(done.isComplete, isTrue);
      expect(done.percentage, 100);
    });
  });
}
