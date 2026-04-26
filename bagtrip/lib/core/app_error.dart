/// Typed error hierarchy. Every API/repository call returns
/// `Result<T>` where the `Failure` branch wraps an [AppError] subclass.
///
/// Subclasses are categorized by HTTP/transport semantics. The optional
/// [code] field carries the backend's machine-readable error code (e.g.
/// `ALREADY_PREMIUM`, `REFUND_AMOUNT_EXCEEDS_REMAINING`) so the UI can map
/// it to a precise localized message in `error_display.dart`.
sealed class AppError {
  final String message;
  final int? statusCode;

  /// Backend error code (e.g. `MISSING_STRIPE_CUSTOMER`). Lets
  /// [error_display] target one specific scenario instead of falling back
  /// to the generic "validation" / "server" copy.
  final String? code;
  final dynamic originalError;
  const AppError(
    this.message, {
    this.statusCode,
    this.code,
    this.originalError,
  });
}

final class NetworkError extends AppError {
  const NetworkError(
    super.message, {
    super.statusCode,
    super.code,
    super.originalError,
  });
}

final class AuthenticationError extends AppError {
  const AuthenticationError(
    super.message, {
    super.statusCode,
    super.code,
    super.originalError,
  });
}

final class ForbiddenError extends AppError {
  const ForbiddenError(
    super.message, {
    super.statusCode,
    super.code,
    super.originalError,
  });
}

final class NotFoundError extends AppError {
  const NotFoundError(
    super.message, {
    super.statusCode,
    super.code,
    super.originalError,
  });
}

final class ValidationError extends AppError {
  const ValidationError(
    super.message, {
    super.statusCode,
    super.code,
    super.originalError,
  });
}

final class QuotaExceededError extends AppError {
  const QuotaExceededError(
    super.message, {
    super.statusCode,
    super.code,
    super.originalError,
  });
}

final class StaleContextError extends AppError {
  const StaleContextError(
    super.message, {
    super.statusCode,
    super.code,
    super.originalError,
  });
}

final class ServerError extends AppError {
  const ServerError(
    super.message, {
    super.statusCode,
    super.code,
    super.originalError,
  });
}

final class RateLimitError extends AppError {
  const RateLimitError(
    super.message, {
    super.statusCode,
    super.code,
    super.originalError,
  });
}

final class CancelledError extends AppError {
  const CancelledError(
    super.message, {
    super.statusCode,
    super.code,
    super.originalError,
  });
}

final class UnknownError extends AppError {
  const UnknownError(
    super.message, {
    super.statusCode,
    super.code,
    super.originalError,
  });
}
