import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bagtrip/model/user.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/google_signin.dart';
import 'package:bagtrip/service/apple_signin.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthAppStarted extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthSignupRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignupRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthGoogleLoginRequested extends AuthEvent {}

class AuthAppleLoginRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final GoogleSigninService _googleSigninService = GoogleSigninService();
  final AppleSigninService _appleSigninService = AppleSigninService();

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthAppleLoginRequested>(_onAppleLoginRequested);
  }

  Future<void> _onAppStarted(
      AuthAppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.me();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.login(event.email, event.password);
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSignupRequested(
      AuthSignupRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signup(event.email, event.password);
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Signup failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authService.logout();
    await _googleSigninService.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onGoogleLoginRequested(
      AuthGoogleLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Logic for Google Sign In
      try {
        final googleUser = await _googleSigninService.signIn();
        if (googleUser != null) {
          emit(const AuthError("Google Sign-In requires backend configuration (firebase/google-services.json)"));
        } else {
          emit(AuthUnauthenticated()); // Canceled
        }
      } catch (e) {
         emit(AuthError("Google Sign-In failed: $e (Missing google-services.json?)"));
      }

    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAppleLoginRequested(
      AuthAppleLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
        await _appleSigninService.signIn();
        // emit(AuthAuthenticated(...)
    } catch (e) {
      emit(const AuthError("Apple Sign-In not configured."));
    }
  }
}
