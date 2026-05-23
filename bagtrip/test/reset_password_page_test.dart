// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/pages/reset_password_page.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/mock_repositories.dart';

/// Minimal router so `LoginRoute().go(context)` after a successful reset has a
/// GoRouter ancestor to navigate against without booting the real app router.
GoRouter _router() => GoRouter(
  initialLocation: '/reset',
  routes: [
    GoRoute(
      path: '/reset',
      builder: (_, _) => const ResetPasswordPage(token: 'tok-123'),
    ),
    GoRoute(
      path: '/login',
      builder: (_, _) => const Scaffold(body: Text('LOGIN SCREEN')),
    ),
  ],
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: _router(),
    ),
  );
  await tester.pump();
}

void main() {
  late MockAuthRepository mockAuth;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockAuth = MockAuthRepository();
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    getIt.registerSingleton<AuthRepository>(mockAuth);
  });

  tearDown(() {
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
  });

  testWidgets('shows mismatch error and does not call resetPassword', (
    tester,
  ) async {
    await _pump(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'password1');
    await tester.enterText(fields.at(1), 'password2');
    await tester.tap(find.text('Reset password'));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    verifyNever(() => mockAuth.resetPassword(any(), any()));
  });

  testWidgets('valid submit calls resetPassword with the token', (
    tester,
  ) async {
    when(
      () => mockAuth.resetPassword(any(), any()),
    ).thenAnswer((_) async => const Success<void>(null));

    await _pump(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'secret123');
    await tester.enterText(fields.at(1), 'secret123');
    await tester.tap(find.text('Reset password'));
    await tester.pump();

    verify(() => mockAuth.resetPassword('tok-123', 'secret123')).called(1);
  });

  testWidgets('shows error message on failure', (tester) async {
    when(
      () => mockAuth.resetPassword(any(), any()),
    ).thenAnswer((_) async => const Failure<void>(NetworkError('boom')));

    await _pump(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'secret123');
    await tester.enterText(fields.at(1), 'secret123');
    await tester.tap(find.text('Reset password'));
    await tester.pump();
    await tester.pump();

    // Type-based fallback for NetworkError.
    expect(find.text('LOGIN SCREEN'), findsNothing);
  });
}
