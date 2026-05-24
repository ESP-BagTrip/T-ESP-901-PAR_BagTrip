import 'package:bagtrip/models/accommodation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accommodation JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'id': 'acc-1',
        'trip_id': 'trip-1',
        'name': 'Hotel Sunshine',
        'address': '123 Beach Road, Nice',
        'check_in': '2024-06-01T14:00:00.000',
        'check_out': '2024-06-05T11:00:00.000',
        'price_per_night': 120.50,
        'currency': 'EUR',
        'booking_reference': 'BK-98765',
        'notes': 'Sea view room requested',
        'created_at': '2024-05-01T10:00:00.000',
        'updated_at': '2024-05-02T12:00:00.000',
      };

      final first = Accommodation.fromJson(json);
      final serialized = first.toJson();
      final second = Accommodation.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'acc-1');
      expect(second.tripId, 'trip-1');
      expect(second.name, 'Hotel Sunshine');
      expect(second.address, '123 Beach Road, Nice');
      expect(second.checkIn, DateTime.parse('2024-06-01T14:00:00.000'));
      expect(second.checkOut, DateTime.parse('2024-06-05T11:00:00.000'));
      expect(second.pricePerNight, 120.50);
      expect(second.currency, 'EUR');
      expect(second.bookingReference, 'BK-98765');
      expect(second.notes, 'Sea view room requested');
      expect(second.createdAt, DateTime.parse('2024-05-01T10:00:00.000'));
      expect(second.updatedAt, DateTime.parse('2024-05-02T12:00:00.000'));
    });

    test('fromJson with minimal fields', () {
      final json = <String, dynamic>{
        'id': 'acc-min',
        'trip_id': 'trip-min',
        'name': 'Basic Hostel',
      };

      final model = Accommodation.fromJson(json);

      expect(model.id, 'acc-min');
      expect(model.tripId, 'trip-min');
      expect(model.name, 'Basic Hostel');
      expect(model.address, isNull);
      expect(model.checkIn, isNull);
      expect(model.checkOut, isNull);
      expect(model.pricePerNight, isNull);
      expect(model.currency, isNull);
      expect(model.bookingReference, isNull);
      expect(model.notes, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('handles nullable fields set to null', () {
      final json = <String, dynamic>{
        'id': 'acc-nulls',
        'trip_id': 'trip-nulls',
        'name': 'Null Hotel',
        'address': null,
        'check_in': null,
        'check_out': null,
        'price_per_night': null,
        'currency': null,
        'booking_reference': null,
        'notes': null,
        'created_at': null,
        'updated_at': null,
      };

      final first = Accommodation.fromJson(json);
      final serialized = first.toJson();
      final second = Accommodation.fromJson(serialized);

      expect(second, first);
      expect(second.address, isNull);
      expect(second.checkIn, isNull);
      expect(second.checkOut, isNull);
      expect(second.pricePerNight, isNull);
      expect(second.currency, isNull);
      expect(second.bookingReference, isNull);
      expect(second.notes, isNull);
      expect(second.createdAt, isNull);
      expect(second.updatedAt, isNull);
    });
  });
}
