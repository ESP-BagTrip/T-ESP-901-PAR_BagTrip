part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested({required this.email, required this.password});
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String? fullName;

  RegisterRequested({
    required this.email,
    required this.password,
    this.fullName,
  });
}

class GoogleSignInRequested extends AuthEvent {
  GoogleSignInRequested();
}

class AppleSignInRequested extends AuthEvent {
  AppleSignInRequested();
}

class LogoutRequested extends AuthEvent {
  LogoutRequested();
}

class AuthModeChanged extends AuthEvent {
  final bool isLoginMode;

  AuthModeChanged({required this.isLoginMode});
}
