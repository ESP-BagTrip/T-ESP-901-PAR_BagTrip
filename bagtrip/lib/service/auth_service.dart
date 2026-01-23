import 'package:bagtrip/models/auth_response.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthService({ApiClient? apiClient, StorageService? storageService})
    : _apiClient = apiClient ?? ApiClient(),
      _storageService = storageService ?? StorageService();

  /// Login avec email et password
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        // Sauvegarder le token
        await _storageService.saveToken(authResponse.token);

        return authResponse;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  /// Register avec email, password et fullName
  Future<AuthResponse> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'fullName': fullName},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        // Sauvegarder le token
        await _storageService.saveToken(authResponse.token);

        return authResponse;
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during registration: $e');
    }
  }

  /// Récupérer l'utilisateur actuel
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Vérifier si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Login avec Google
  Future<AuthResponse> loginWithGoogle() async {
    try {
      // Initialiser Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Lancer la connexion Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      // Obtenir l'authentification
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Vérifier que le token d'identité est disponible
      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        throw Exception(
          'Google Sign-In failed: identity token is missing. Please check your Firebase configuration.',
        );
      }

      // Envoyer le token à l'API
      final response = await _apiClient.post(
        '/auth/google',
        data: {'idToken': googleAuth.idToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Vérifier que response.data est bien un Map
        if (response.data is! Map<String, dynamic>) {
          throw Exception(
            'Invalid response format from server: expected Map, got ${response.data.runtimeType}',
          );
        }

        try {
          final authResponse = AuthResponse.fromJson(
            response.data as Map<String, dynamic>,
          );

          // Vérifier que le token est présent
          if (authResponse.token.isEmpty) {
            throw Exception('Token is missing in server response');
          }

          // Sauvegarder le token
          await _storageService.saveToken(authResponse.token);

          return authResponse;
        } catch (e) {
          // Erreur de parsing JSON
          throw Exception(
            'Failed to parse server response: ${e.toString()}. Response data: ${response.data}',
          );
        }
      } else {
        final errorMessage =
            response.data is Map
                ? response.data['detail'] ?? 'Google login failed'
                : 'Google login failed: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      // Gérer les erreurs Dio spécifiquement
      final errorMessage =
          e.response?.data is Map
              ? e.response!.data['detail'] ??
                  e.error?.toString() ??
                  'Erreur de connexion'
              : e.error?.toString() ?? 'Erreur lors de la connexion Google';
      throw Exception(errorMessage);
    } catch (e) {
      // Gérer les autres erreurs (y compris les erreurs de GoogleSignIn)
      if (e.toString().contains('cancelled') ||
          e.toString().contains('canceled')) {
        throw Exception('Connexion Google annulée');
      }
      throw Exception('Erreur lors de la connexion Google: ${e.toString()}');
    }
  }

  /// Login avec Apple
  ///
  /// IMPORTANT: Apple Sign-In a des limitations connues sur les simulateurs iOS 14+
  /// qui peuvent causer un loader infini après la saisie des identifiants.
  /// Solutions recommandées:
  /// - Tester sur un appareil physique (recommandé pour la production)
  /// - Utiliser un simulateur iOS 13 si disponible
  /// - Le code fonctionne correctement sur appareil physique
  Future<AuthResponse> loginWithApple() async {
    try {
      // Lancer la connexion Apple
      // Note: Ne pas ajouter de timeout ici car Apple gère déjà son propre timeout
      // et un timeout externe peut interférer avec le flux d'authentification
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Vérifier que le token d'identité est disponible
      if (credential.identityToken == null ||
          credential.identityToken!.isEmpty) {
        throw Exception(
          'Apple Sign-In failed: identity token is missing. Please try again.',
        );
      }

      // Envoyer le token à l'API
      final response = await _apiClient.post(
        '/auth/apple',
        data: {'idToken': credential.identityToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Vérifier que response.data est bien un Map
        if (response.data is! Map<String, dynamic>) {
          throw Exception(
            'Invalid response format from server: expected Map, got ${response.data.runtimeType}',
          );
        }

        try {
          final authResponse = AuthResponse.fromJson(
            response.data as Map<String, dynamic>,
          );

          // Vérifier que le token est présent
          if (authResponse.token.isEmpty) {
            throw Exception('Token is missing in server response');
          }

          // Sauvegarder le token
          await _storageService.saveToken(authResponse.token);

          return authResponse;
        } catch (e) {
          // Erreur de parsing JSON
          throw Exception(
            'Failed to parse server response: ${e.toString()}. Response data: ${response.data}',
          );
        }
      } else {
        final errorMessage =
            response.data is Map
                ? response.data['detail'] ?? 'Apple login failed'
                : 'Apple login failed: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      // Gérer les erreurs Dio spécifiquement
      final errorMessage =
          e.response?.data is Map
              ? e.response!.data['detail'] ??
                  e.error?.toString() ??
                  'Erreur de connexion'
              : e.error?.toString() ?? 'Erreur lors de la connexion Apple';
      throw Exception(errorMessage);
    } catch (e) {
      // Gérer les autres erreurs (y compris les erreurs de SignInWithApple)
      if (e.toString().contains('cancelled') ||
          e.toString().contains('canceled')) {
        throw Exception('Connexion Apple annulée');
      }
      throw Exception('Erreur lors de la connexion Apple: ${e.toString()}');
    }
  }

  /// Logout
  Future<void> logout() async {
    await _storageService.clearAll();
  }
}
