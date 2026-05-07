// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/budget/widgets/budget_item_form.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpForm(
    WidgetTester tester, {
    required void Function(Map<String, dynamic>) onSave,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BudgetItemForm(tripId: 'trip-1', onSave: onSave),
        ),
      ),
    );
    await tester.pump();
  }

  group('BudgetItemForm — Planned/Spent segmented control', () {
    testWidgets('starts on "Planned" with the planned helper text rendered', (
      tester,
    ) async {
      await pumpForm(tester, onSave: (_) {});

      // Default isPlanned == true, helper reflects that.
      expect(find.text('This expense will join the forecast.'), findsOneWidget);
      expect(find.text('This expense will join the actuals.'), findsNothing);
    });

    testWidgets(
      'tapping "Spent" flips the helper text and the segmented selection',
      (tester) async {
        await pumpForm(tester, onSave: (_) {});

        // The segmented button labels are the localized "Planned" / "Real"
        // strings — tap the Spent (Real) one.
        await tester.tap(find.text('Real'));
        await tester.pump();

        expect(
          find.text('This expense will join the actuals.'),
          findsOneWidget,
        );
        expect(find.text('This expense will join the forecast.'), findsNothing);
      },
    );

    testWidgets(
      'submitting persists the chosen isPlanned value into onSave payload',
      (tester) async {
        Map<String, dynamic>? captured;
        await pumpForm(tester, onSave: (data) => captured = data);

        // Switch to Spent.
        await tester.tap(find.text('Real'));
        await tester.pump();

        // The form's two text fields are Label (index 0) + Amount (index 1).
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'Cab fare');
        await tester.enterText(textFields.at(1), '42');

        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pump();

        expect(captured, isNotNull);
        expect(captured!['isPlanned'], false);
        expect(captured!['amount'], 42.0);
        expect(captured!['label'], 'Cab fare');
      },
    );
  });
}
