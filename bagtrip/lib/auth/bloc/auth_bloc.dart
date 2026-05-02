import 'dart:developer' as developer;
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/auth_response.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/service/crashlytics_service.dart';
import 'package:bagtrip/repositories/notification_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  bool _isLoginMode = true;

  AuthBloc({AuthRepository? authRepository})
    : _authRepository = authRepository ?? getIt<AuthRepository>(),
      super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<AppleSignInRequested>(_onAppleSignInRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthModeChanged>(_onAuthModeChanged);
    on<UserRefreshRequested>(_onUserRefreshRequested);
    on<OptimisticPremiumActivated>(_onOptimisticPremiumActivated);
    on<ConfirmPremiumActivation>(_onConfirmPremiumActivation);
  }

  Future<void> _registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final platform = AdaptivePlatform.isIOS ? 'ios' : 'android';
        await getIt<NotificationRepository>().registerDeviceToken(
          token,
          platform: platform,
        );
      }
    } catch (e) {
      developer.log('FCM token registration failed: $e');
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(method: AuthMethod.email));
    final result = await _authRepository.login(event.email, event.password);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        getIt<CrashlyticsService>().setUserId(data.user.id);
        emit(AuthSuccess(authResponse: data));
        _registerDeviceToken();
      case Failure(:final error):
        emit(AuthError(error: error, isLoginMode: _isLoginMode));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(method: AuthMethod.email));
    final result = await _authRepository.register(
      event.email,
      event.password,
      event.fullName ?? 'User',
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        getIt<CrashlyticsService>().setUserId(data.user.id);
        emit(AuthSuccess(authResponse: data));
        _registerDeviceToken();
      case Failure(:final error):
        emit(AuthError(error: error, isLoginMode: _isLoginMode));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(method: AuthMethod.google));
    final result = await _authRepository.loginWithGoogle();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        getIt<CrashlyticsService>().setUserId(data.user.id);
        emit(AuthSuccess(authResponse: data));
        _registerDeviceToken();
      case Failure(:final error):
        if (error is CancelledError) {
          emit(AuthInitial(isLoginMode: _isLoginMode));
        } else {
          emit(AuthError(error: error, isLoginMode: _isLoginMode));
        }
    }
  }

  Future<void> _onAppleSignInRequested(
    AppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(method: AuthMethod.apple));
    final result = await _authRepository.loginWithApple();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        getIt<CrashlyticsService>().setUserId(data.user.id);
        emit(AuthSuccess(authResponse: data));
        _registerDeviceToken();
      case Failure(:final error):
        if (error is CancelledError) {
          emit(AuthInitial(isLoginMode: _isLoginMode));
        } else {
          emit(AuthError(error: error, isLoginMode: _isLoginMode));
        }
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    getIt<CrashlyticsService>().clearUserId();
    await _authRepository.logout();
    await getIt<CacheService>().clearAll();
    if (isClosed) return;
    emit(AuthInitial());
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _authRepository.deleteAccount();
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LogoutRequested());
      case Failure(:final error):
        emit(AuthError(error: error, isLoginMode: _isLoginMode));
    }
  }

  void _onAuthModeChanged(AuthModeChanged event, Emitter<AuthState> emit) {
    _isLoginMode = event.isLoginMode;
    if (state is AuthInitial || state is AuthError) {
      emit(AuthModeChangedState(isLoginMode: event.isLoginMode));
    } else {
      emit(AuthModeChangedState(isLoginMode: event.isLoginMode));
    }
  }

  /// Re-fetch the user and re-emit [AuthSuccess] with the fresh copy.
  ///
  /// Best-effort: a failure here doesn't kick the user out (a transient
  /// network error shouldn't undo a paid-in-full subscription locally).
  /// Auth errors *do* propagate so a 401 still drops to [AuthInitial].
  Future<void> _onUserRefreshRequested(
    UserRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthSuccess) return;
    final result = await _authRepository.getCurrentUser();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        if (data == null) return;
        emit(
          AuthSuccess(authResponse: current.authResponse.copyWith(user: data)),
        );
      case Failure(:final error):
        if (error is AuthenticationError) {
          await _authRepository.logout();
          if (isClosed) return;
          emit(AuthInitial(isLoginMode: _isLoginMode));
        }
      // Other errors: silently keep the stale user — refresh will retry
      // on the next opportunity (next paid action, next app resume).
    }
  }

  /// Optimistically flip `user.plan` to PREMIUM without touching the server.
  ///
  /// Called from the paywall the moment the PaymentSheet returns
  /// success — the gate is lifted instantly so the user can keep doing
  /// what they were doing. [ConfirmPremiumActivation] reconciles with
  /// the server in the background.
  Future<void> _onOptimisticPremiumActivated(
    OptimisticPremiumActivated event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthSuccess) return;
    if (current.authResponse.user.isPremium) return;
    emit(
      AuthSuccess(
        authResponse: current.authResponse.copyWith(
          user: current.authResponse.user.copyWith(plan: 'PREMIUM'),
        ),
      ),
    );
  }

  /// Reconcile the optimistic Premium state with the server.
  ///
  /// Retries `/auth/me` at 500 ms → 2 s → 5 s after the optimistic
  /// flip so the local state catches up with the
  /// `customer.subscription.created` webhook. Stops as soon as the
  /// server confirms PREMIUM. If it never does (very rare), we keep
  /// the optimistic state — the user paid; rolling back to FREE would
  /// be more wrong than living with a brief mismatch until the next
  /// natural refresh.
  Future<void> _onConfirmPremiumActivation(
    ConfirmPremiumActivation event,
    Emitter<AuthState> emit,
  ) async {
    const delays = [
      Duration(milliseconds: 500),
      Duration(seconds: 2),
      Duration(seconds: 5),
    ];
    for (final delay in delays) {
      await Future<void>.delayed(delay);
      if (isClosed) return;
      final current = state;
      if (current is! AuthSuccess) return;
      final result = await _authRepository.getCurrentUser();
      if (isClosed) return;
      if (result case Success(:final data) when data != null) {
        // Replace optimistic state with the server's truth — preserves
        // every other field (memberSince, profileCompleted, etc.) that
        // may have been touched by webhook side-effects.
        emit(
          AuthSuccess(authResponse: current.authResponse.copyWith(user: data)),
        );
        if (data.isPremium) return; // server confirmed — done.
      }
      // Auth errors handled by the regular UserRefreshRequested handler;
      // here we just keep retrying until we hit the timeout or confirm.
    }
  }
}
