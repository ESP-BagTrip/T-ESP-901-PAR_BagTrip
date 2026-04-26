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

class DeleteAccountRequested extends AuthEvent {
  DeleteAccountRequested();
}

class AuthModeChanged extends AuthEvent {
  final bool isLoginMode;

  AuthModeChanged({required this.isLoginMode});
}

/// Re-fetch the current user from `/auth/me` and re-emit [AuthSuccess].
///
/// Fired after any side effect that changes the user's plan or profile
/// without re-authenticating — Stripe Checkout return, subscription
/// cancel/reactivate, payment success. Without this, `user.plan` stays
/// stale until the next login.
class UserRefreshRequested extends AuthEvent {
  UserRefreshRequested();
}
