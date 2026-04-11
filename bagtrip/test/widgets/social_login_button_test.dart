import 'package:bagtrip/auth/widgets/social_login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('SocialLoginButton', () {
    testWidgets('renders Google provider with icon + label', (tester) async {
      await pumpLocalized(
        tester,
        SocialLoginButton(provider: SocialProvider.google, onPressed: () {}),
      );
      await tester.pump();
      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('renders Apple provider with dark style', (tester) async {
      await pumpLocalized(
        tester,
        SocialLoginButton(
          provider: SocialProvider.apple,
          useDarkStyle: true,
          onPressed: () {},
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.apple), findsOneWidget);
    });

    testWidgets('renders custom label when provided', (tester) async {
      await pumpLocalized(
        tester,
        SocialLoginButton(
          provider: SocialProvider.google,
          label: 'Continue with Google',
          onPressed: () {},
        ),
      );
      await tester.pump();
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows spinner when isLoading is true', (tester) async {
      await pumpLocalized(
        tester,
        SocialLoginButton(
          provider: SocialProvider.google,
          isLoading: true,
          onPressed: () {},
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('button is disabled when onPressed is null', (tester) async {
      await pumpLocalized(
        tester,
        const SocialLoginButton(provider: SocialProvider.google),
      );
      await tester.pump();
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });
  });
}
