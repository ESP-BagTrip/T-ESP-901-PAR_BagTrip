import 'package:bagtrip/components/adaptive/adaptive_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('showAdaptiveTimePicker', () {
    testWidgets('opens the Material time picker and cancels', (tester) async {
      TimeOfDay? picked;
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              picked = await showAdaptiveTimePicker(
                context: ctx,
                initialTime: const TimeOfDay(hour: 9, minute: 30),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      // Cancel closes the dialog, picked stays null
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(picked, isNull);
    });

    testWidgets('OK confirms the initial time', (tester) async {
      TimeOfDay? picked;
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              picked = await showAdaptiveTimePicker(
                context: ctx,
                initialTime: const TimeOfDay(hour: 14, minute: 0),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pump();
      expect(picked, isNotNull);
      expect(picked!.hour, 14);
    });
  });
}
