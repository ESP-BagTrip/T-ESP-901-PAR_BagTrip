import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/auth_response.dart';
import 'package:bagtrip/models/user.dart';

abstract class AuthRepository {
  Future<Result<AuthResponse>> login(String email, String password);
  Future<Result<AuthResponse>> register(
    String email,
    String password,
    String fullName,
  );
  Future<Result<AuthResponse>> loginWithGoogle();
  Future<Result<AuthResponse>> loginWithApple();
  Future<Result<void>> logout();
  Future<Result<User?>> getCurrentUser();
  Future<Result<User>> updateUser({String? fullName, String? phone});
  Future<Result<bool>> isAuthenticated();
}
