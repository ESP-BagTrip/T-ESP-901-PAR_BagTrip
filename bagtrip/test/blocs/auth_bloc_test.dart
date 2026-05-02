import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/crashlytics_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockCrashlyticsService mockCrashlyticsService;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockCrashlyticsService = MockCrashlyticsService();

    // Register mock CrashlyticsService used by AuthBloc
    if (getIt.isRegistered<CrashlyticsService>()) {
      getIt.unregister<CrashlyticsService>();
    }
    getIt.registerLazySingleton<CrashlyticsService>(
      () => mockCrashlyticsService,
    );

    // Register mock CacheService used by AuthBloc on logout
    if (getIt.isRegistered<CacheService>()) {
      getIt.unregister<CacheService>();
    }
    final mockCacheService = MockCacheService();
    getIt.registerLazySingleton<CacheService>(() => mockCacheService);
    when(() => mockCacheService.clearAll()).thenAnswer((_) async {});

    when(
      () => mockCrashlyticsService.setUserId(any()),
    ).thenAnswer((_) async {});
    when(() => mockCrashlyticsService.clearUserId()).thenAnswer((_) async {});
  });

  tearDown(() {
    if (getIt.isRegistered<CrashlyticsService>()) {
      getIt.unregister<CrashlyticsService>();
    }
    if (getIt.isRegistered<CacheService>()) {
      getIt.unregister<CacheService>();
    }
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

    // ── Phase C reinforcement: remaining branches ───────────────────────

    blocTest<AuthBloc, AuthState>(
      'login success calls CrashlyticsService.setUserId',
      build: () {
        when(
          () => mockAuthRepo.login(any(), any()),
        ).thenAnswer((_) async => Success(makeAuthResponse()));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(LoginRequested(email: 'a@b.com', password: 'pw')),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) {
        verify(
          () => mockCrashlyticsService.setUserId(any(that: isNotEmpty)),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'register failure emits AuthError',
      build: () {
        when(() => mockAuthRepo.register(any(), any(), any())).thenAnswer(
          (_) async => const Failure(ValidationError('email taken')),
        );
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) =>
          bloc.add(RegisterRequested(email: 'x@y.com', password: 'pw')),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );

    blocTest<AuthBloc, AuthState>(
      'Google sign-in success emits AuthSuccess',
      build: () {
        when(
          () => mockAuthRepo.loginWithGoogle(),
        ).thenAnswer((_) async => Success(makeAuthResponse()));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(GoogleSignInRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
    );

    blocTest<AuthBloc, AuthState>(
      'Google sign-in non-cancel failure emits AuthError',
      build: () {
        when(
          () => mockAuthRepo.loginWithGoogle(),
        ).thenAnswer((_) async => const Failure(ServerError('nope')));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(GoogleSignInRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );

    blocTest<AuthBloc, AuthState>(
      'Apple sign-in success emits AuthSuccess',
      build: () {
        when(
          () => mockAuthRepo.loginWithApple(),
        ).thenAnswer((_) async => Success(makeAuthResponse()));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(AppleSignInRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
    );

    blocTest<AuthBloc, AuthState>(
      'Apple sign-in non-cancel failure emits AuthError',
      build: () {
        when(
          () => mockAuthRepo.loginWithApple(),
        ).thenAnswer((_) async => const Failure(ServerError('nope')));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(AppleSignInRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );

    // ── DeleteAccountRequested ──────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'deleteAccount success triggers logout flow',
      build: () {
        when(
          () => mockAuthRepo.deleteAccount(),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => mockAuthRepo.logout(),
        ).thenAnswer((_) async => const Success(null));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(DeleteAccountRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
      verify: (_) {
        verify(() => mockAuthRepo.deleteAccount()).called(1);
        verify(() => mockAuthRepo.logout()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'deleteAccount failure emits AuthError',
      build: () {
        when(
          () => mockAuthRepo.deleteAccount(),
        ).thenAnswer((_) async => const Failure(ServerError('boom')));
        return AuthBloc(authRepository: mockAuthRepo);
      },
      act: (bloc) => bloc.add(DeleteAccountRequested()),
      expect: () => [isA<AuthError>()],
    );

    // ── UserRefreshRequested ────────────────────────────────────────────

    group('UserRefreshRequested', () {
      blocTest<AuthBloc, AuthState>(
        'while authenticated: re-emits AuthSuccess with the fresh user',
        build: () {
          when(
            () => mockAuthRepo.getCurrentUser(),
          ).thenAnswer((_) async => Success(makeUser(plan: 'PREMIUM')));
          return AuthBloc(authRepository: mockAuthRepo);
        },
        seed: () =>
            AuthSuccess(authResponse: makeAuthResponse(user: makeUser())),
        act: (bloc) => bloc.add(UserRefreshRequested()),
        expect: () => [
          predicate<AuthState>(
            (s) => s is AuthSuccess && s.authResponse.user.plan == 'PREMIUM',
            'AuthSuccess with refreshed plan',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'when not authenticated: no-op',
        build: () => AuthBloc(authRepository: mockAuthRepo),
        seed: () => AuthInitial(),
        act: (bloc) => bloc.add(UserRefreshRequested()),
        expect: () => <AuthState>[],
        verify: (_) {
          verifyNever(() => mockAuthRepo.getCurrentUser());
        },
      );

      blocTest<AuthBloc, AuthState>(
        'on AuthenticationError: logs out (drops to AuthInitial)',
        build: () {
          when(() => mockAuthRepo.getCurrentUser()).thenAnswer(
            (_) async => const Failure(AuthenticationError('expired')),
          );
          when(
            () => mockAuthRepo.logout(),
          ).thenAnswer((_) async => const Success(null));
          return AuthBloc(authRepository: mockAuthRepo);
        },
        seed: () =>
            AuthSuccess(authResponse: makeAuthResponse(user: makeUser())),
        act: (bloc) => bloc.add(UserRefreshRequested()),
        expect: () => [isA<AuthInitial>()],
        verify: (_) {
          verify(() => mockAuthRepo.logout()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'on transient network error: keeps the stale user (silent)',
        build: () {
          when(
            () => mockAuthRepo.getCurrentUser(),
          ).thenAnswer((_) async => const Failure(NetworkError('offline')));
          return AuthBloc(authRepository: mockAuthRepo);
        },
        seed: () =>
            AuthSuccess(authResponse: makeAuthResponse(user: makeUser())),
        act: (bloc) => bloc.add(UserRefreshRequested()),
        expect: () => <AuthState>[],
      );
    });

    // ── OptimisticPremiumActivated / ConfirmPremiumActivation ───────────

    group('OptimisticPremiumActivated', () {
      blocTest<AuthBloc, AuthState>(
        'flips plan to PREMIUM locally without hitting the network',
        build: () => AuthBloc(authRepository: mockAuthRepo),
        seed: () =>
            AuthSuccess(authResponse: makeAuthResponse(user: makeUser())),
        act: (bloc) => bloc.add(OptimisticPremiumActivated()),
        expect: () => [
          predicate<AuthState>(
            (s) => s is AuthSuccess && s.authResponse.user.plan == 'PREMIUM',
            'AuthSuccess with optimistic PREMIUM',
          ),
        ],
        verify: (_) {
          // No server call — the whole point of optimistic.
          verifyNever(() => mockAuthRepo.getCurrentUser());
        },
      );

      blocTest<AuthBloc, AuthState>(
        'no-op when user is already PREMIUM',
        build: () => AuthBloc(authRepository: mockAuthRepo),
        seed: () => AuthSuccess(
          authResponse: makeAuthResponse(user: makeUser(plan: 'PREMIUM')),
        ),
        act: (bloc) => bloc.add(OptimisticPremiumActivated()),
        expect: () => <AuthState>[],
      );

      blocTest<AuthBloc, AuthState>(
        'no-op when not authenticated',
        build: () => AuthBloc(authRepository: mockAuthRepo),
        seed: () => AuthInitial(),
        act: (bloc) => bloc.add(OptimisticPremiumActivated()),
        expect: () => <AuthState>[],
      );
    });

    group('ConfirmPremiumActivation', () {
      blocTest<AuthBloc, AuthState>(
        'first /auth/me already returns PREMIUM → emits once and stops',
        build: () {
          when(
            () => mockAuthRepo.getCurrentUser(),
          ).thenAnswer((_) async => Success(makeUser(plan: 'PREMIUM')));
          return AuthBloc(authRepository: mockAuthRepo);
        },
        seed: () => AuthSuccess(
          authResponse: makeAuthResponse(user: makeUser(plan: 'PREMIUM')),
        ),
        act: (bloc) => bloc.add(ConfirmPremiumActivation()),
        // Backoff: 500ms before first call. Wait long enough for one
        // attempt but short of the second (2s) so we observe a single
        // emission.
        wait: const Duration(milliseconds: 800),
        expect: () => [
          predicate<AuthState>(
            (s) => s is AuthSuccess && s.authResponse.user.plan == 'PREMIUM',
          ),
        ],
        verify: (_) {
          verify(() => mockAuthRepo.getCurrentUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'no-op when user logged out mid-confirmation',
        build: () => AuthBloc(authRepository: mockAuthRepo),
        seed: () => AuthInitial(),
        act: (bloc) => bloc.add(ConfirmPremiumActivation()),
        wait: const Duration(milliseconds: 800),
        expect: () => <AuthState>[],
        verify: (_) {
          verifyNever(() => mockAuthRepo.getCurrentUser());
        },
      );
    });
  });
}
