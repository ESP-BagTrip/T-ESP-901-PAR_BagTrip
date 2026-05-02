part of 'subscription_bloc.dart';

@immutable
sealed class SubscriptionEvent {}

/// Fetch (or re-fetch) the full subscription details from the backend.
final class LoadSubscription extends SubscriptionEvent {}

/// Alias for [LoadSubscription] — semantically a "pull-to-refresh".
final class RefreshSubscription extends SubscriptionEvent {}

/// Fetch the invoice list. Done lazily — only when the user navigates
/// to the invoices screen, not on every subscription state load.
final class LoadInvoices extends SubscriptionEvent {
  final int limit;
  LoadInvoices({this.limit = 12});
}

/// Cancel the active subscription at period end (soft cancel).
final class CancelSubscription extends SubscriptionEvent {}

/// Undo a scheduled cancellation while still in the current period.
final class ReactivateSubscription extends SubscriptionEvent {}

/// Reset to initial state — used on logout to clear the previous user's
/// subscription state from the in-memory bloc.
final class ResetSubscription extends SubscriptionEvent {}

/// Locally flip the cached [SubscriptionDetails] to PREMIUM the moment
/// the PaymentSheet returns success — *before* `/subscription/me`
/// reflects the change.
///
/// `/subscription/me` reads from `User.plan`, which is only updated by
/// the `customer.subscription.created` webhook. There's a 200-1500 ms
/// window between PaymentSheet success and the webhook landing during
/// which a naive `LoadSubscription` would re-paint the manage screen
/// in FREE mode and bounce the user back to the paywall body. The
/// optimistic emit + [ConfirmSubscriptionActivation] reconciliation
/// hides that gap.
///
/// Named distinctly from `AuthBloc.OptimisticPremiumActivated` because
/// callers import both blocs in the same file (the checkout flow) —
/// keeping a unique class name avoids prefix gymnastics.
final class OptimisticSubscriptionActivated extends SubscriptionEvent {}

/// Reconcile the optimistic Premium subscription with the server.
///
/// Retries `/subscription/me` at 500 ms → 2 s → 5 s after the optimistic
/// flip until the server confirms `plan == PREMIUM`. Mirrors
/// [AuthBloc.ConfirmPremiumActivation] but at the subscription-detail
/// level so the manage screen also catches up — currentPeriodEnd,
/// payment method, etc. only exist server-side.
final class ConfirmSubscriptionActivation extends SubscriptionEvent {}
