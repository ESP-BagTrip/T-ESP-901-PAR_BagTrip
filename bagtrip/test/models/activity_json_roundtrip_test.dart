import 'package:bagtrip/models/activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Activity JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'id': 'act-abc-789',
        'trip_id': 'trip-xyz-123',
        'title': 'Visit the Louvre Museum',
        'description':
            'Explore one of the world\'s largest and most visited art museums',
        'date': '2024-06-15T09:00:00.000',
        'start_time': '09:00',
        'end_time': '13:00',
        'location': '99 Rue de Rivoli, 75001 Paris, France',
        'category': 'CULTURE',
        'estimated_cost': 22.50,
        'is_booked': true,
        'is_done': true,
        'validation_status': 'VALIDATED',
        'suggested_day': 3,
        'created_at': '2024-05-01T10:00:00.000',
        'updated_at': '2024-05-10T15:30:00.000',
      };

      final first = Activity.fromJson(json);
      final serialized = first.toJson();
      final second = Activity.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'act-abc-789');
      expect(second.tripId, 'trip-xyz-123');
      expect(second.title, 'Visit the Louvre Museum');
      expect(
        second.description,
        'Explore one of the world\'s largest and most visited art museums',
      );
      expect(second.date, DateTime.parse('2024-06-15T09:00:00.000'));
      expect(second.startTime, '09:00');
      expect(second.endTime, '13:00');
      expect(second.location, '99 Rue de Rivoli, 75001 Paris, France');
      expect(second.category, ActivityCategory.culture);
      expect(second.estimatedCost, 22.50);
      expect(second.isBooked, true);
      expect(second.isDone, true);
      expect(second.validationStatus, ValidationStatus.validated);
      expect(second.suggestedDay, 3);
      expect(second.createdAt, DateTime.parse('2024-05-01T10:00:00.000'));
      expect(second.updatedAt, DateTime.parse('2024-05-10T15:30:00.000'));
    });

    test('roundtrip with minimal required fields preserves defaults', () {
      final json = <String, dynamic>{
        'id': 'act-minimal',
        'trip_id': 'trip-1',
        'title': 'Free Walking Tour',
        'date': '2024-08-01T14:00:00.000',
      };

      final first = Activity.fromJson(json);
      final serialized = first.toJson();
      final second = Activity.fromJson(serialized);

      expect(second, first);
      expect(second.category, ActivityCategory.other);
      expect(second.isBooked, false);
      expect(second.isDone, false);
      expect(second.validationStatus, ValidationStatus.manual);
      expect(second.description, isNull);
      expect(second.startTime, isNull);
      expect(second.endTime, isNull);
      expect(second.location, isNull);
      expect(second.estimatedCost, isNull);
      expect(second.suggestedDay, isNull);
    });

    test('roundtrip preserves each ActivityCategory value', () {
      for (final category in ActivityCategory.values) {
        final activity = Activity(
          id: 'act-$category',
          tripId: 'trip-1',
          title: 'Category test: $category',
          date: DateTime(2024, 7),
          category: category,
        );

        final json = activity.toJson();
        final restored = Activity.fromJson(json);

        expect(
          restored.category,
          category,
          reason: 'Category $category should survive roundtrip',
        );
        expect(restored, activity);
      }
    });

    test('roundtrip preserves each ValidationStatus value', () {
      for (final status in ValidationStatus.values) {
        final activity = Activity(
          id: 'act-vs-$status',
          tripId: 'trip-1',
          title: 'Validation status test: $status',
          date: DateTime(2024, 7),
          validationStatus: status,
        );

        final json = activity.toJson();
        final restored = Activity.fromJson(json);

        expect(
          restored.validationStatus,
          status,
          reason: 'ValidationStatus $status should survive roundtrip',
        );
        expect(restored, activity);
      }
    });

    test('category serializes as uppercase JSON value', () {
      final activity = Activity(
        id: 'a1',
        tripId: 't1',
        title: 'Dinner',
        date: DateTime(2024, 6, 1, 19),
        category: ActivityCategory.food,
      );

      final json = activity.toJson();
      expect(json['category'], 'FOOD');

      final restored = Activity.fromJson(json);
      expect(restored.category, ActivityCategory.food);
    });
  });
}
