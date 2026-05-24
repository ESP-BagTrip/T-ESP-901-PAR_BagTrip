import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/pages/not_found_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({Locale locale = const Locale('en')}) {
    return MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: const NotFoundPage(),
    );
  }

  group('NotFoundPage', () {
    testWidgets('renders ElegantEmptyState with correct EN texts', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(ElegantEmptyState), findsOneWidget);
      expect(find.text('Page not found'), findsOneWidget);
      expect(
        find.text(
          "The page you are looking for doesn't exist or has been moved.",
        ),
        findsOneWidget,
      );
      expect(find.text('Return home'), findsOneWidget);
      expect(find.byIcon(Icons.explore_off_rounded), findsOneWidget);
    });

    testWidgets('renders correct FR texts', (tester) async {
      await tester.pumpWidget(buildApp(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      expect(find.text('Page introuvable'), findsOneWidget);
      expect(
        find.text(
          "La page que vous recherchez n'existe pas ou a été déplacée.",
        ),
        findsOneWidget,
      );
      expect(find.text("Retour à l'accueil"), findsOneWidget);
    });
  });
}
