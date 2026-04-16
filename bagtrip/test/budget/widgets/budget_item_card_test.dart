import 'package:bagtrip/budget/widgets/budget_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('BudgetItemCard', () {
    testWidgets('renders item with edit/delete callbacks', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 200,
          child: BudgetItemCard(
            item: makeBudgetItem(),
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(BudgetItemCard), findsOneWidget);
    });

    testWidgets('renders in viewer mode', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 200,
          child: BudgetItemCard(item: makeBudgetItem(), isViewer: true),
        ),
      );
      await tester.pump();
      expect(find.byType(BudgetItemCard), findsOneWidget);
    });

    testWidgets('renders without callbacks', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 200,
          child: BudgetItemCard(item: makeBudgetItem()),
        ),
      );
      await tester.pump();
      expect(find.byType(BudgetItemCard), findsOneWidget);
    });
  });
}
