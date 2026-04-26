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
