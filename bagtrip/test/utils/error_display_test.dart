import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/l10n/app_localizations_en.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('toUserFriendlyMessage', () {
    test('backend code wins over generic type message', () {
      const error = ValidationError(
        'too much',
        code: 'REFUND_AMOUNT_EXCEEDS_REMAINING',
      );
      expect(
        toUserFriendlyMessage(error, l10n),
        l10n.errorRefundExceedsRemaining,
      );
    });

    test('falls back to type-based copy when no code is supplied', () {
      const error = ValidationError('whatever');
      expect(toUserFriendlyMessage(error, l10n), l10n.errorValidation);
    });

    test(
      'maps STRIPE_CUSTOMER_MISSING and MISSING_STRIPE_CUSTOMER to the same message',
      () {
        const a = ValidationError('a', code: 'STRIPE_CUSTOMER_MISSING');
        const b = ValidationError('b', code: 'MISSING_STRIPE_CUSTOMER');
        expect(toUserFriendlyMessage(a, l10n), toUserFriendlyMessage(b, l10n));
      },
    );

    test('maps NO_ACTIVE_SUBSCRIPTION', () {
      const error = ValidationError('x', code: 'NO_ACTIVE_SUBSCRIPTION');
      expect(
        toUserFriendlyMessage(error, l10n),
        l10n.errorNoActiveSubscription,
      );
    });

    test('unknown code falls through to type-based message', () {
      const error = ValidationError('x', code: 'SOMETHING_NEW');
      expect(toUserFriendlyMessage(error, l10n), l10n.errorValidation);
    });
  });
}
