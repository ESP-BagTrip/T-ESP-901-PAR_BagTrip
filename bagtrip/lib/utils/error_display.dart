import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/l10n/app_localizations.dart';

/// Returns a short, user-friendly error message suitable for the toaster.
///
/// Two-tier resolution:
///   1. If the backend supplied a structured code (e.g. `ALREADY_PREMIUM`),
///      map it to the most precise localized string.
///   2. Otherwise fall back to the AppError type — the broad bucket the
///      transport layer assigned (network / auth / validation / etc.).
///
/// `ValidationError.message` is never returned verbatim because the
/// backend's English validation strings would leak into French UIs.
String toUserFriendlyMessage(AppError error, AppLocalizations l10n) {
  // Tier 1: explicit backend codes — these are the only path to a
  // domain-specific message (refund-too-large, already-fully-refunded, …).
  final code = error.code;
  if (code != null) {
    final mapped = _codeToMessage(code, l10n);
    if (mapped != null) return mapped;
  }

  // Tier 2: type-based fallback.
  return switch (error) {
    NetworkError() => l10n.errorNetwork,
    AuthenticationError() => l10n.errorAuth,
    ForbiddenError() => l10n.errorForbidden,
    NotFoundError() => l10n.errorNotFound,
    ValidationError() => l10n.errorValidation,
    QuotaExceededError() => l10n.errorQuota,
    StaleContextError() => l10n.errorStaleContext,
    ServerError() => l10n.errorServer,
    RateLimitError() => l10n.errorRateLimit,
    CancelledError() => l10n.errorCancelled,
    UnknownError() => l10n.errorUnknown,
  };
}

String? _codeToMessage(String code, AppLocalizations l10n) {
  return switch (code) {
    // Subscription
    'ALREADY_PREMIUM' => l10n.errorAlreadyPremium,
    'NO_ACTIVE_SUBSCRIPTION' => l10n.errorNoActiveSubscription,
    'STRIPE_CUSTOMER_MISSING' => l10n.errorMissingStripeCustomer,
    'MISSING_STRIPE_CUSTOMER' => l10n.errorMissingStripeCustomer,
    // Refund
    'REFUND_AMOUNT_EXCEEDS_REMAINING' => l10n.errorRefundExceedsRemaining,
    'ALREADY_FULLY_REFUNDED' => l10n.errorAlreadyFullyRefunded,
    'INVALID_REFUND_REASON' => l10n.errorInvalidRefundReason,
    _ => null,
  };
}
