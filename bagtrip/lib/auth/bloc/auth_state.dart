part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {
  final bool isLoginMode;

  AuthInitial({this.isLoginMode = true});
}

final class AuthLoading extends AuthState {}

final class AuthSuccess extends AuthState {
  final AuthResponse authResponse;

  AuthSuccess({required this.authResponse});
}

final class AuthError extends AuthState {
  final String errorMessage;
  final bool isLoginMode;

  AuthError({required this.errorMessage, this.isLoginMode = true});
}

final class AuthModeChangedState extends AuthState {
  final bool isLoginMode;

  AuthModeChangedState({required this.isLoginMode});
}
