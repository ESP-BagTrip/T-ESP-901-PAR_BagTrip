import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('showAdaptiveAlertDialog', () {
    testWidgets('renders Material AlertDialog with confirm + cancel', (
      tester,
    ) async {
      var confirmed = false;
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showAdaptiveAlertDialog<void>(
              context: ctx,
              title: 'Delete?',
              content: 'This cannot be undone.',
              confirmLabel: 'Delete',
              cancelLabel: 'Cancel',
              isDestructive: true,
              onConfirm: () => confirmed = true,
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(find.text('Delete?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(confirmed, isTrue);
    });

    testWidgets('cancel tap fires onCancel', (tester) async {
      var cancelled = false;
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showAdaptiveAlertDialog<void>(
              context: ctx,
              title: 'Confirm',
              confirmLabel: 'OK',
              cancelLabel: 'Cancel',
              onCancel: () => cancelled = true,
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(cancelled, isTrue);
    });

    testWidgets('renders without content when null', (tester) async {
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showAdaptiveAlertDialog<void>(
              context: ctx,
              title: 'Quick',
              confirmLabel: 'OK',
              cancelLabel: 'Cancel',
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(find.text('Quick'), findsOneWidget);
    });
  });
}
