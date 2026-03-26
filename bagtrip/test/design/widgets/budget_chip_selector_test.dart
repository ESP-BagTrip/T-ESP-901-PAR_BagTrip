import 'package:bagtrip/design/widgets/budget_chip_selector.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testOptions = [
    BudgetOption(label: 'Budget', emoji: '\u{1F4B0}', range: '0 - 500 \u20AC'),
    BudgetOption(
      label: 'Medium',
      emoji: '\u{1F4B3}',
      range: '500 - 1500 \u20AC',
    ),
    BudgetOption(
      label: 'Premium',
      emoji: '\u{1F48E}',
      range: '1500 - 3000 \u20AC',
    ),
    BudgetOption(label: 'Luxury', emoji: '\u{1F451}', range: '3000+ \u20AC'),
  ];

  Widget buildApp({int? selectedIndex, ValueChanged<int>? onSelected}) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BudgetChipSelector(
            options: testOptions,
            selectedIndex: selectedIndex,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('BudgetChipSelector', () {
    testWidgets('renders all 4 chips', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('Luxury'), findsOneWidget);

      expect(find.text('0 - 500 \u20AC'), findsOneWidget);
      expect(find.text('500 - 1500 \u20AC'), findsOneWidget);
      expect(find.text('1500 - 3000 \u20AC'), findsOneWidget);
      expect(find.text('3000+ \u20AC'), findsOneWidget);
    });

    testWidgets('selection callback fires with correct index', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        buildApp(onSelected: (index) => tappedIndex = index),
      );

      await tester.tap(find.text('Premium'));
      expect(tappedIndex, 2);

      await tester.tap(find.text('Budget'));
      expect(tappedIndex, 0);

      await tester.tap(find.text('Luxury'));
      expect(tappedIndex, 3);
    });

    testWidgets('selected chip has different decoration', (tester) async {
      await tester.pumpWidget(buildApp(selectedIndex: 1));
      await tester.pumpAndSettle();

      // Find all AnimatedContainer widgets used as chip containers.
      final animatedContainers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();

      expect(animatedContainers.length, 4);

      // The selected chip (index 1) should have primaryLight background.
      final selectedDecoration =
          animatedContainers[1].decoration! as BoxDecoration;
      expect(selectedDecoration.color, ColorName.primaryLight);
      expect(
        selectedDecoration.border,
        isA<Border>().having((b) => b.top.width, 'border width', 2),
      );
      expect(selectedDecoration.boxShadow, isNotNull);
      expect(selectedDecoration.boxShadow, isNotEmpty);

      // An unselected chip (index 0) should have surface background.
      final unselectedDecoration =
          animatedContainers[0].decoration! as BoxDecoration;
      expect(unselectedDecoration.color, ColorName.surface);
      expect(
        unselectedDecoration.border,
        isA<Border>().having((b) => b.top.width, 'border width', 1),
      );
      expect(unselectedDecoration.boxShadow, isNull);
    });
  });
}
