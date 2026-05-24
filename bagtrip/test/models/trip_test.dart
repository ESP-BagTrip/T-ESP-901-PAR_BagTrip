import 'package:bagtrip/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TripStatus', () {
    group('fromString', () {
      test('returns draft for "draft"', () {
        expect(TripStatus.fromString('draft'), TripStatus.draft);
      });

      test('returns planned for "planned"', () {
        expect(TripStatus.fromString('planned'), TripStatus.planned);
      });

      test('returns planned for "planning"', () {
        expect(TripStatus.fromString('planning'), TripStatus.planned);
      });

      test('returns ongoing for "active"', () {
        expect(TripStatus.fromString('active'), TripStatus.ongoing);
      });

      test('returns ongoing for "ongoing"', () {
        expect(TripStatus.fromString('ongoing'), TripStatus.ongoing);
      });

      test('returns completed for "completed"', () {
        expect(TripStatus.fromString('completed'), TripStatus.completed);
      });

      test('returns completed for "archived"', () {
        expect(TripStatus.fromString('archived'), TripStatus.completed);
      });

      test('returns draft for unknown value', () {
        expect(TripStatus.fromString('unknown'), TripStatus.draft);
        expect(TripStatus.fromString(''), TripStatus.draft);
        expect(TripStatus.fromString('random'), TripStatus.draft);
      });

      test('is case-insensitive', () {
        expect(TripStatus.fromString('DRAFT'), TripStatus.draft);
        expect(TripStatus.fromString('Planned'), TripStatus.planned);
        expect(TripStatus.fromString('ONGOING'), TripStatus.ongoing);
        expect(TripStatus.fromString('Completed'), TripStatus.completed);
      });
    });
  });

  group('TripStatusConverter', () {
    const converter = TripStatusConverter();

    group('fromJson', () {
      test('converts string to TripStatus using fromString', () {
        expect(converter.fromJson('draft'), TripStatus.draft);
        expect(converter.fromJson('planned'), TripStatus.planned);
        expect(converter.fromJson('planning'), TripStatus.planned);
        expect(converter.fromJson('ongoing'), TripStatus.ongoing);
        expect(converter.fromJson('active'), TripStatus.ongoing);
        expect(converter.fromJson('completed'), TripStatus.completed);
        expect(converter.fromJson('archived'), TripStatus.completed);
      });
    });

    group('toJson', () {
      test('converts TripStatus to its name string', () {
        expect(converter.toJson(TripStatus.draft), 'draft');
        expect(converter.toJson(TripStatus.planned), 'planned');
        expect(converter.toJson(TripStatus.ongoing), 'ongoing');
        expect(converter.toJson(TripStatus.completed), 'completed');
      });
    });
  });

  group('Trip', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'trip-1',
          'user_id': 'user-1',
          'title': 'Paris Vacation',
          'origin_iata': 'JFK',
          'destination_iata': 'CDG',
          'start_date': '2024-06-01T00:00:00.000',
          'end_date': '2024-06-10T00:00:00.000',
          'status': 'ongoing',
          'description': 'A lovely trip to Paris',
          'destination_name': 'Paris',
          'nb_travelers': 2,
          'cover_image_url': 'https://example.com/img.jpg',
          'budget_target': 3000.50,
          'budget_estimated': 2800.0,
          'origin': 'New York',
          'role': 'OWNER',
          'created_at': '2024-01-15T10:30:00.000',
          'updated_at': '2024-02-20T14:00:00.000',
        };

        final trip = Trip.fromJson(json);

        expect(trip.id, 'trip-1');
        expect(trip.userId, 'user-1');
        expect(trip.title, 'Paris Vacation');
        expect(trip.originIata, 'JFK');
        expect(trip.destinationIata, 'CDG');
        expect(trip.startDate, DateTime.parse('2024-06-01T00:00:00.000'));
        expect(trip.endDate, DateTime.parse('2024-06-10T00:00:00.000'));
        expect(trip.status, TripStatus.ongoing);
        expect(trip.description, 'A lovely trip to Paris');
        expect(trip.destinationName, 'Paris');
        expect(trip.nbTravelers, 2);
        expect(trip.coverImageUrl, 'https://example.com/img.jpg');
        expect(trip.budgetTarget, 3000.50);
        expect(trip.budgetEstimated, 2800.0);
        expect(trip.origin, 'New York');
        expect(trip.role, 'OWNER');
        expect(trip.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
        expect(trip.updatedAt, DateTime.parse('2024-02-20T14:00:00.000'));
      });

      test('parses with only required fields and applies defaults', () {
        final json = <String, dynamic>{'id': 'trip-2', 'user_id': 'user-2'};

        final trip = Trip.fromJson(json);

        expect(trip.id, 'trip-2');
        expect(trip.userId, 'user-2');
        expect(trip.title, isNull);
        expect(trip.originIata, isNull);
        expect(trip.destinationIata, isNull);
        expect(trip.startDate, isNull);
        expect(trip.endDate, isNull);
        expect(trip.status, TripStatus.draft);
        expect(trip.description, isNull);
        expect(trip.destinationName, isNull);
        expect(trip.nbTravelers, isNull);
        expect(trip.coverImageUrl, isNull);
        expect(trip.budgetTarget, isNull);
        expect(trip.budgetEstimated, isNull);
        expect(trip.budgetActual, isNull);
        expect(trip.origin, isNull);
        expect(trip.role, isNull);
        expect(trip.createdAt, isNull);
        expect(trip.updatedAt, isNull);
      });

      test('status defaults to draft when status is null', () {
        final json = <String, dynamic>{
          'id': 'trip-3',
          'user_id': 'user-3',
          'status': null,
        };

        final trip = Trip.fromJson(json);
        expect(trip.status, TripStatus.draft);
      });

      test('parses alias statuses correctly via converter', () {
        final planning = Trip.fromJson({
          'id': 't1',
          'user_id': 'u1',
          'status': 'planning',
        });
        expect(planning.status, TripStatus.planned);

        final active = Trip.fromJson({
          'id': 't2',
          'user_id': 'u2',
          'status': 'active',
        });
        expect(active.status, TripStatus.ongoing);

        final archived = Trip.fromJson({
          'id': 't3',
          'user_id': 'u3',
          'status': 'archived',
        });
        expect(archived.status, TripStatus.completed);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final trip = Trip(
          id: 'trip-rt',
          userId: 'user-rt',
          title: 'Roundtrip Test',
          originIata: 'LAX',
          destinationIata: 'NRT',
          startDate: DateTime.parse('2024-07-01T00:00:00.000'),
          endDate: DateTime.parse('2024-07-15T00:00:00.000'),
          status: TripStatus.planned,
          description: 'A test trip',
          destinationName: 'Tokyo',
          nbTravelers: 4,
          coverImageUrl: 'https://example.com/cover.png',
          budgetTarget: 5000.0,
          origin: 'Los Angeles',
          role: 'OWNER',
          createdAt: DateTime.parse('2024-01-01T00:00:00.000'),
          updatedAt: DateTime.parse('2024-03-01T00:00:00.000'),
        );

        final json = trip.toJson();
        final restored = Trip.fromJson(json);

        expect(restored, trip);
      });

      test('serializes status via TripStatusConverter', () {
        final trip = const Trip(
          id: 't1',
          userId: 'u1',
          status: TripStatus.ongoing,
        );

        final json = trip.toJson();
        expect(json['status'], 'ongoing');
      });

      test('serializes dates as ISO 8601 strings', () {
        final trip = Trip(
          id: 't1',
          userId: 'u1',
          startDate: DateTime.parse('2024-06-01T00:00:00.000'),
        );

        final json = trip.toJson();
        expect(json['start_date'], '2024-06-01T00:00:00.000');
      });
    });

    group('equality', () {
      test('two trips with same fields are equal', () {
        final t1 = const Trip(id: 'trip-1', userId: 'user-1');
        final t2 = const Trip(id: 'trip-1', userId: 'user-1');
        expect(t1, t2);
      });

      test('two trips with different fields are not equal', () {
        final t1 = const Trip(id: 'trip-1', userId: 'user-1');
        final t2 = const Trip(id: 'trip-2', userId: 'user-1');
        expect(t1, isNot(t2));
      });

      test('hashCode is consistent with equality', () {
        final t1 = const Trip(id: 'trip-1', userId: 'user-1');
        final t2 = const Trip(id: 'trip-1', userId: 'user-1');
        expect(t1.hashCode, t2.hashCode);
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final trip = const Trip(
          id: 'trip-1',
          userId: 'user-1',
          title: 'Old Title',
        );
        final updated = trip.copyWith(
          title: 'New Title',
          status: TripStatus.ongoing,
        );

        expect(updated.id, 'trip-1');
        expect(updated.userId, 'user-1');
        expect(updated.title, 'New Title');
        expect(updated.status, TripStatus.ongoing);
      });

      test('copies with no changes produces equal object', () {
        final trip = const Trip(
          id: 'trip-1',
          userId: 'user-1',
          title: 'Test',
          status: TripStatus.planned,
        );
        final copy = trip.copyWith();
        expect(copy, trip);
      });
    });
  });
}
