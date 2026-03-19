import 'package:bagtrip/models/activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityCategory', () {
    test('JSON values are mapped correctly via Activity fromJson', () {
      Activity fromCategory(String category) => Activity.fromJson({
        'id': 'a1',
        'trip_id': 't1',
        'title': 'Test',
        'date': '2024-01-15T10:30:00.000',
        'category': category,
      });

      expect(fromCategory('CULTURE').category, ActivityCategory.culture);
      expect(fromCategory('NATURE').category, ActivityCategory.nature);
      expect(fromCategory('FOOD').category, ActivityCategory.food);
      expect(fromCategory('SPORT').category, ActivityCategory.sport);
      expect(fromCategory('SHOPPING').category, ActivityCategory.shopping);
      expect(fromCategory('NIGHTLIFE').category, ActivityCategory.nightlife);
      expect(fromCategory('RELAXATION').category, ActivityCategory.relaxation);
      expect(fromCategory('OTHER').category, ActivityCategory.other);
    });

    test('null category defaults to other', () {
      final activity = Activity.fromJson({
        'id': 'a1',
        'trip_id': 't1',
        'title': 'Test',
        'date': '2024-01-15T10:30:00.000',
      });
      expect(activity.category, ActivityCategory.other);
    });
  });

  group('Activity', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'act-1',
          'trip_id': 'trip-1',
          'title': 'Visit Eiffel Tower',
          'description': 'Iconic landmark visit',
          'date': '2024-06-02T09:00:00.000',
          'start_time': '09:00',
          'end_time': '12:00',
          'location': 'Champ de Mars, Paris',
          'category': 'CULTURE',
          'estimated_cost': 25.50,
          'is_booked': true,
          'created_at': '2024-01-15T10:30:00.000',
          'updated_at': '2024-02-20T14:00:00.000',
        };

        final activity = Activity.fromJson(json);

        expect(activity.id, 'act-1');
        expect(activity.tripId, 'trip-1');
        expect(activity.title, 'Visit Eiffel Tower');
        expect(activity.description, 'Iconic landmark visit');
        expect(activity.date, DateTime.parse('2024-06-02T09:00:00.000'));
        expect(activity.startTime, '09:00');
        expect(activity.endTime, '12:00');
        expect(activity.location, 'Champ de Mars, Paris');
        expect(activity.category, ActivityCategory.culture);
        expect(activity.estimatedCost, 25.50);
        expect(activity.isBooked, true);
        expect(activity.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
        expect(activity.updatedAt, DateTime.parse('2024-02-20T14:00:00.000'));
      });

      test('parses with only required fields and applies defaults', () {
        final json = <String, dynamic>{
          'id': 'act-2',
          'trip_id': 'trip-2',
          'title': 'Free Walking Tour',
          'date': '2024-06-03T14:00:00.000',
        };

        final activity = Activity.fromJson(json);

        expect(activity.id, 'act-2');
        expect(activity.tripId, 'trip-2');
        expect(activity.title, 'Free Walking Tour');
        expect(activity.date, DateTime.parse('2024-06-03T14:00:00.000'));
        expect(activity.description, isNull);
        expect(activity.startTime, isNull);
        expect(activity.endTime, isNull);
        expect(activity.location, isNull);
        expect(activity.category, ActivityCategory.other);
        expect(activity.estimatedCost, isNull);
        expect(activity.isBooked, false);
        expect(activity.createdAt, isNull);
        expect(activity.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final activity = Activity(
          id: 'act-rt',
          tripId: 'trip-rt',
          title: 'Museum Visit',
          description: 'Art museum',
          date: DateTime.parse('2024-06-05T10:00:00.000'),
          startTime: '10:00',
          endTime: '13:00',
          location: 'Louvre, Paris',
          category: ActivityCategory.culture,
          estimatedCost: 17.0,
          isBooked: true,
          createdAt: DateTime.parse('2024-01-01T00:00:00.000'),
          updatedAt: DateTime.parse('2024-03-01T00:00:00.000'),
        );

        final json = activity.toJson();
        final restored = Activity.fromJson(json);

        expect(restored, activity);
      });

      test('serializes category as uppercase JSON value', () {
        final activity = Activity(
          id: 'a1',
          tripId: 't1',
          title: 'Lunch',
          date: DateTime.parse('2024-06-01T12:00:00.000'),
          category: ActivityCategory.food,
        );

        final json = activity.toJson();
        expect(json['category'], 'FOOD');
      });

      test('serializes date as ISO 8601 string', () {
        final activity = Activity(
          id: 'a1',
          tripId: 't1',
          title: 'Test',
          date: DateTime.parse('2024-06-01T12:00:00.000'),
        );

        final json = activity.toJson();
        expect(json['date'], '2024-06-01T12:00:00.000');
      });
    });

    group('equality', () {
      test('two activities with same fields are equal', () {
        final a1 = Activity(
          id: 'a1',
          tripId: 't1',
          title: 'Test',
          date: DateTime.parse('2024-06-01T00:00:00.000'),
        );
        final a2 = Activity(
          id: 'a1',
          tripId: 't1',
          title: 'Test',
          date: DateTime.parse('2024-06-01T00:00:00.000'),
        );
        expect(a1, a2);
      });

      test('two activities with different fields are not equal', () {
        final a1 = Activity(
          id: 'a1',
          tripId: 't1',
          title: 'Test',
          date: DateTime.parse('2024-06-01T00:00:00.000'),
        );
        final a2 = Activity(
          id: 'a2',
          tripId: 't1',
          title: 'Test',
          date: DateTime.parse('2024-06-01T00:00:00.000'),
        );
        expect(a1, isNot(a2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final activity = Activity(
          id: 'a1',
          tripId: 't1',
          title: 'Old Title',
          date: DateTime.parse('2024-06-01T00:00:00.000'),
        );
        final updated = activity.copyWith(
          title: 'New Title',
          category: ActivityCategory.relaxation,
          isBooked: true,
        );

        expect(updated.id, 'a1');
        expect(updated.title, 'New Title');
        expect(updated.category, ActivityCategory.relaxation);
        expect(updated.isBooked, true);
      });

      test('copies with no changes produces equal object', () {
        final activity = Activity(
          id: 'a1',
          tripId: 't1',
          title: 'Test',
          date: DateTime.parse('2024-06-01T00:00:00.000'),
        );
        final copy = activity.copyWith();
        expect(copy, activity);
      });
    });
  });
}
