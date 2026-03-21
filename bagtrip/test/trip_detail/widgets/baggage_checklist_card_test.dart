import 'package:bagtrip/trip_detail/widgets/baggage_checklist_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

Widget _buildApp({required Widget child}) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('BaggageChecklistCard', () {
    testWidgets('renders name + category badge when category present', (
      tester,
    ) async {
      final item = makeBaggageItem(category: 'Documents');

      await tester.pumpWidget(
        _buildApp(
          child: BaggageChecklistCard(
            item: item,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Passport'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
    });

    testWidgets('renders "xN" quantity badge when quantity > 1', (
      tester,
    ) async {
      final item = makeBaggageItem(name: 'T-Shirt', quantity: 3);

      await tester.pumpWidget(
        _buildApp(
          child: BaggageChecklistCard(
            item: item,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('x3'), findsOneWidget);
    });

    testWidgets('checkbox filled with check icon when isPacked', (
      tester,
    ) async {
      final item = makeBaggageItem(name: 'Packed Item', isPacked: true);

      await tester.pumpWidget(
        _buildApp(
          child: BaggageChecklistCard(
            item: item,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('tap checkbox → calls onToggle callback', (tester) async {
      var toggled = false;
      final item = makeBaggageItem(name: 'Toggle Me');

      await tester.pumpWidget(
        _buildApp(
          child: BaggageChecklistCard(
            item: item,
            isOwner: true,
            isCompleted: false,
            onToggle: () => toggled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the checkbox (AnimatedContainer inside the leading GestureDetector)
      final checkbox = find.byWidgetPredicate(
        (w) => w is AnimatedContainer && w.constraints?.maxWidth == 28,
      );
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
    });

    testWidgets('Dismissible present when isOwner && !isCompleted', (
      tester,
    ) async {
      final item = makeBaggageItem(name: 'Deletable');

      await tester.pumpWidget(
        _buildApp(
          child: BaggageChecklistCard(
            item: item,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('no Dismissible when isCompleted', (tester) async {
      final item = makeBaggageItem(name: 'Non-deletable');

      await tester.pumpWidget(
        _buildApp(
          child: BaggageChecklistCard(
            item: item,
            isOwner: true,
            isCompleted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNothing);
    });
  });
}
