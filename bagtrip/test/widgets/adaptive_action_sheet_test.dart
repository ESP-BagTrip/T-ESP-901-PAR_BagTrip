import 'package:bagtrip/components/adaptive/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('showAdaptiveActionSheet', () {
    testWidgets('renders title + actions and invokes callback on tap', (
      tester,
    ) async {
      var picked = '';
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showAdaptiveActionSheet(
              context: ctx,
              title: 'Pick one',
              cancelLabel: 'Dismiss',
              actions: [
                AdaptiveAction(
                  label: 'Option A',
                  icon: Icons.star,
                  onPressed: () => picked = 'A',
                ),
                AdaptiveAction(
                  label: 'Delete',
                  isDestructive: true,
                  onPressed: () => picked = 'delete',
                ),
              ],
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Pick one'), findsOneWidget);
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Option A'));
      await tester.pump();
      expect(picked, 'A');
    });

    testWidgets('renders without title', (tester) async {
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showAdaptiveActionSheet(
              context: ctx,
              actions: [AdaptiveAction(label: 'Just one', onPressed: () {})],
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Just one'), findsOneWidget);
    });
  });
}
