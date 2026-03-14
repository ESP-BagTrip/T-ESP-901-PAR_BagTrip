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

  group('Auth integration flow', () {
    // ── Login -> AuthSuccess -> Logout -> AuthInitial ─────────────────

    blocTest<AuthBloc, AuthState>(
      'full login then logout flow',
      build: () {
        when(
          () => mockAuthRepo.login(any(), any()),
        ).thenAnswer((_) async => Success(makeAuthResponse()));
        when(
          () => mockAuthRepo.logout(),
        ).thenAnswer((_) async => const Success(null));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) async {
        bloc.add(LoginRequested(email: 'a@b.com', password: 'pass'));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(LogoutRequested());
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>(),
        isA<AuthLoading>(),
        isA<AuthInitial>(),
      ],
      verify: (_) {
        verify(() => mockAuthRepo.login('a@b.com', 'pass')).called(1);
        verify(() => mockAuthRepo.logout()).called(1);
      },
    );

    // ── Register -> AuthSuccess ───────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'register with all params succeeds',
      build: () {
        when(
          () => mockAuthRepo.register(any(), any(), any()),
        ).thenAnswer((_) async => Success(makeAuthResponse()));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(
        RegisterRequested(
          email: 'new@example.com',
          password: 'securePass',
          fullName: 'John Doe',
        ),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) {
        verify(
          () => mockAuthRepo.register(
            'new@example.com',
            'securePass',
            'John Doe',
          ),
        ).called(1);
      },
    );

    // ── Login failure -> mode change -> retry register success ────────

    blocTest<AuthBloc, AuthState>(
      'login fails, switch to register mode, register succeeds',
      build: () {
        when(() => mockAuthRepo.login(any(), any())).thenAnswer(
          (_) async =>
              const Failure(AuthenticationError('Invalid credentials')),
        );
        when(
          () => mockAuthRepo.register(any(), any(), any()),
        ).thenAnswer((_) async => Success(makeAuthResponse()));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) async {
        bloc.add(LoginRequested(email: 'a@b.com', password: 'bad'));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(AuthModeChanged(isLoginMode: false));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(
          RegisterRequested(
            email: 'a@b.com',
            password: 'pass',
            fullName: 'Name',
          ),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
        isA<AuthModeChangedState>(),
        isA<AuthLoading>(),
        isA<AuthSuccess>(),
      ],
      verify: (_) {
        verify(() => mockAuthRepo.login('a@b.com', 'bad')).called(1);
        verify(
          () => mockAuthRepo.register('a@b.com', 'pass', 'Name'),
        ).called(1);
      },
    );

    // ── Login failure preserves isLoginMode in AuthError ──────────────

    blocTest<AuthBloc, AuthState>(
      'login failure carries isLoginMode = true by default',
      build: () {
        when(
          () => mockAuthRepo.login(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('No connection')));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(LoginRequested(email: 'a@b.com', password: 'pw')),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
      verify: (bloc) {
        final state = bloc.state as AuthError;
        expect(state.isLoginMode, isTrue);
        expect(state.errorMessage, isNotEmpty);
      },
    );
  });
}
