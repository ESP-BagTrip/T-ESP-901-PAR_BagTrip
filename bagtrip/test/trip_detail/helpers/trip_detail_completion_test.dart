import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  group('tripDetailCompletion', () {
    test('returns 0 when nothing is set', () {
      const trip = Trip(id: 'empty');
      expect(
        tripDetailCompletion(
          trip: trip,
          flights: [],
          accommodations: [],
          activities: [],
          baggageItems: [],
        ),
        0,
      );
    });

    test('returns 20 when only dates are set', () {
      final trip = makeTrip(); // has startDate + endDate by default
      expect(
        tripDetailCompletion(
          trip: trip,
          flights: [],
          accommodations: [],
          activities: [],
          baggageItems: [],
        ),
        20,
      );
    });

    test('returns 40 when dates + 1 flight', () {
      final trip = makeTrip();
      expect(
        tripDetailCompletion(
          trip: trip,
          flights: [makeManualFlight()],
          accommodations: [],
          activities: [],
          baggageItems: [],
        ),
        40,
      );
    });

    test('returns 60 when dates + flight + accommodation', () {
      final trip = makeTrip();
      expect(
        tripDetailCompletion(
          trip: trip,
          flights: [makeManualFlight()],
          accommodations: [makeAccommodation()],
          activities: [],
          baggageItems: [],
        ),
        60,
      );
    });

    test('returns 80 when dates + flight + accommodation + 3 activities', () {
      final trip = makeTrip();
      expect(
        tripDetailCompletion(
          trip: trip,
          flights: [makeManualFlight()],
          accommodations: [makeAccommodation()],
          activities: [
            makeActivity(id: 'a1'),
            makeActivity(id: 'a2'),
            makeActivity(id: 'a3'),
          ],
          baggageItems: [],
        ),
        80,
      );
    });

    test('returns 100 when all criteria met', () {
      final trip = makeTrip();
      expect(
        tripDetailCompletion(
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
        ),
        100,
      );
    });

    test('2 activities does not count as 20%', () {
      const trip = Trip(id: 'empty'); // no dates
      expect(
        tripDetailCompletion(
          trip: trip,
          flights: [],
          accommodations: [],
          activities: [
            makeActivity(id: 'a1'),
            makeActivity(id: 'a2'),
          ],
          baggageItems: [],
        ),
        0,
      );
    });

    test('4 baggage items does not count as 20%', () {
      const trip = Trip(id: 'empty'); // no dates
      expect(
        tripDetailCompletion(
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
        ),
        0,
      );
    });

    test('startDate only (no endDate) does not count', () {
      final trip = Trip(id: 't', startDate: DateTime(2024, 6));
      expect(
        tripDetailCompletion(
          trip: trip,
          flights: [],
          accommodations: [],
          activities: [],
          baggageItems: [],
        ),
        0,
      );
    });

    test('endDate only (no startDate) does not count', () {
      final trip = Trip(id: 't', endDate: DateTime(2024, 6, 7));
      expect(
        tripDetailCompletion(
          trip: trip,
          flights: [],
          accommodations: [],
          activities: [],
          baggageItems: [],
        ),
        0,
      );
    });
  });
}
