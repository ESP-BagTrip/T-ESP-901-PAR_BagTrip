import 'package:bagtrip/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Trip JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'id': 'trip-abc-123',
        'user_id': 'user-xyz-789',
        'title': 'Summer in Tokyo',
        'origin_iata': 'CDG',
        'destination_iata': 'NRT',
        'start_date': '2024-07-15T00:00:00.000',
        'end_date': '2024-07-30T00:00:00.000',
        'status': 'planned',
        'description': 'Two weeks exploring Japanese culture and cuisine',
        'destination_name': 'Tokyo',
        'nb_travelers': 3,
        'cover_image_url': 'https://cdn.example.com/trips/tokyo-cover.jpg',
        'budget_target': 4500.75,
        'budget_estimated': 4200.0,
        'budget_actual': 3900.0,
        'origin': 'Paris',
        'role': 'OWNER',
        'created_at': '2024-03-10T08:30:00.000',
        'updated_at': '2024-04-15T14:20:00.000',
      };

      final first = Trip.fromJson(json);
      final serialized = first.toJson();
      final second = Trip.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'trip-abc-123');
      expect(second.userId, 'user-xyz-789');
      expect(second.title, 'Summer in Tokyo');
      expect(second.originIata, 'CDG');
      expect(second.destinationIata, 'NRT');
      expect(second.startDate, DateTime.parse('2024-07-15T00:00:00.000'));
      expect(second.endDate, DateTime.parse('2024-07-30T00:00:00.000'));
      expect(second.status, TripStatus.planned);
      expect(
        second.description,
        'Two weeks exploring Japanese culture and cuisine',
      );
      expect(second.destinationName, 'Tokyo');
      expect(second.nbTravelers, 3);
      expect(
        second.coverImageUrl,
        'https://cdn.example.com/trips/tokyo-cover.jpg',
      );
      expect(second.budgetTarget, 4500.75);
      expect(second.budgetEstimated, 4200.0);
      expect(second.budgetActual, 3900.0);
      expect(second.origin, 'Paris');
      expect(second.role, 'OWNER');
      expect(second.createdAt, DateTime.parse('2024-03-10T08:30:00.000'));
      expect(second.updatedAt, DateTime.parse('2024-04-15T14:20:00.000'));
    });

    test('roundtrip with minimal fields preserves defaults', () {
      final json = <String, dynamic>{'id': 'trip-minimal'};

      final first = Trip.fromJson(json);
      final serialized = first.toJson();
      final second = Trip.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'trip-minimal');
      expect(second.status, TripStatus.draft);
      expect(second.title, isNull);
      expect(second.startDate, isNull);
      expect(second.endDate, isNull);
      expect(second.budgetTarget, isNull);
      expect(second.budgetEstimated, isNull);
      expect(second.budgetActual, isNull);
      expect(second.nbTravelers, isNull);
    });

    test('roundtrip preserves each TripStatus value', () {
      for (final status in TripStatus.values) {
        final trip = Trip(id: 'trip-status-$status', status: status);
        final json = trip.toJson();
        final restored = Trip.fromJson(json);
        expect(
          restored.status,
          status,
          reason: 'Status $status should survive roundtrip',
        );
      }
    });

    test('roundtrip with all nullable fields set to null', () {
      final json = <String, dynamic>{
        'id': 'trip-nulls',
        'user_id': null,
        'title': null,
        'origin_iata': null,
        'destination_iata': null,
        'start_date': null,
        'end_date': null,
        'description': null,
        'destinationName': null,
        'nb_travelers': null,
        'cover_image_url': null,
        'budget_total': null,
        'origin': null,
        'role': null,
        'created_at': null,
        'updated_at': null,
      };

      final first = Trip.fromJson(json);
      final serialized = first.toJson();
      final second = Trip.fromJson(serialized);

      expect(second, first);
    });
  });
}
