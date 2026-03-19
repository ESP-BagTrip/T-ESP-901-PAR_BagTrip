import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Route locations', () {
    test('PlanTripRoute generates /home/plan', () {
      expect(const PlanTripRoute().location, '/home/plan');
    });

    test('TripDetailRoute generates /home/trip/:tripId', () {
      expect(const TripDetailRoute(tripId: 'abc').location, '/home/trip/abc');
    });

    test('DeepLinkTripRoute generates /trip/:tripId', () {
      expect(const DeepLinkTripRoute(tripId: 'xyz').location, '/trip/xyz');
    });

    test('existing TripCreationRoute unchanged', () {
      expect(const TripCreationRoute().location, '/home/create');
    });

    test('existing TripHomeRoute unchanged', () {
      expect(const TripHomeRoute(tripId: 'x').location, '/home/x');
    });
  });
}
