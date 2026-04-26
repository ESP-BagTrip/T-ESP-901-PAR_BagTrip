import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/invoice.dart';
import 'package:bagtrip/models/subscription_details.dart';

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

  /// Create a Stripe Checkout Session and return its hosted URL.
  Future<Result<String>> getCheckoutUrl();

  /// Create a Stripe Billing Portal Session and return its hosted URL.
  Future<Result<String>> getPortalUrl();

  /// Cancel the active subscription at period end (soft cancel).
  /// User keeps Premium until `current_period_end`.
  Future<Result<void>> cancel();

  /// Undo a scheduled cancellation while still in the current period.
  Future<Result<void>> reactivate();

  /// Recent invoices, most recent first. Backend cap is 50.
  Future<Result<List<Invoice>>> listInvoices({int limit = 12});
}
