class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/v1',
  );

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'STRIPE_KEY_NOT_SET',
  );

  /// Apple Pay merchant identifier — set this once the app's Apple
  /// Developer Merchant ID is created and wired in Stripe + Xcode.
  /// Empty until then; the PaymentSheet falls back to card-only on iOS.
  /// Pass via `--dart-define=APPLE_MERCHANT_IDENTIFIER=merchant.fr.bagtrip.app`.
  static const String appleMerchantIdentifier = String.fromEnvironment(
    'APPLE_MERCHANT_IDENTIFIER',
  );
}
