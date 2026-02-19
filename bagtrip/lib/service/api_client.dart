import 'package:bagtrip/service/storage_service.dart';
import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;
  final String baseUrl;
  final StorageService _storageService;
  bool _isRefreshing = false;

  ApiClient({String? baseUrl, StorageService? storageService})
    : baseUrl = baseUrl ?? 'http://localhost:3000/v1',
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

  Future<Response> delete(String path, {Options? options}) {
    return _dio.delete(path, options: options);
  }

  /// Direct access to Dio (if needed).
  Dio get dio => _dio;

  DioException _handleError(DioException error) {
    String message;
    int? statusCode;

    if (error.response != null) {
      statusCode = error.response!.statusCode;
      final data = error.response!.data;

      switch (statusCode) {
        case 400:
          message = data['detail'] ?? 'Requête invalide';
          break;
        case 401:
          message = 'Non authentifié. Veuillez vous reconnecter.';
          break;
        case 403:
          message =
              'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
          break;
        case 404:
          message = 'Ressource non trouvée';
          break;
        case 409:
          // Context version mismatch
          if (data is Map && data['error'] == 'stale_context') {
            message = 'Le contexte a été mis à jour. Veuillez rafraîchir.';
          } else {
            message = data['detail'] ?? 'Conflit de version';
          }
          break;
        case 429:
          message = 'Trop de requêtes. Veuillez patienter.';
          break;
        case 500:
          message = 'Erreur serveur. Veuillez réessayer plus tard.';
          break;
        default:
          message = data['detail'] ?? 'Une erreur est survenue';
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Timeout. Vérifiez votre connexion internet.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Erreur de connexion. Vérifiez votre connexion internet.';
    } else {
      message = 'Une erreur inattendue est survenue';
    }

    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: message,
    );
  }
}
