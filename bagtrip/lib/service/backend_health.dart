import 'package:dio/dio.dart';

/// Base URL of the API (with /v1). Health endpoint is at origin/health.
const String _defaultBaseUrl = 'http://localhost:3000/v1';

/// Returns the API origin (without /v1) for health checks.
String get _healthOrigin {
  final base = _defaultBaseUrl;
  if (base.endsWith('/v1')) {
    return base.substring(0, base.length - 3);
  }
  return base;
}

/// Waits until the backend responds to GET /health or [timeout] is reached.
/// Retries every [retryInterval] until [maxWait].
/// Returns true if backend became ready, false if timeout.
Future<bool> waitForBackendReady({
  Duration maxWait = const Duration(seconds: 10),
  Duration retryInterval = const Duration(seconds: 1),
  Duration requestTimeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(maxWait);
  final dio = Dio(
    BaseOptions(connectTimeout: requestTimeout, receiveTimeout: requestTimeout),
  );

  while (DateTime.now().isBefore(deadline)) {
    try {
      final response = await dio.get('$_healthOrigin/health');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (_) {
      // Backend not ready, retry after interval
    }
    await Future<void>.delayed(retryInterval);
  }
  return false;
}
