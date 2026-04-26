part of 'subscription_bloc.dart';

/// Coarse-grained tag for the cancel / reactivate buttons. The state model
/// is intentionally a single class with flags (rather than a sealed class
/// per status) because the page renders the same chrome with localized
/// in-flight indicators rather than swapping screens.
enum SubscriptionAction { idle, cancelling, reactivating }

/// Sentinel used by [SubscriptionState.copyWith] so callers can either
/// **clear** an error (`error: null`) or **leave it unchanged** (omit the
/// argument). Without this, the only way to keep an existing error would
/// be to thread it through every call.
const Object _kKeep = Object();

@immutable
final class SubscriptionState {
  final SubscriptionDetails? details;
  final List<Invoice> invoices;

  /// First load — page can show a full skeleton.
  final bool isLoading;

  /// Subsequent loads — keep the previous data visible.
  final bool isRefreshing;

  final bool invoicesLoading;
  final SubscriptionAction actionInFlight;

  /// Last error from the main subscription fetch.
  final AppError? error;

  /// Last error from the invoices fetch — separate so a failed invoices
  /// load doesn't blank out the manage-subscription screen.
  final AppError? invoicesError;

  const SubscriptionState({
    this.details,
    this.invoices = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.invoicesLoading = false,
    this.actionInFlight = SubscriptionAction.idle,
    this.error,
    this.invoicesError,
  });

  const SubscriptionState.initial() : this();

  bool get hasData => details != null;
  bool get isCancelling => actionInFlight == SubscriptionAction.cancelling;
  bool get isReactivating => actionInFlight == SubscriptionAction.reactivating;

  SubscriptionState copyWith({
    SubscriptionDetails? details,
    List<Invoice>? invoices,
    bool? isLoading,
    bool? isRefreshing,
    bool? invoicesLoading,
    SubscriptionAction? actionInFlight,
    Object? error = _kKeep,
    Object? invoicesError = _kKeep,
  }) {
    return SubscriptionState(
      details: details ?? this.details,
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      invoicesLoading: invoicesLoading ?? this.invoicesLoading,
      actionInFlight: actionInFlight ?? this.actionInFlight,
      error: identical(error, _kKeep) ? this.error : error as AppError?,
      invoicesError: identical(invoicesError, _kKeep)
          ? this.invoicesError
          : invoicesError as AppError?,
    );
  }
}
