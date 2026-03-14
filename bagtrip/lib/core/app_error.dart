sealed class AppError {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  const AppError(this.message, {this.statusCode, this.originalError});
}

final class NetworkError extends AppError {
  const NetworkError(super.message, {super.statusCode, super.originalError});
}

final class AuthenticationError extends AppError {
  const AuthenticationError(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

final class ForbiddenError extends AppError {
  const ForbiddenError(super.message, {super.statusCode, super.originalError});
}

final class NotFoundError extends AppError {
  const NotFoundError(super.message, {super.statusCode, super.originalError});
}

final class ValidationError extends AppError {
  const ValidationError(super.message, {super.statusCode, super.originalError});
}

final class QuotaExceededError extends AppError {
  const QuotaExceededError(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

final class StaleContextError extends AppError {
  const StaleContextError(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

final class ServerError extends AppError {
  const ServerError(super.message, {super.statusCode, super.originalError});
}

final class RateLimitError extends AppError {
  const RateLimitError(super.message, {super.statusCode, super.originalError});
}

final class CancelledError extends AppError {
  const CancelledError(super.message, {super.statusCode, super.originalError});
}

final class UnknownError extends AppError {
  const UnknownError(super.message, {super.statusCode, super.originalError});
}
