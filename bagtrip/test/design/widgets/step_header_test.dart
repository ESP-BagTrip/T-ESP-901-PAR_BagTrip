import 'package:bagtrip/design/widgets/step_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testItems = [
    StepSummaryItem(
      icon: Icons.location_on,
      label: 'Destination',
      value: 'Paris',
    ),
    StepSummaryItem(
      icon: Icons.calendar_today,
      label: 'Dates',
      value: 'Mar 20 - Mar 25',
    ),
    StepSummaryItem(icon: Icons.group, label: 'Travelers', value: '3 people'),
  ];

  Widget buildApp({
    List<StepSummaryItem> items = testItems,
    bool initiallyExpanded = false,
    VoidCallback? onToggle,
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          body: StepHeader(
            items: items,
            initiallyExpanded: initiallyExpanded,
            onToggle: onToggle,
          ),
        ),
      ),
    );
  }

  group('StepHeader', () {
    testWidgets('renders with items in collapsed state', (tester) async {
      await tester.pumpWidget(buildApp());

      // AnimatedCrossFade renders both children; values appear in both views.
      // Verify values exist at least once.
      expect(find.text('Paris'), findsAtLeastNWidgets(1));
      expect(find.text('Mar 20 - Mar 25'), findsAtLeastNWidgets(1));
      expect(find.text('3 people'), findsAtLeastNWidgets(1));

      // Icons are present
      expect(find.byIcon(Icons.location_on), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.calendar_today), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.group), findsAtLeastNWidgets(1));

      // Collapsed shows the down-arrow chevron prominently
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('toggle expand on tap calls onToggle', (tester) async {
      var toggleCount = 0;
      await tester.pumpWidget(buildApp(onToggle: () => toggleCount++));

      // Initially collapsed — down arrow visible
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

      // Tap to expand
      await tester.tap(find.byType(StepHeader));
      await tester.pumpAndSettle();

      // After expand — up arrow now visible, labels appear
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.text('DESTINATION'), findsAtLeastNWidgets(1));
      expect(find.text('DATES'), findsAtLeastNWidgets(1));
      expect(find.text('TRAVELERS'), findsAtLeastNWidgets(1));
      expect(toggleCount, 1);

      // Tap to collapse
      await tester.tap(find.byType(StepHeader));
      await tester.pumpAndSettle();

      // Back to collapsed — down arrow visible again
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(toggleCount, 2);
    });

    testWidgets('shows correct values in expanded state', (tester) async {
      await tester.pumpWidget(buildApp(initiallyExpanded: true));
      await tester.pumpAndSettle();

      // Labels (uppercase)
      expect(find.text('DESTINATION'), findsAtLeastNWidgets(1));
      expect(find.text('DATES'), findsAtLeastNWidgets(1));
      expect(find.text('TRAVELERS'), findsAtLeastNWidgets(1));

      // Values
      expect(find.text('Paris'), findsAtLeastNWidgets(1));
      expect(find.text('Mar 20 - Mar 25'), findsAtLeastNWidgets(1));
      expect(find.text('3 people'), findsAtLeastNWidgets(1));

      // Icons present
      expect(find.byIcon(Icons.location_on), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.calendar_today), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.group), findsAtLeastNWidgets(1));

      // Up arrow when expanded
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    });

    testWidgets('renders with a single item', (tester) async {
      const singleItem = [
        StepSummaryItem(
          icon: Icons.flight,
          label: 'Flight',
          value: 'CDG - JFK',
        ),
      ];

      await tester.pumpWidget(buildApp(items: singleItem));

      expect(find.text('CDG - JFK'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.flight), findsAtLeastNWidgets(1));
    });
  });
}
