import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/l10n/app_localizations.dart';

/// Returns a short, user-friendly error message suitable for the toaster.
///
/// All branches return a localized string. In particular, `ValidationError`
/// used to short-circuit to `error.message` when it was short enough, which
/// leaked the backend's English validation strings into French UIs. Until
/// we have a `code` field on `ValidationError` that we can map to l10n
/// keys, we always fall back to `l10n.errorValidation`.
String toUserFriendlyMessage(AppError error, AppLocalizations l10n) {
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
