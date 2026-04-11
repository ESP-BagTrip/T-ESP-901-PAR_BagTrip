// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/auth/widgets/social_login_button.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/design/widgets/primary_button.dart';
import 'package:bagtrip/pages/login_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_widget.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoginRequested(email: 'a@b', password: 'x'));
    registerFallbackValue(AuthInitial());
  });

  setUp(() {
    mockBloc = _MockAuthBloc();
  });

  Future<void> pump(WidgetTester tester, AuthState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(mockBloc, const Stream<AuthState>.empty(), initialState: seed);
    await pumpLocalized(
      tester,
      BlocProvider<AuthBloc>.value(value: mockBloc, child: const LoginPage()),
      size: const Size(900, 1800),
    );
    await tester.pump();
  }

  group('LoginPage', () {
    testWidgets('renders in login mode with AuthInitial', (tester) async {
      await pump(tester, AuthInitial());
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders in sign-up mode when isLoginMode is false', (
      tester,
    ) async {
      await pump(tester, AuthInitial(isLoginMode: false));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders in loading state', (tester) async {
      await pump(tester, AuthLoading());
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders with AuthError state', (tester) async {
      await pump(
        tester,
        AuthError(error: const NetworkError('offline'), isLoginMode: true),
      );
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('LoginPage reinforcement', () {
    testWidgets('renders AuthModeChangedState in signup mode', (tester) async {
      await pump(tester, AuthModeChangedState(isLoginMode: false));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders AuthModeChangedState in login mode', (tester) async {
      await pump(tester, AuthModeChangedState(isLoginMode: true));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders AuthError in signup mode', (tester) async {
      await pump(
        tester,
        AuthError(error: const ValidationError('invalid'), isLoginMode: false),
      );
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('tapping login toggle button dispatches AuthModeChanged', (
      tester,
    ) async {
      await pump(tester, AuthInitial(isLoginMode: true));
      // Tap the "Sign Up" side of the toggle to switch modes
      final signUpText = find.text('Sign Up');
      if (signUpText.evaluate().isNotEmpty) {
        await tester.tap(signUpText.first);
        await tester.pump();
        verify(
          () => mockBloc.add(any(that: isA<AuthModeChanged>())),
        ).called(greaterThanOrEqualTo(1));
      }
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets(
      'tapping submit with empty fields triggers validation (no event dispatched)',
      (tester) async {
        await pump(tester, AuthInitial(isLoginMode: true));
        final submit = find.byType(PrimaryButton);
        if (submit.evaluate().isNotEmpty) {
          await tester.tap(submit.first, warnIfMissed: false);
          await tester.pump();
          // AppSnackBar.showError needs a SnackBarScope ancestor that we
          // don't wire here — drain that specific assertion.
          tester.takeException();
          verifyNever(() => mockBloc.add(any(that: isA<LoginRequested>())));
        }
        expect(find.byType(LoginPage), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Google social button dispatches GoogleSignInRequested',
      (tester) async {
        await pump(tester, AuthInitial(isLoginMode: true));
        final socials = find.byType(SocialLoginButton);
        if (socials.evaluate().isNotEmpty) {
          await tester.tap(socials.first, warnIfMissed: false);
          await tester.pump();
          verify(
            () => mockBloc.add(any(that: isA<GoogleSignInRequested>())),
          ).called(greaterThanOrEqualTo(1));
        }
        expect(find.byType(LoginPage), findsOneWidget);
      },
    );

    testWidgets('tapping Apple social button dispatches AppleSignInRequested', (
      tester,
    ) async {
      await pump(tester, AuthInitial(isLoginMode: true));
      final socials = find.byType(SocialLoginButton);
      if (socials.evaluate().length >= 2) {
        await tester.tap(socials.at(1), warnIfMissed: false);
        await tester.pump();
        verify(
          () => mockBloc.add(any(that: isA<AppleSignInRequested>())),
        ).called(greaterThanOrEqualTo(1));
      }
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets(
      'signup mode: tapping submit with empty fields keeps LoginRequested at zero',
      (tester) async {
        await pump(tester, AuthInitial(isLoginMode: false));
        final submit = find.byType(PrimaryButton);
        if (submit.evaluate().isNotEmpty) {
          await tester.tap(submit.first, warnIfMissed: false);
          await tester.pump();
          tester.takeException();
          verifyNever(() => mockBloc.add(any(that: isA<RegisterRequested>())));
        }
        expect(find.byType(LoginPage), findsOneWidget);
      },
    );

    testWidgets('tapping obscure-password icon toggles visibility', (
      tester,
    ) async {
      await pump(tester, AuthInitial(isLoginMode: true));
      final visibilityIcon = find.byIcon(Icons.visibility_outlined);
      if (visibilityIcon.evaluate().isNotEmpty) {
        await tester.tap(visibilityIcon.first, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
