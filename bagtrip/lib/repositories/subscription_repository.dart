import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/invoice.dart';
import 'package:bagtrip/models/payment_method_setup_params.dart';
import 'package:bagtrip/models/subscription_details.dart';
import 'package:bagtrip/models/subscription_start_params.dart';

/// Subscription read+write surface.
///
/// Mirrors the `/v1/subscription/*` endpoints. Each method returns a
/// [Result] — services bubble Stripe / network errors via [Failure] rather
/// than throwing, per project convention.
abstract class SubscriptionRepository {
  /// Lightweight plan info — used for gating decisions across the app.
  /// Returns the raw map so callers can read whatever they need without
  /// breaking when the backend adds a new field.
  Future<Result<Map<String, dynamic>>> getStatus();

  /// Full subscription state for the "Manage subscription" screen.
  /// Includes payment method preview, renewal date and cancel scheduling.
  Future<Result<SubscriptionDetails>> getDetails();

  /// Bootstrap the native PaymentSheet (deferred-IntentConfiguration mode).
  ///
  /// Returns just what the SDK needs to *render* the sheet — `customer`,
  /// `ephemeralKey`, `amount`, `currency`. **No `Subscription` is
  /// created at this stage**; that happens in [confirmSubscription]
  /// once the user has chosen a payment method and tapped Pay.
  Future<Result<SubscriptionStartParams>> start();

  /// Confirm the subscription with the chosen payment method.
  ///
  /// Called from the PaymentSheet's `confirmHandler` (server-driven
  /// `IntentConfiguration` flow). Returns the `client_secret` of the
  /// freshly-created subscription's invoice PaymentIntent — the SDK
  /// uses it to finalise the payment in-sheet (3DS / SCA in line).
  Future<Result<String>> confirmSubscription(String paymentMethodId);

  /// Bootstrap an in-app payment method update via SetupIntent.
  Future<Result<PaymentMethodSetupParams>> startPaymentMethodUpdate();

  /// Wire a freshly-attached PaymentMethod as the subscription default.
  /// Called after the SetupIntent confirms in the native PaymentSheet.
  Future<Result<void>> attachPaymentMethod(String paymentMethodId);

  /// Create a Stripe Checkout Session and return its hosted URL.
  /// Legacy / web fallback only — mobile should call [start] instead.
  Future<Result<String>> getCheckoutUrl();

  /// Create a Stripe Billing Portal Session and return its hosted URL.
  /// Mobile clients should open this in an in-app browser
  /// (`SFSafariViewController` / Custom Tabs), not the system browser.
  Future<Result<String>> getPortalUrl();

  /// Cancel the active subscription at period end (soft cancel).
  /// User keeps Premium until `current_period_end`.
  Future<Result<void>> cancel();

  /// Undo a scheduled cancellation while still in the current period.
  Future<Result<void>> reactivate();

  /// Recent invoices, most recent first. Backend cap is 50.
  Future<Result<List<Invoice>>> listInvoices({int limit = 12});
}
