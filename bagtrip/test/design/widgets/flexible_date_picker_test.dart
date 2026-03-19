import 'package:bagtrip/design/widgets/flexible_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    DateMode mode = DateMode.exact,
    ValueChanged<DateMode>? onModeChanged,
    String? flexibilityLabel,
    ValueChanged<String>? onFlexibilityChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: FlexibleDatePicker(
            mode: mode,
            onModeChanged: onModeChanged ?? (_) {},
            flexibilityLabel: flexibilityLabel,
            onFlexibilityChanged: onFlexibilityChanged,
          ),
        ),
      ),
    );
  }

  group('FlexibleDatePicker', () {
    testWidgets('renders segment control with 3 modes', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Exact dates'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Flexible'), findsOneWidget);
    });

    testWidgets('exact mode shows date cards', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Date card labels (toUpperCase in _DateCard)
      expect(find.text('DEPART'), findsOneWidget);
      expect(find.text('RETURN'), findsOneWidget);
    });

    testWidgets('flexible mode shows flexibility chips', (tester) async {
      await tester.pumpWidget(buildApp(mode: DateMode.flexible));
      await tester.pumpAndSettle();

      expect(find.text('Whenever'), findsOneWidget);
      expect(find.text('Weekend'), findsOneWidget);
      expect(find.text('1 week'), findsOneWidget);
      expect(find.text('2 weeks'), findsOneWidget);
    });

    testWidgets('flexibility chip fires callback', (tester) async {
      String? selected;
      await tester.pumpWidget(
        buildApp(
          mode: DateMode.flexible,
          onFlexibilityChanged: (v) => selected = v,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weekend'));
      await tester.pump();

      expect(selected, 'Weekend');
    });

    testWidgets('mode change callback fires', (tester) async {
      DateMode? newMode;
      await tester.pumpWidget(buildApp(onModeChanged: (m) => newMode = m));
      await tester.pumpAndSettle();

      // Tap on "Month" segment
      await tester.tap(find.text('Month'));
      await tester.pump();

      expect(newMode, DateMode.month);
    });
  });
}
