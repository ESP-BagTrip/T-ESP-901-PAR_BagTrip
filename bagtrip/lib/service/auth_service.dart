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

  /// Login with email and password.
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        await _storageService.saveTokens(
          authResponse.accessToken,
          authResponse.refreshToken,
        );

        return authResponse;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message =
          e.error is String
              ? e.error as String
              : 'Erreur de connexion. Veuillez réessayer.';
      throw Exception(message);
    } catch (e) {
      throw Exception('Une erreur est survenue. Veuillez réessayer.');
    }
  }

  /// Register with email, password and full name.
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

        await _storageService.saveTokens(
          authResponse.accessToken,
          authResponse.refreshToken,
        );

        return authResponse;
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message =
          e.error is String
              ? e.error as String
              : 'Erreur de connexion. Veuillez réessayer.';
      throw Exception(message);
    } catch (e) {
      throw Exception('Une erreur est survenue. Veuillez réessayer.');
    }
  }

  /// Get the current user.
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

  /// Check if the user is authenticated.
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Login with Google.
  Future<AuthResponse> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Ensure identity token is available.
      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        throw Exception(
          'Google Sign-In failed: identity token is missing. Please check your Firebase configuration.',
        );
      }

      // Send token to API.
      final response = await _apiClient.post(
        '/auth/google',
        data: {'idToken': googleAuth.idToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is! Map<String, dynamic>) {
          throw Exception(
            'Invalid response format from server: expected Map, got ${response.data.runtimeType}',
          );
        }

        try {
          final authResponse = AuthResponse.fromJson(
            response.data as Map<String, dynamic>,
          );

          if (authResponse.accessToken.isEmpty) {
            throw Exception('Token is missing in server response');
          }

          await _storageService.saveTokens(
            authResponse.accessToken,
            authResponse.refreshToken,
          );

          return authResponse;
        } catch (e) {
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
      final errorMessage =
          e.response?.data is Map
              ? e.response!.data['detail'] ??
                  e.error?.toString() ??
                  'Connection error'
              : e.error?.toString() ?? 'Google sign-in error';
      throw Exception(errorMessage);
    } catch (e) {
      if (e.toString().contains('cancelled') ||
          e.toString().contains('canceled')) {
        throw Exception('Google sign-in cancelled');
      }
      throw Exception('Google sign-in error: ${e.toString()}');
    }
  }

  /// Login with Apple.
  ///
  /// IMPORTANT: Apple Sign-In has known limitations on iOS 14+ simulators
  /// that can cause an infinite loader after entering credentials.
  /// Recommended: test on a physical device (for production), or use an
  /// iOS 13 simulator if available; code works correctly on a physical device.
  Future<AuthResponse> loginWithApple() async {
    try {
      // Do not add a timeout here: Apple has its own and an external timeout
      // can interfere with the auth flow.
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null ||
          credential.identityToken!.isEmpty) {
        throw Exception(
          'Apple Sign-In failed: identity token is missing. Please try again.',
        );
      }

      final response = await _apiClient.post(
        '/auth/apple',
        data: {'idToken': credential.identityToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is! Map<String, dynamic>) {
          throw Exception(
            'Invalid response format from server: expected Map, got ${response.data.runtimeType}',
          );
        }

        try {
          final authResponse = AuthResponse.fromJson(
            response.data as Map<String, dynamic>,
          );

          if (authResponse.accessToken.isEmpty) {
            throw Exception('Token is missing in server response');
          }

          await _storageService.saveTokens(
            authResponse.accessToken,
            authResponse.refreshToken,
          );

          return authResponse;
        } catch (e) {
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
      final errorMessage =
          e.response?.data is Map
              ? e.response!.data['detail'] ??
                  e.error?.toString() ??
                  'Connection error'
              : e.error?.toString() ?? 'Apple sign-in error';
      throw Exception(errorMessage);
    } catch (e) {
      if (e.toString().contains('cancelled') ||
          e.toString().contains('canceled')) {
        throw Exception('Apple sign-in cancelled');
      }
      throw Exception('Apple sign-in error: ${e.toString()}');
    }
  }

  /// Logout — call server to revoke refresh token, then clear local storage.
  Future<void> logout() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post(
          '/auth/logout',
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (_) {
      // Best effort — clear tokens even if server call fails
    }
    await _storageService.clearAll();
  }
}
