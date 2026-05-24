// Exercises the LoginPage AuthSuccess listener flow by injecting mocks
// for AuthRepository + PersonalizationStorage via the widget's new
// constructor parameters. Before phase F these dependencies were
// resolved through getIt, which made the success path unreachable in a
// hermetic test.

// ignore_for_file: avoid_redundant_argument_values, unnecessary_underscores

import 'dart:async';

import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/pages/login_page.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPersonalizationStorage extends Mock
    implements PersonalizationStorage {}

void main() {
  late _MockAuthBloc mockBloc;
  late _MockAuthRepository mockAuthRepo;
  late _MockPersonalizationStorage mockStorage;

  setUpAll(() {
    registerFallbackValue(LoginRequested(email: 'a@b', password: 'x'));
    registerFallbackValue(AuthInitial());
  });

  setUp(() {
    mockBloc = _MockAuthBloc();
    mockAuthRepo = _MockAuthRepository();
    mockStorage = _MockPersonalizationStorage();
  });

  /// Builds a minimal GoRouter tree where the login route hosts the
  /// LoginPage with injected dependencies. The listener delay is 100ms
  /// so tests advance the fake clock explicitly with `tester.pump`.
  Future<void> pumpRouterApp(
    WidgetTester tester,
    Stream<AuthState> stream, {
    required AuthState initialState,
  }) async {
    when(() => mockBloc.state).thenReturn(initialState);
    whenListen(mockBloc, stream, initialState: initialState);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => BlocProvider<AuthBloc>.value(
            value: mockBloc,
            child: LoginPage(
              authRepository: mockAuthRepo,
              personalizationStorage: mockStorage,
            ),
          ),
        ),
        GoRoute(path: '/home', builder: (_, __) => const Text('HOME')),
        GoRoute(
          path: '/personalization',
          builder: (_, __) => const Text('PERSONALIZATION'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
    await tester.pump();
  }

  /// Returns the Finder that asserts navigation landed at the given text.
  Finder findRouteLabel(String label) => find.text(label);

  group('LoginPage AuthSuccess listener (with injected dependencies)', () {
    testWidgets(
      'navigates to /home when user has already seen the personalization prompt',
      (tester) async {
        final controller = StreamController<AuthState>();

        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => Success(makeUser(id: 'user-1')));
        when(
          () => mockStorage.hasSeenPersonalizationPrompt('user-1'),
        ).thenAnswer((_) async => true);

        await pumpRouterApp(
          tester,
          controller.stream,
          initialState: AuthInitial(),
        );

        // Fire the AuthSuccess state through the bloc stream.
        controller.add(AuthSuccess(authResponse: makeAuthResponse()));
        await tester.pump();
        // The listener schedules a 100ms delayed callback before calling
        // getCurrentUser. Advance the fake clock past it.
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();

        verify(() => mockAuthRepo.getCurrentUser()).called(1);
        verify(
          () => mockStorage.hasSeenPersonalizationPrompt('user-1'),
        ).called(1);
        expect(findRouteLabel('HOME'), findsOneWidget);

        await controller.close();
      },
    );

    testWidgets(
      'navigates to /personalization when user has not seen the prompt',
      (tester) async {
        final controller = StreamController<AuthState>();

        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => Success(makeUser(id: 'user-1')));
        when(
          () => mockStorage.hasSeenPersonalizationPrompt('user-1'),
        ).thenAnswer((_) async => false);

        await pumpRouterApp(
          tester,
          controller.stream,
          initialState: AuthInitial(),
        );

        controller.add(AuthSuccess(authResponse: makeAuthResponse()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();

        expect(findRouteLabel('PERSONALIZATION'), findsOneWidget);
        await controller.close();
      },
    );

    testWidgets('falls back to /home when getCurrentUser returns no user', (
      tester,
    ) async {
      final controller = StreamController<AuthState>();

      when(
        () => mockAuthRepo.getCurrentUser(),
      ).thenAnswer((_) async => const Success(null));

      await pumpRouterApp(
        tester,
        controller.stream,
        initialState: AuthInitial(),
      );

      controller.add(AuthSuccess(authResponse: makeAuthResponse()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      expect(findRouteLabel('HOME'), findsOneWidget);
      verifyNever(() => mockStorage.hasSeenPersonalizationPrompt(any()));
      await controller.close();
    });

    testWidgets('falls back to /home when user id is empty (edge case)', (
      tester,
    ) async {
      final controller = StreamController<AuthState>();

      when(
        () => mockAuthRepo.getCurrentUser(),
      ).thenAnswer((_) async => Success(makeUser(id: '')));

      await pumpRouterApp(
        tester,
        controller.stream,
        initialState: AuthInitial(),
      );

      controller.add(AuthSuccess(authResponse: makeAuthResponse()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      expect(findRouteLabel('HOME'), findsOneWidget);
      verifyNever(() => mockStorage.hasSeenPersonalizationPrompt(any()));
      await controller.close();
    });

    testWidgets('falls back to /home when getCurrentUser fails', (
      tester,
    ) async {
      final controller = StreamController<AuthState>();

      when(
        () => mockAuthRepo.getCurrentUser(),
      ).thenAnswer((_) async => const Failure(NetworkError('offline')));

      await pumpRouterApp(
        tester,
        controller.stream,
        initialState: AuthInitial(),
      );

      controller.add(AuthSuccess(authResponse: makeAuthResponse()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      expect(findRouteLabel('HOME'), findsOneWidget);
      await controller.close();
    });
  });
}
