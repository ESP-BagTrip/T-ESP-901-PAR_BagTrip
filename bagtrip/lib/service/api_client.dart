import 'package:bagtrip/config/app_config.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/service/storage_service.dart';
import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;
  final String baseUrl;
  final StorageService _storageService;
  bool _isRefreshing = false;

  ApiClient({String? baseUrl, StorageService? storageService})
    : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _storageService = storageService ?? StorageService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: this.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor to add JWT token.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              // Retry the original request with the new token
              final token = await _storageService.getToken();
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } on DioException catch (e) {
                return handler.reject(e);
              }
            } else {
              await _storageService.deleteToken();
            }
          }
          final apiError = _handleError(error);
          return handler.reject(apiError);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    _isRefreshing = true;
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      // Use a separate Dio instance to avoid interceptor loops
      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;
        if (newAccessToken != null && newRefreshToken != null) {
          await _storageService.saveTokens(newAccessToken, newRefreshToken);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // Helper methods for HTTP requests.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path, {dynamic data, Options? options}) {
    return _dio.post(path, data: data, options: options);
  }

  Future<Response> patch(String path, {dynamic data, Options? options}) {
    return _dio.patch(path, data: data, options: options);
  }

  Future<Response> put(String path, {dynamic data, Options? options}) {
    return _dio.put(path, data: data, options: options);
  }

  Future<Response> delete(String path, {Options? options}) {
    return _dio.delete(path, options: options);
  }

  /// Direct access to Dio (if needed).
  Dio get dio => _dio;

  /// Maps a [DioException] to a typed [AppError].
  static AppError mapDioError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;
      final detail = data is Map ? data['detail'] : null;
      final detailStr = detail is String ? detail : error.message ?? '';

      return switch (statusCode) {
        400 => ValidationError(
          detailStr,
          statusCode: statusCode,
          originalError: error,
        ),
        401 => AuthenticationError(
          detailStr,
          statusCode: statusCode,
          originalError: error,
        ),
        402 => QuotaExceededError(
          detailStr,
          statusCode: statusCode,
          originalError: error,
        ),
        403 => ForbiddenError(
          detailStr,
          statusCode: statusCode,
          originalError: error,
        ),
        404 => NotFoundError(
          detailStr,
          statusCode: statusCode,
          originalError: error,
        ),
        409 when data is Map && data['error'] == 'stale_context' =>
          StaleContextError(
            detailStr,
            statusCode: statusCode,
            originalError: error,
          ),
        409 => ValidationError(
          detailStr,
          statusCode: statusCode,
          originalError: error,
        ),
        429 => RateLimitError(
          detailStr,
          statusCode: statusCode,
          originalError: error,
        ),
        500 => ServerError(
          detailStr,
          statusCode: statusCode,
          originalError: error,
        ),
        _ => UnknownError(
          detailStr,
          statusCode: statusCode,
          originalError: error,
        ),
      };
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkError('timeout', originalError: error);
    }
    if (error.type == DioExceptionType.connectionError) {
      return NetworkError('connection_error', originalError: error);
    }
    return UnknownError(error.message ?? '', originalError: error);
  }

  DioException _handleError(DioException error) {
    // Delegate to mapDioError for classification; keep interceptor reject behavior.
    final appError = mapDioError(error);
    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: appError.message,
    );
  }
}
