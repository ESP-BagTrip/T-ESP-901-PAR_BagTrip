import 'package:bagtrip/models/payment_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentCard', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'card-1',
          'lastFourDigits': '4242',
          'expiryDate': '12/25',
          'isDefault': true,
        };

        final card = PaymentCard.fromJson(json);

        expect(card.id, 'card-1');
        expect(card.lastFourDigits, '4242');
        expect(card.expiryDate, '12/25');
        expect(card.isDefault, true);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        const card = PaymentCard(
          id: 'card-rt',
          lastFourDigits: '1234',
          expiryDate: '06/28',
          isDefault: false,
        );

        final json = card.toJson();
        final restored = PaymentCard.fromJson(json);

        expect(restored, card);
      });

      test('serializes keys as camelCase', () {
        const card = PaymentCard(
          id: 'c1',
          lastFourDigits: '9999',
          expiryDate: '01/30',
          isDefault: true,
        );

        final json = card.toJson();
        expect(json['lastFourDigits'], '9999');
        expect(json['expiryDate'], '01/30');
        expect(json['isDefault'], true);
      });
    });

    group('equality', () {
      test('two cards with same fields are equal', () {
        const c1 = PaymentCard(
          id: 'c1',
          lastFourDigits: '4242',
          expiryDate: '12/25',
          isDefault: true,
        );
        const c2 = PaymentCard(
          id: 'c1',
          lastFourDigits: '4242',
          expiryDate: '12/25',
          isDefault: true,
        );
        expect(c1, c2);
      });

      test('two cards with different fields are not equal', () {
        const c1 = PaymentCard(
          id: 'c1',
          lastFourDigits: '4242',
          expiryDate: '12/25',
          isDefault: true,
        );
        const c2 = PaymentCard(
          id: 'c2',
          lastFourDigits: '4242',
          expiryDate: '12/25',
          isDefault: true,
        );
        expect(c1, isNot(c2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        const card = PaymentCard(
          id: 'c1',
          lastFourDigits: '4242',
          expiryDate: '12/25',
          isDefault: false,
        );
        final updated = card.copyWith(isDefault: true);

        expect(updated.id, 'c1');
        expect(updated.lastFourDigits, '4242');
        expect(updated.isDefault, true);
      });
    });
  });
}
