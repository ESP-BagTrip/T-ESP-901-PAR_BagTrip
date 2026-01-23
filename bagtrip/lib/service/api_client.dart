import 'package:bagtrip/service/storage_service.dart';
import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;
  final String baseUrl;
  final StorageService _storageService;

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

    // Intercepteur pour ajouter le token JWT
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Gestion centralisée des erreurs
          final apiError = _handleError(error);
          if (apiError.response?.statusCode == 401) {
            // Token expiré ou invalide
            _storageService.deleteToken();
            // Optionnel : rediriger vers login
          }
          return handler.reject(apiError);
        },
      ),
    );
  }

  // Méthodes helper pour les requêtes
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

  // Getter pour accès direct au Dio (si nécessaire)
  Dio get dio => _dio;

  DioException _handleError(DioException error) {
    // Créer une erreur personnalisée avec message clair
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
