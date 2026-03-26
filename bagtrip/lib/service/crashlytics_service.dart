import 'package:bagtrip/core/app_error.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsService({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  Future<void> initialize() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> clearUserId() async {
    await _crashlytics.setUserIdentifier('');
  }

  void recordFlutterFatalError(FlutterErrorDetails details) {
    _crashlytics.recordFlutterFatalError(details);
  }

  bool recordPlatformError(Object error, StackTrace stack) {
    _crashlytics.recordError(error, stack, fatal: true);
    return true;
  }

  Future<void> recordAppError(AppError error, {StackTrace? stackTrace}) async {
    if (kDebugMode) {
      debugPrint(
        '[AppError] ${error.runtimeType}: ${error.message} (status: ${error.statusCode})',
      );
      return;
    }

    final isFatal = error is ServerError || error is UnknownError;

    await _crashlytics.setCustomKey('error_type', error.runtimeType.toString());
    if (error.statusCode != null) {
      await _crashlytics.setCustomKey('status_code', error.statusCode!);
    }

    await _crashlytics.recordError(
      error,
      stackTrace ?? StackTrace.current,
      reason: error.message,
      fatal: isFatal,
    );
  }
}
