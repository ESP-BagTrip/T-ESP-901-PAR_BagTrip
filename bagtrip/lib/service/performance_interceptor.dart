import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class PerformanceInterceptor extends Interceptor {
  static const _metricKey = '_perfMetric';

  static HttpMethod? _mapMethod(String method) {
    return switch (method.toUpperCase()) {
      'GET' => HttpMethod.Get,
      'POST' => HttpMethod.Post,
      'PUT' => HttpMethod.Put,
      'PATCH' => HttpMethod.Patch,
      'DELETE' => HttpMethod.Delete,
      _ => null,
    };
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      handler.next(options);
      return;
    }

    final httpMethod = _mapMethod(options.method);
    if (httpMethod == null) {
      handler.next(options);
      return;
    }

    final metric = FirebasePerformance.instance.newHttpMetric(
      options.uri.toString(),
      httpMethod,
    );
    metric.start();
    options.extra[_metricKey] = metric;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _stopMetric(response.requestOptions, responseCode: response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _stopMetric(err.requestOptions, responseCode: err.response?.statusCode);
    handler.next(err);
  }

  void _stopMetric(RequestOptions options, {int? responseCode}) {
    final metric = options.extra.remove(_metricKey);
    if (metric is HttpMetric) {
      if (responseCode != null) {
        metric.httpResponseCode = responseCode;
      }
      metric.stop();
    }
  }
}
