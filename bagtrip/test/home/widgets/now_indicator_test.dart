import 'package:bagtrip/home/widgets/now_indicator_row.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matches [NowIndicatorRow] accent (timeline "now" marker).
const Color _nowAccent = Color(0xFF34B7A4);

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
    testWidgets('renders now accent dot', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(NowIndicatorRow), findsOneWidget);
    });

    testWidgets('renders "Now" label', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Now'), findsOneWidget);
    });

    testWidgets('renders horizontal now line', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Find the 1px line container
      final lineFinder = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxHeight == 1,
      );
      expect(lineFinder, findsOneWidget);
    });

    testWidgets('uses now accent color for dot, line, and label', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Now'));
      expect(textWidget.style?.color, _nowAccent);

      final lineFinder = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxHeight == 1 &&
            w.color == _nowAccent.withValues(alpha: 0.35),
      );
      expect(lineFinder, findsOneWidget);

      final dotFinder = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == 8 &&
            w.constraints?.maxHeight == 8 &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == _nowAccent,
      );
      expect(dotFinder, findsOneWidget);
    });

    testWidgets('is wrapped in IntrinsicHeight', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(IntrinsicHeight), findsOneWidget);
    });
  });
}
