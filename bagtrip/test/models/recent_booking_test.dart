import 'package:bagtrip/models/recent_booking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecentBooking', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'booking-1',
          'details': 'CDG → JFK',
          'date': '2024-06-01T10:00:00.000',
          'priceTotal': 599.99,
          'currency': 'EUR',
          'status': 'confirmed',
        };

        final booking = RecentBooking.fromJson(json);

        expect(booking.id, 'booking-1');
        expect(booking.details, 'CDG → JFK');
        expect(booking.date, DateTime.parse('2024-06-01T10:00:00.000'));
        expect(booking.priceTotal, 599.99);
        expect(booking.currency, 'EUR');
        expect(booking.status, 'confirmed');
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final booking = RecentBooking(
          id: 'booking-rt',
          details: 'LHR → LAX',
          date: DateTime.parse('2024-07-15T08:30:00.000'),
          priceTotal: 1200.50,
          currency: 'GBP',
          status: 'pending',
        );

        final json = booking.toJson();
        final restored = RecentBooking.fromJson(json);

        expect(restored, booking);
      });

      test('serializes priceTotal as camelCase', () {
        final booking = RecentBooking(
          id: 'b1',
          details: 'Test',
          date: DateTime.parse('2024-01-01T00:00:00.000'),
          priceTotal: 100.0,
          currency: 'EUR',
          status: 'ok',
        );

        final json = booking.toJson();
        expect(json['priceTotal'], 100.0);
      });
    });

    group('equality', () {
      test('two bookings with same fields are equal', () {
        final b1 = RecentBooking(
          id: 'b1',
          details: 'Test',
          date: DateTime.parse('2024-01-01T00:00:00.000'),
          priceTotal: 100.0,
          currency: 'EUR',
          status: 'ok',
        );
        final b2 = RecentBooking(
          id: 'b1',
          details: 'Test',
          date: DateTime.parse('2024-01-01T00:00:00.000'),
          priceTotal: 100.0,
          currency: 'EUR',
          status: 'ok',
        );
        expect(b1, b2);
      });

      test('two bookings with different fields are not equal', () {
        final b1 = RecentBooking(
          id: 'b1',
          details: 'Test',
          date: DateTime.parse('2024-01-01T00:00:00.000'),
          priceTotal: 100.0,
          currency: 'EUR',
          status: 'ok',
        );
        final b2 = RecentBooking(
          id: 'b2',
          details: 'Test',
          date: DateTime.parse('2024-01-01T00:00:00.000'),
          priceTotal: 100.0,
          currency: 'EUR',
          status: 'ok',
        );
        expect(b1, isNot(b2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final booking = RecentBooking(
          id: 'b1',
          details: 'Old',
          date: DateTime.parse('2024-01-01T00:00:00.000'),
          priceTotal: 100.0,
          currency: 'EUR',
          status: 'pending',
        );
        final updated = booking.copyWith(
          status: 'confirmed',
          priceTotal: 150.0,
        );

        expect(updated.id, 'b1');
        expect(updated.details, 'Old');
        expect(updated.status, 'confirmed');
        expect(updated.priceTotal, 150.0);
      });
    });
  });
}
