import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );
  }

  group('ErrorView', () {
    testWidgets('shows icon and message', (tester) async {
      await tester.pumpWidget(
        buildApp(child: const ErrorView(message: 'Something failed')),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something failed'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        buildApp(
          child: ErrorView(message: 'Error', onRetry: () => retried = true),
        ),
      );
      await tester.pumpAndSettle();

      // FilledButton.icon renders as a FilledButton subtype
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('no button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        buildApp(child: const ErrorView(message: 'Error')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('custom retryLabel and retryIcon', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: ErrorView(
            message: 'Error',
            onRetry: () {},
            retryLabel: 'Go back',
            retryIcon: Icons.arrow_back,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Go back'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
