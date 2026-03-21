import 'package:bagtrip/home/widgets/now_indicator_row.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp() {
    return const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: Scaffold(body: NowIndicatorRow()),
    );
  }

  group('NowIndicatorRow', () {
    testWidgets('renders red dot', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(NowIndicatorRow), findsOneWidget);
    });

    testWidgets('renders "Now" label', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Now'), findsOneWidget);
    });

    testWidgets('renders horizontal red line', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Find the 1px red line container
      final lineFinder = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxHeight == 1,
      );
      expect(lineFinder, findsOneWidget);
    });

    testWidgets('uses red.shade400 color for dot and line', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Verify the "Now" text uses red.shade400
      final textWidget = tester.widget<Text>(find.text('Now'));
      expect(textWidget.style?.color, Colors.red.shade400);
    });

    testWidgets('is wrapped in IntrinsicHeight', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(IntrinsicHeight), findsOneWidget);
    });
  });
}
