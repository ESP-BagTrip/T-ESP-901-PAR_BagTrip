import 'package:bagtrip/budget/widgets/budget_item_form.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

Widget _buildApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('BudgetItemForm', () {
    testWidgets('renders "Add expense" title for new expense', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: BudgetItemForm(tripId: 'trip-1', onSave: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add expense'), findsOneWidget);
    });

    testWidgets('renders "Edit expense" title in edit mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: BudgetItemForm(
            tripId: 'trip-1',
            item: makeBudgetItem(),
            onSave: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit expense'), findsOneWidget);
    });

    testWidgets('displays all 6 category chips', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: BudgetItemForm(tripId: 'trip-1', onSave: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flights'), findsOneWidget);
      expect(find.text('Accommodation'), findsOneWidget);
      expect(find.text('Meals'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('category chip is selectable', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: BudgetItemForm(tripId: 'trip-1', onSave: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flights'));
      await tester.pumpAndSettle();

      // The Flights chip should now be selected
      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('Flights'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('empty label shows validation error', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: BudgetItemForm(tripId: 'trip-1', onSave: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Tap save without filling label
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Label is required'), findsOneWidget);
    });

    testWidgets('empty amount shows validation error', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: BudgetItemForm(tripId: 'trip-1', onSave: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Fill label but not amount
      await tester.enterText(find.byType(TextFormField).first, 'Hotel');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('onSave receives correct data on valid submission', (
      tester,
    ) async {
      Map<String, dynamic>? savedData;

      await tester.pumpWidget(
        _buildApp(
          child: BudgetItemForm(
            tripId: 'trip-1',
            onSave: (data) => savedData = data,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill label
      await tester.enterText(find.byType(TextFormField).first, 'Hotel');
      // Fill amount
      await tester.enterText(find.byType(TextFormField).at(1), '120.50');
      // Select category
      await tester.tap(find.text('Accommodation'));
      await tester.pumpAndSettle();
      // Submit
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedData, isNotNull);
      expect(savedData!['label'], 'Hotel');
      expect(savedData!['amount'], 120.50);
      expect(savedData!['category'], 'ACCOMMODATION');
      expect(savedData!['isPlanned'], true);
    });

    testWidgets('planned/real toggle works', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: BudgetItemForm(tripId: 'trip-1', onSave: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Planned should be selected by default
      final plannedChip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('Planned'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(plannedChip.selected, isTrue);

      // Tap Real
      await tester.tap(find.text('Real'));
      await tester.pumpAndSettle();

      final realChip = tester.widget<ChoiceChip>(
        find.ancestor(of: find.text('Real'), matching: find.byType(ChoiceChip)),
      );
      expect(realChip.selected, isTrue);
    });
  });
}
