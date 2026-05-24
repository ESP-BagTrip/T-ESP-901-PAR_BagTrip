// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/components/snack_bar_scope.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/profile/widgets/email_verification_banner.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';

class _MockUserProfileBloc extends MockBloc<UserProfileEvent, UserProfileState>
    implements UserProfileBloc {}

UserProfileLoaded _loaded({required bool emailVerified}) => UserProfileLoaded(
  name: 'Alice',
  email: 'alice@example.com',
  phone: '—',
  memberSince: DateTime(2024),
  emailVerified: emailVerified,
);

void main() {
  late _MockUserProfileBloc mockBloc;
  late MockAuthRepository mockAuth;

  setUpAll(() {
    registerFallbackValue(LoadUserProfile());
  });

  setUp(() {
    mockBloc = _MockUserProfileBloc();
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

  Future<void> pump(WidgetTester tester, UserProfileState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<UserProfileState>.empty(),
      initialState: seed,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: SnackBarScope(
          child: Scaffold(
            body: BlocProvider<UserProfileBloc>.value(
              value: mockBloc,
              child: const EmailVerificationBanner(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the banner when the user is not verified', (
    tester,
  ) async {
    await pump(tester, _loaded(emailVerified: false));

    expect(
      find.text('Verify your email address to secure your account.'),
      findsOneWidget,
    );
    expect(find.text('Resend'), findsOneWidget);
  });

  testWidgets('hides the banner when the user is verified', (tester) async {
    await pump(tester, _loaded(emailVerified: true));

    expect(find.byType(SizedBox), findsWidgets);
    expect(find.text('Resend'), findsNothing);
  });

  testWidgets('hides the banner before the profile resolves', (tester) async {
    await pump(tester, UserProfileLoading());

    expect(find.text('Resend'), findsNothing);
  });

  testWidgets('tapping Resend calls resendVerification and shows success', (
    tester,
  ) async {
    when(
      () => mockAuth.resendVerification(),
    ).thenAnswer((_) async => const Success(null));

    await pump(tester, _loaded(emailVerified: false));

    await tester.tap(find.text('Resend'));
    await tester.pump();

    verify(() => mockAuth.resendVerification()).called(1);
    await tester.pump();
    expect(
      find.text('Verification email sent. Check your inbox.'),
      findsOneWidget,
    );

    // Drain the toast's auto-dismiss timer + reverse animation so no timer
    // is left pending at teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('tapping Resend surfaces an error toast on failure', (
    tester,
  ) async {
    when(
      () => mockAuth.resendVerification(),
    ).thenAnswer((_) async => const Failure(NetworkError('offline')));

    await pump(tester, _loaded(emailVerified: false));

    await tester.tap(find.text('Resend'));
    await tester.pump();
    await tester.pump();

    verify(() => mockAuth.resendVerification()).called(1);
    expect(
      find.text('Connection error. Check your internet connection.'),
      findsOneWidget,
    );

    // Drain the toast's auto-dismiss timer + reverse animation.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
