import 'package:bagtrip/models/payment_method_setup_params.dart';
import 'package:bagtrip/models/subscription_start_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionStartParams.fromJson', () {
    test('parses bootstrap fields from /subscription/start', () {
      // The `start` endpoint returns just what the deferred-Intent
      // PaymentSheet needs to render — no subscription_id /
      // payment_intent_client_secret yet (those come from /confirm).
      final params = SubscriptionStartParams.fromJson({
        'customer': 'cus_123',
        'ephemeral_key': 'ek_secret_abc',
        'amount': 999,
        'currency': 'eur',
      });
      expect(params.customer, 'cus_123');
      expect(params.ephemeralKey, 'ek_secret_abc');
      expect(params.amount, 999);
      expect(params.currency, 'eur');
    });
  });

  group('PaymentMethodSetupParams.fromJson', () {
    test('parses snake_case fields from /payment-method/setup', () {
      final params = PaymentMethodSetupParams.fromJson({
        'setup_intent_client_secret': 'seti_secret',
        'ephemeral_key': 'ek_secret',
        'customer': 'cus_123',
      });
      expect(params.setupIntentClientSecret, 'seti_secret');
      expect(params.ephemeralKey, 'ek_secret');
      expect(params.customer, 'cus_123');
    });
  });
}
