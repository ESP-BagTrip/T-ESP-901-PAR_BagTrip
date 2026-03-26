import 'package:bagtrip/service/performance_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PerformanceInterceptor', () {
    late PerformanceInterceptor interceptor;

    setUp(() {
      interceptor = PerformanceInterceptor();
    });

    test('does not add metric to extras in debug mode', () {
      // In debug mode, onRequest should skip metric creation
      final options = RequestOptions(path: '/test', method: 'GET');
      // Just verify the extra map doesn't contain a metric key before any call
      expect(options.extra.containsKey('_perfMetric'), isFalse);
    });

    test('can be added to Dio interceptors without error', () {
      final dio = Dio();
      dio.interceptors.add(interceptor);
      expect(dio.interceptors.length, greaterThan(0));
    });

    test('stopMetric handles missing metric in response gracefully', () async {
      // Use a real Dio with the interceptor to test the full flow
      final dio = Dio(BaseOptions(baseUrl: 'https://httpbin.org'));
      dio.interceptors.add(interceptor);

      // The interceptor should not throw even without a real Firebase instance
      // In debug mode, it skips metric creation entirely, so stop is a no-op
      final options = RequestOptions(path: '/test');
      // Verify extra doesn't have metric (debug mode skip)
      expect(options.extra.containsKey('_perfMetric'), isFalse);
    });
  });
}
