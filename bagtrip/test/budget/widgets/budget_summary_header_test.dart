import 'package:bagtrip/budget/widgets/budget_summary_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('BudgetSummaryHeader', () {
    testWidgets('renders with default summary', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 400,
          child: BudgetSummaryHeader(summary: makeBudgetSummary()),
        ),
      );
      await tester.pump();
      expect(find.byType(BudgetSummaryHeader), findsOneWidget);
    });

    testWidgets('renders with zero total budget', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 400,
          child: BudgetSummaryHeader(
            summary: makeBudgetSummary(
              totalBudget: 0,
              totalSpent: 0,
              remaining: 0,
              confirmedTotal: 0,
              forecastedTotal: 0,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(BudgetSummaryHeader), findsOneWidget);
    });

    testWidgets('renders in viewer mode with percent consumed', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 400,
          child: BudgetSummaryHeader(
            summary: makeBudgetSummary(percentConsumed: 75),
            isViewer: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(BudgetSummaryHeader), findsOneWidget);
    });
  });
}
