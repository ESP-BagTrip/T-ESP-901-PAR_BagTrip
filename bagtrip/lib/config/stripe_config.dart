import 'package:flutter_stripe/flutter_stripe.dart';

class StripeConfig {
  static String? _publishableKey;

  /// Initialize Stripe with publishable key
  /// Call this in main.dart before runApp
  static Future<void> initialize(String publishableKey) async {
    _publishableKey = publishableKey;
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  /// Get the publishable key
  static String? get publishableKey => _publishableKey;

  /// Check if Stripe is initialized
  static bool get isInitialized => _publishableKey != null;
}
