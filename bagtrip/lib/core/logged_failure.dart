import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/crashlytics_service.dart';

/// Creates a [Failure] and logs the error via [CrashlyticsService].
/// Skips [CancelledError] (user-initiated cancellation, not an error).
Failure<T> loggedFailure<T>(AppError error, {StackTrace? stackTrace}) {
  if (error is! CancelledError && getIt.isRegistered<CrashlyticsService>()) {
    getIt<CrashlyticsService>().recordAppError(
      error,
      stackTrace: stackTrace ?? StackTrace.current,
    );
  }
  return Failure<T>(error);
}
