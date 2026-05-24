import 'package:bagtrip/trip_detail/widgets/date_range_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('showTripDateRangePicker', () {
    testWidgets('opens the Material DateRangePicker on Android', (
      tester,
    ) async {
      DateTimeRange? picked;
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              picked = await showTripDateRangePicker(
                context: ctx,
                currentStart: DateTime.now(),
                currentEnd: DateTime.now().add(const Duration(days: 5)),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      // Material date range picker renders via a full-screen dialog.
      expect(find.byType(Dialog), findsWidgets);
      // Dismiss the dialog via the Cancel button label.
      final cancel = find.text('Cancel');
      if (cancel.evaluate().isNotEmpty) {
        await tester.tap(cancel.first);
        await tester.pump();
      }
      expect(picked, isNull);
    });

    testWidgets('passes null when both currentStart/currentEnd are null', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showTripDateRangePicker(
              context: ctx,
              currentStart: null,
              currentEnd: null,
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(find.byType(Dialog), findsWidgets);
    });
  });
}
