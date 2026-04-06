import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/models/inspiration_destination.dart';
import 'package:bagtrip/home/view/onboarding_home_view.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  Widget buildApp({String? fullName = 'Test User'}) {
    final user = makeUser(fullName: fullName);
    final state = HomeNewUser(user: user);

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: OnboardingHomeView(state: state)),
    );
  }

  group('OnboardingHomeView', () {
    testWidgets('CTA is visible with correct text', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Create my first trip'), findsOneWidget);
    });

    testWidgets('displays inspiration cards', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // First cards are visible in the horizontal scroll
      expect(find.text('Tokyo'), findsOneWidget);
      expect(find.text('Barcelona'), findsOneWidget);
      expect(find.text('Marrakech'), findsOneWidget);
    });

    testWidgets('greeting includes user name', (tester) async {
      await tester.pumpWidget(buildApp(fullName: 'Alice Smith'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome, Alice'), findsOneWidget);
    });

    testWidgets('greeting fallback when no name', (tester) async {
      await tester.pumpWidget(buildApp(fullName: null));
      await tester.pumpAndSettle();

      expect(find.text('Ready to travel?'), findsOneWidget);
    });

    testWidgets('section header "Get inspired" is visible', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('GET INSPIRED'), findsOneWidget);
    });

    testWidgets('inspiration cards have correct total count', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(InspirationDestination.all.length, equals(6));
    });

    testWidgets('displays welcome subtitle', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Create your first trip in a few steps. '
          'Manual or AI-assisted — your choice.',
        ),
        findsOneWidget,
      );
    });
  });
}
