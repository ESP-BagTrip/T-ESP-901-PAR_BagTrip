import 'package:bagtrip/models/booking_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingResponse JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'id': 'booking-1',
        'amadeusOrderId': 'AMX-ORDER-789',
        'status': 'CONFIRMED',
        'priceTotal': 1250.99,
        'currency': 'EUR',
        'createdAt': '2024-06-01T14:30:00.000',
      };

      final first = BookingResponse.fromJson(json);
      final serialized = first.toJson();
      final second = BookingResponse.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'booking-1');
      expect(second.amadeusOrderId, 'AMX-ORDER-789');
      expect(second.status, 'CONFIRMED');
      expect(second.priceTotal, 1250.99);
      expect(second.currency, 'EUR');
      expect(second.createdAt, DateTime.parse('2024-06-01T14:30:00.000'));
    });

    test('fromJson with minimal fields', () {
      final json = <String, dynamic>{
        'id': 'booking-min',
        'amadeusOrderId': 'AMX-MIN',
        'status': 'PENDING',
        'priceTotal': 0.0,
        'currency': 'USD',
      };

      final model = BookingResponse.fromJson(json);

      expect(model.id, 'booking-min');
      expect(model.amadeusOrderId, 'AMX-MIN');
      expect(model.status, 'PENDING');
      expect(model.priceTotal, 0.0);
      expect(model.currency, 'USD');
      expect(model.createdAt, isNull);
    });

    test('handles nullable fields set to null', () {
      final json = <String, dynamic>{
        'id': 'booking-nulls',
        'amadeusOrderId': 'AMX-NULL',
        'status': 'CANCELLED',
        'priceTotal': 500.0,
        'currency': 'GBP',
        'createdAt': null,
      };

      final first = BookingResponse.fromJson(json);
      final serialized = first.toJson();
      final second = BookingResponse.fromJson(serialized);

      expect(second, first);
      expect(second.createdAt, isNull);
    });
  });
}
