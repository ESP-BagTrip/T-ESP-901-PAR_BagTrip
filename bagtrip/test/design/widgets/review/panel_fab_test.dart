import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a FAB with label', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PanelFab(label: 'Add expense', onTap: () => tapped = true),
          ),
        ),
      ),
    );

    final labelFinder = find.text('Add expense');
    if (labelFinder.evaluate().isNotEmpty) {
      // Android extended FAB renders the label.
      await tester.tap(labelFinder);
    } else {
      // iOS compact variant has no text label — tap on the widget itself.
      await tester.tap(find.byType(PanelFab));
    }
    expect(tapped, isTrue);
  });

  testWidgets('has semantics label even when label is not displayed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PanelFab(label: 'Add item', onTap: () {}),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Add item'),
      findsWidgets,
      reason: 'semantics label should expose the FAB action to screen readers',
    );
  });
}
