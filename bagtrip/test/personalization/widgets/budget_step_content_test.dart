import 'package:bagtrip/personalization/widgets/budget_step_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('BudgetStepContent', () {
    testWidgets('renders with null selection', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1600,
          child: BudgetStepContent(selectedId: null, onSelect: (_) {}),
        ),
      );
      await tester.pump();
      expect(find.byType(BudgetStepContent), findsOneWidget);
    });

    testWidgets('renders with comfort selected', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1600,
          child: BudgetStepContent(selectedId: 'comfort', onSelect: (_) {}),
        ),
      );
      await tester.pump();
      expect(find.byType(BudgetStepContent), findsOneWidget);
    });

    testWidgets('renders with luxury selected', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1600,
          child: BudgetStepContent(selectedId: 'luxury', onSelect: (_) {}),
        ),
      );
      await tester.pump();
      expect(find.byType(BudgetStepContent), findsOneWidget);
    });
  });
}
