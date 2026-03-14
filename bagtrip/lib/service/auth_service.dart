import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/auth_response.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthRepositoryImpl({ApiClient? apiClient, StorageService? storageService})
    : _apiClient = apiClient ?? ApiClient(),
      _storageService = storageService ?? StorageService();

  @override
  Future<Result<AuthResponse>> login(String email, String password) async {
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
        return Success(authResponse);
      }
      return Failure(UnknownError('login failed: ${response.statusCode}'));
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<AuthResponse>> register(
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
        return Success(authResponse);
      }
      return Failure(
        UnknownError('registration failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      if (response.statusCode == 200) {
        return Success(User.fromJson(response.data));
      }
      return const Success(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Failure(
          AuthenticationError(
            'not authenticated',
            statusCode: 401,
            originalError: e,
          ),
        );
      }
      return const Success(null);
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    final token = await _storageService.getToken();
    return Success(token != null && token.isNotEmpty);
  }

  @override
  Future<Result<AuthResponse>> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return const Failure(CancelledError('Google sign-in cancelled'));
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        return const Failure(
          AuthenticationError('Google identity token missing'),
        );
      }

      final response = await _apiClient.post(
        '/auth/google',
        data: {'idToken': googleAuth.idToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        if (authResponse.accessToken.isEmpty) {
          return const Failure(
            AuthenticationError('token missing in response'),
          );
        }
        await _storageService.saveTokens(
          authResponse.accessToken,
          authResponse.refreshToken,
        );
        return Success(authResponse);
      }
      return Failure(
        UnknownError('Google login failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancelled') || msg.contains('canceled')) {
        return const Failure(CancelledError('Google sign-in cancelled'));
      }
      return Failure(UnknownError(msg, originalError: e));
    }
  }

  @override
  Future<Result<AuthResponse>> loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null ||
          credential.identityToken!.isEmpty) {
        return const Failure(
          AuthenticationError('Apple identity token missing'),
        );
      }

      final response = await _apiClient.post(
        '/auth/apple',
        data: {'idToken': credential.identityToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        if (authResponse.accessToken.isEmpty) {
          return const Failure(
            AuthenticationError('token missing in response'),
          );
        }
        await _storageService.saveTokens(
          authResponse.accessToken,
          authResponse.refreshToken,
        );
        return Success(authResponse);
      }
      return Failure(
        UnknownError('Apple login failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancelled') || msg.contains('canceled')) {
        return const Failure(CancelledError('Apple sign-in cancelled'));
      }
      return Failure(UnknownError(msg, originalError: e));
    }
  }

  @override
  Future<Result<void>> logout() async {
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
    return const Success(null);
  }
}
