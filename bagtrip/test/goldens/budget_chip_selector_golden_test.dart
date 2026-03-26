@Tags(['golden'])
library;

import 'package:bagtrip/design/widgets/budget_chip_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

const _options = [
  BudgetOption(label: 'Backpacker', emoji: '🎒', range: '< 500€'),
  BudgetOption(label: 'Comfortable', emoji: '😊', range: '500-1500€'),
  BudgetOption(label: 'Premium', emoji: '✨', range: '1500-3000€'),
  BudgetOption(label: 'Luxury', emoji: '👑', range: '3000€+'),
];

void main() {
  group('BudgetChipSelector goldens', () {
    testWidgets('no selection', (tester) async {
      await setGoldenSize(tester);
      await tester.pumpWidget(
        goldenWrapper(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BudgetChipSelector(
              options: _options,
              selectedIndex: null,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BudgetChipSelector),
        matchesGoldenFile('goldens/budget_chip_selector_none.png'),
      );
    });

    testWidgets('second option selected', (tester) async {
      await setGoldenSize(tester);
      await tester.pumpWidget(
        goldenWrapper(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BudgetChipSelector(
              options: _options,
              selectedIndex: 1,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BudgetChipSelector),
        matchesGoldenFile('goldens/budget_chip_selector_selected.png'),
      );
    });
  });
}
