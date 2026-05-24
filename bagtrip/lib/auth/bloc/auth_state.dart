part of 'auth_bloc.dart';

/// Identifies which auth flow is in progress so the UI can scope the spinner
/// to the button that was actually tapped (SMP-294). `null` is used for flows
/// that don't need per-button feedback (e.g. logout).
enum AuthMethod { email, google, apple }

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {
  final bool isLoginMode;

  AuthInitial({this.isLoginMode = true});
}

final class AuthLoading extends AuthState {
  final AuthMethod? method;

  AuthLoading({this.method});
}

final class AuthSuccess extends AuthState {
  final AuthResponse authResponse;

  AuthSuccess({required this.authResponse});
}

final class AuthError extends AuthState {
  final AppError error;
  final bool isLoginMode;

  AuthError({required this.error, this.isLoginMode = true});
}

final class AuthModeChangedState extends AuthState {
  final bool isLoginMode;

  AuthModeChangedState({required this.isLoginMode});
}
