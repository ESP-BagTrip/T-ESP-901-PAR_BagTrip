import 'dart:developer' as developer;

import 'package:bagtrip/models/auth_response.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  bool _isLoginMode = true;

  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<AppleSignInRequested>(_onAppleSignInRequested);
    on<AuthModeChanged>(_onAuthModeChanged);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authResponse = await _authService.login(
        event.email,
        event.password,
      );
      emit(AuthSuccess(authResponse: authResponse));
    } catch (e) {
      emit(AuthError(errorMessage: e.toString(), isLoginMode: _isLoginMode));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authResponse = await _authService.register(
        event.email,
        event.password,
        event.fullName ?? 'User',
      );
      emit(AuthSuccess(authResponse: authResponse));
    } catch (e) {
      emit(AuthError(errorMessage: e.toString(), isLoginMode: _isLoginMode));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authResponse = await _authService.loginWithGoogle();
      emit(AuthSuccess(authResponse: authResponse));
    } catch (e, stackTrace) {
      developer.log('Google Sign-In Error: ${e.toString()}');
      developer.log('Stack trace: $stackTrace');

      String errorMessage = 'Google sign-in error';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }

      emit(AuthError(errorMessage: errorMessage, isLoginMode: _isLoginMode));
    }
  }

  Future<void> _onAppleSignInRequested(
    AppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authResponse = await _authService.loginWithApple();
      emit(AuthSuccess(authResponse: authResponse));
    } catch (e, stackTrace) {
      developer.log('Apple Sign-In Error: ${e.toString()}');
      developer.log('Stack trace: $stackTrace');

      String errorMessage = 'Apple sign-in error';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }

      emit(AuthError(errorMessage: errorMessage, isLoginMode: _isLoginMode));
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
}
