import 'package:bagtrip/models/invoice.dart';
import 'package:bagtrip/models/payment_method_preview.dart';
import 'package:bagtrip/models/subscription_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionDetails.fromJson', () {
    test('parses the GET /subscription/me response shape', () {
      final json = {
        'plan': 'PREMIUM',
        'cancel_at_period_end': true,
        'current_period_end': '2026-05-30T00:00:00.000Z',
        'plan_expires_at': '2026-05-30T00:00:00.000Z',
        'stripe_subscription_id': 'sub_123',
        'payment_method': {
          'brand': 'visa',
          'last4': '4242',
          'exp_month': 12,
          'exp_year': 2030,
        },
        'ai_generations_remaining': null,
      };

      final details = SubscriptionDetails.fromJson(json);

      expect(details.isPremium, isTrue);
      expect(details.cancelAtPeriodEnd, isTrue);
      expect(details.isCancelScheduled, isTrue);
      expect(details.effectiveRenewalDate, DateTime.utc(2026, 5, 30));
      expect(details.paymentMethod?.last4, '4242');
    });

    test('treats ADMIN as Premium for gating purposes', () {
      const details = SubscriptionDetails(plan: 'ADMIN');
      expect(details.isPremium, isTrue);
      expect(details.isAdmin, isTrue);
      // Admins are never "cancel scheduled" because there is no subscription
      expect(details.isCancelScheduled, isFalse);
    });

    test(
      'falls back to plan_expires_at when current_period_end is missing',
      () {
        final details = SubscriptionDetails(
          plan: 'PREMIUM',
          planExpiresAt: DateTime.utc(2026, 5, 30),
        );
        expect(details.effectiveRenewalDate, DateTime.utc(2026, 5, 30));
      },
    );
  });

  group('PaymentMethodPreview', () {
    test('formats expiry as MM / YYYY', () {
      const pm = PaymentMethodPreview(expMonth: 3, expYear: 2030);
      expect(pm.formattedExpiry, '03 / 2030');
    });

    test('returns null expiry when month or year is missing', () {
      const pm = PaymentMethodPreview(expMonth: 3);
      expect(pm.formattedExpiry, isNull);
    });

    test('capitalises brand for display', () {
      const pm = PaymentMethodPreview(brand: 'visa');
      expect(pm.brandDisplay, 'Visa');
    });

    test('falls back to "Card" when brand is null', () {
      const pm = PaymentMethodPreview();
      expect(pm.brandDisplay, 'Card');
    });
  });

  group('Invoice', () {
    test('converts amount to major currency unit', () {
      const invoice = Invoice(id: 'in_1', amountPaid: 999);
      expect(invoice.amountPaidMajor, 9.99);
    });

    test('returns null major when amount is null', () {
      const invoice = Invoice(id: 'in_1');
      expect(invoice.amountPaidMajor, isNull);
    });
  });
}
