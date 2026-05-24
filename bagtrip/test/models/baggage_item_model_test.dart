import 'package:bagtrip/models/baggage_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaggageItem JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'id': 'bag-1',
        'trip_id': 'trip-1',
        'name': 'Toothbrush',
        'quantity': 2,
        'is_packed': true,
        'category': 'Hygiene',
        'notes': 'Travel-size preferred',
        'created_at': '2024-06-01T08:00:00.000',
        'updated_at': '2024-06-02T09:00:00.000',
      };

      final first = BaggageItem.fromJson(json);
      final serialized = first.toJson();
      final second = BaggageItem.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'bag-1');
      expect(second.tripId, 'trip-1');
      expect(second.name, 'Toothbrush');
      expect(second.quantity, 2);
      expect(second.isPacked, true);
      expect(second.category, 'Hygiene');
      expect(second.notes, 'Travel-size preferred');
      expect(second.createdAt, DateTime.parse('2024-06-01T08:00:00.000'));
      expect(second.updatedAt, DateTime.parse('2024-06-02T09:00:00.000'));
    });

    test('fromJson with minimal fields applies defaults', () {
      final json = <String, dynamic>{
        'id': 'bag-min',
        'trip_id': 'trip-min',
        'name': 'Sunscreen',
      };

      final model = BaggageItem.fromJson(json);

      expect(model.id, 'bag-min');
      expect(model.tripId, 'trip-min');
      expect(model.name, 'Sunscreen');
      expect(model.quantity, isNull);
      expect(model.isPacked, false);
      expect(model.category, isNull);
      expect(model.notes, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('handles nullable fields set to null', () {
      final json = <String, dynamic>{
        'id': 'bag-nulls',
        'trip_id': 'trip-nulls',
        'name': 'Passport',
        'quantity': null,
        'category': null,
        'notes': null,
        'created_at': null,
        'updated_at': null,
      };

      final first = BaggageItem.fromJson(json);
      final serialized = first.toJson();
      final second = BaggageItem.fromJson(serialized);

      expect(second, first);
      expect(second.quantity, isNull);
      expect(second.isPacked, false);
      expect(second.category, isNull);
      expect(second.notes, isNull);
      expect(second.createdAt, isNull);
      expect(second.updatedAt, isNull);
    });
  });
}
