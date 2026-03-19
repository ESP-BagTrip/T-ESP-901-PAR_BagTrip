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
    on<AuthModeChanged>(_onAuthModeChanged);
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
    emit(AuthLoading());
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
    emit(AuthLoading());
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
    emit(AuthLoading());
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
    emit(AuthLoading());
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

  void _onAuthModeChanged(AuthModeChanged event, Emitter<AuthState> emit) {
    _isLoginMode = event.isLoginMode;
    if (state is AuthInitial || state is AuthError) {
      emit(AuthModeChangedState(isLoginMode: event.isLoginMode));
    } else {
      emit(AuthModeChangedState(isLoginMode: event.isLoginMode));
    }
  }

  @override
  // ignore: unnecessary_overrides
  Future<void> close() {
    return super.close();
  }
}
