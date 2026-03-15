import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/l10n/app_localizations.dart';

/// Returns a short, user-friendly error message suitable for the toaster.
String toUserFriendlyMessage(AppError error, AppLocalizations l10n) {
  return switch (error) {
    NetworkError() => l10n.errorNetwork,
    AuthenticationError() => l10n.errorAuth,
    ForbiddenError() => l10n.errorForbidden,
    NotFoundError() => l10n.errorNotFound,
    ValidationError(:final message)
        when message.isNotEmpty && message.length <= 120 =>
      message,
    ValidationError() => l10n.errorValidation,
    QuotaExceededError() => l10n.errorQuota,
    StaleContextError() => l10n.errorStaleContext,
    ServerError() => l10n.errorServer,
    RateLimitError() => l10n.errorRateLimit,
    CancelledError() => l10n.errorCancelled,
    UnknownError() => l10n.errorUnknown,
  };
}
