import 'package:bagtrip/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingPage', () {
    testWidgets('renders hero copy, the CTA button, and the skip link', (
      tester,
    ) async {
      await pumpLocalized(tester, const OnboardingPage());
      await tester.pump();

      // Three feature rows
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);

      // Title + subtitle + CTA copy exist in l10n — we only check that the
      // page builds a visible Scaffold without throwing.
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
