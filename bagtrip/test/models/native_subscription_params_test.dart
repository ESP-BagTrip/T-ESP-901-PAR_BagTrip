import 'package:bagtrip/models/payment_method_setup_params.dart';
import 'package:bagtrip/models/subscription_start_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionStartParams.fromJson', () {
    test('parses snake_case fields from /subscription/start', () {
      final params = SubscriptionStartParams.fromJson({
        'subscription_id': 'sub_999',
        'payment_intent_client_secret': 'pi_secret_xyz',
        'ephemeral_key': 'ek_secret_abc',
        'customer': 'cus_123',
      });
      expect(params.subscriptionId, 'sub_999');
      expect(params.paymentIntentClientSecret, 'pi_secret_xyz');
      expect(params.ephemeralKey, 'ek_secret_abc');
      expect(params.customer, 'cus_123');
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
