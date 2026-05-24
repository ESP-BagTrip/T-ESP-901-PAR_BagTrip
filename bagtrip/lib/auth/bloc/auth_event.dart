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

/// Locally flip `user.plan` to PREMIUM the moment the PaymentSheet
/// returns success — *before* the webhook lands.
///
/// Stripe has already confirmed the payment by the time
/// `presentPaymentSheet()` returns without throwing; the only thing
/// still pending is the `customer.subscription.created` webhook that
/// flips the server-side state. Waiting on it would leave the UI
/// showing FREE for 200-1500 ms after a successful Apple Pay
/// confirmation — Jony Ive would rather die. The optimistic emit
/// followed by [ConfirmPremiumActivation] handles that gap invisibly.
class OptimisticPremiumActivated extends AuthEvent {
  OptimisticPremiumActivated();
}

/// Confirm an optimistic Premium activation against the server.
///
/// Fires `getCurrentUser()` with retry/backoff (500 ms → 2 s → 5 s) so
/// the local state catches up with the webhook within ~7.5 s of the
/// PaymentSheet success. If it never does (rare — webhook outage), we
/// keep the optimistic state and log; the user paid, after all.
class ConfirmPremiumActivation extends AuthEvent {
  ConfirmPremiumActivation();
}
