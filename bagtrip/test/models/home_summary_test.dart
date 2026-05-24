import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/home_summary.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeSummary.fromJson', () {
    test('parses the aggregated /home payload (camelCase top-level keys)', () {
      final json = <String, dynamic>{
        'ongoingTrips': [
          {'id': 't1', 'status': 'ongoing', 'completion_percentage': 60},
        ],
        'plannedTrips': [
          {'id': 't2', 'status': 'planned'},
        ],
        'completedTrips': [
          {'id': 't3', 'status': 'completed'},
        ],
        'user': {'id': 'u1', 'email': 'a@b.com', 'plan': 'PREMIUM'},
        'activeTripActivities': [
          {
            'id': 'a1',
            'trip_id': 't1',
            'title': 'City tour',
            'category': 'CULTURE',
          },
        ],
        'activeTripWeather': {'avg_temp_c': 20.0, 'description': 'Clear'},
      };

      final summary = HomeSummary.fromJson(json);

      expect(summary.ongoingTrips.single.id, 't1');
      expect(summary.ongoingTrips.single.status, TripStatus.ongoing);
      expect(summary.ongoingTrips.single.completionPercentage, 60);
      expect(summary.plannedTrips.single.id, 't2');
      expect(summary.completedTrips.single.id, 't3');
      expect(summary.user.email, 'a@b.com');
      expect(summary.user.plan, 'PREMIUM');
      expect(summary.activeTripActivities.single.title, 'City tour');
      expect(
        summary.activeTripActivities.single.category,
        ActivityCategory.culture,
      );
      expect(summary.activeTripWeather?.avgTempC, 20.0);
      expect(summary.activeTripWeather?.description, 'Clear');
    });

    test('defaults lists to empty and weather to null when omitted', () {
      final json = <String, dynamic>{
        'user': {'id': 'u1', 'email': 'a@b.com'},
      };

      final summary = HomeSummary.fromJson(json);

      expect(summary.ongoingTrips, isEmpty);
      expect(summary.plannedTrips, isEmpty);
      expect(summary.completedTrips, isEmpty);
      expect(summary.activeTripActivities, isEmpty);
      expect(summary.activeTripWeather, isNull);
    });

    test('toJson round-trips back to an equal HomeSummary', () {
      final json = <String, dynamic>{
        'ongoingTrips': [
          {'id': 't1', 'status': 'ongoing'},
        ],
        'plannedTrips': <dynamic>[],
        'completedTrips': <dynamic>[],
        'user': {'id': 'u1', 'email': 'a@b.com'},
        'activeTripActivities': <dynamic>[],
        'activeTripWeather': null,
      };

      final summary = HomeSummary.fromJson(json);
      final restored = HomeSummary.fromJson(summary.toJson());

      expect(restored, summary);
    });
  });
}
