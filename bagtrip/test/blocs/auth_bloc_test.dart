import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  group('AuthBloc', () {
    // ── LoginRequested ──────────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when login succeeds',
      build: () {
        when(
          () => mockAuthRepo.login(any(), any()),
        ).thenAnswer((_) async => Success(makeAuthResponse()));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) =>
          bloc.add(LoginRequested(email: 'test@example.com', password: 'pw')),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) {
        verify(() => mockAuthRepo.login('test@example.com', 'pw')).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(
          () => mockAuthRepo.login(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) =>
          bloc.add(LoginRequested(email: 'test@example.com', password: 'pw')),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );

    // ── RegisterRequested ───────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when register succeeds, fullName defaults to User',
      build: () {
        when(
          () => mockAuthRepo.register(any(), any(), any()),
        ).thenAnswer((_) async => Success(makeAuthResponse()));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) =>
          bloc.add(RegisterRequested(email: 'new@example.com', password: 'pw')),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) {
        // fullName is null on the event, so the BLoC passes 'User'
        verify(
          () => mockAuthRepo.register('new@example.com', 'pw', 'User'),
        ).called(1);
      },
    );

    // ── GoogleSignInRequested ───────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthInitial] when Google sign-in is cancelled',
      build: () {
        when(
          () => mockAuthRepo.loginWithGoogle(),
        ).thenAnswer((_) async => const Failure(CancelledError('cancelled')));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(GoogleSignInRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
    );

    // ── AppleSignInRequested ────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthInitial] when Apple sign-in is cancelled',
      build: () {
        when(
          () => mockAuthRepo.loginWithApple(),
        ).thenAnswer((_) async => const Failure(CancelledError('cancelled')));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(AppleSignInRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
    );

    // ── LogoutRequested ─────────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthInitial] on logout',
      build: () {
        when(
          () => mockAuthRepo.logout(),
        ).thenAnswer((_) async => const Success(null));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(LogoutRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
      verify: (_) {
        verify(() => mockAuthRepo.logout()).called(1);
      },
    );

    // ── AuthModeChanged ─────────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'emits [AuthModeChangedState(isLoginMode: false)] when mode is toggled',
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(AuthModeChanged(isLoginMode: false)),
      expect: () => [isA<AuthModeChangedState>()],
      verify: (bloc) {
        final emitted = bloc.state;
        expect(emitted, isA<AuthModeChangedState>());
        expect((emitted as AuthModeChangedState).isLoginMode, isFalse);
      },
    );
  });
}
