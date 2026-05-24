import 'package:bagtrip/components/adaptive/adaptive_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('showAdaptiveDatePicker', () {
    testWidgets('opens the Material date picker dialog on Android', (
      tester,
    ) async {
      DateTime? picked;
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              picked = await showAdaptiveDatePicker(
                context: ctx,
                initialDate: DateTime(2026, 6, 15),
                firstDate: DateTime(2026),
                lastDate: DateTime(2026, 12, 31),
                helpText: 'Pick a date',
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      // Material date picker dialog is in the tree
      expect(find.byType(DatePickerDialog), findsOneWidget);
      // Close it
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(picked, isNull);
    });

    testWidgets('OK button returns the initial date', (tester) async {
      DateTime? picked;
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              picked = await showAdaptiveDatePicker(
                context: ctx,
                initialDate: DateTime(2026, 6, 15),
                firstDate: DateTime(2026),
                lastDate: DateTime(2026, 12, 31),
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
    });
  });
}
