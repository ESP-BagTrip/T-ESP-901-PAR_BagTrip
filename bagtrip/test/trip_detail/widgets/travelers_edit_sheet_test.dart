import 'package:bagtrip/trip_detail/widgets/travelers_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('showTravelersEditSheet', () {
    testWidgets('opens the sheet with the initial value', (tester) async {
      int? result;
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              result = await showTravelersEditSheet(
                context: ctx,
                currentValue: 3,
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The sheet exposes the Save button.
      expect(find.byType(FilledButton), findsWidgets);

      // Tap save — pops the initial value.
      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();
      expect(result, 3);
    });

    testWidgets('dismissing without save returns null', (tester) async {
      int? result = -1;
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              result = await showTravelersEditSheet(
                context: ctx,
                currentValue: 2,
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Drag the sheet down to dismiss.
      final sheet = find.byType(FilledButton);
      expect(sheet, findsWidgets);
      // Just pop the route to simulate dismissal.
      final nav = Navigator.of(tester.element(find.text('Open')));
      nav.pop();
      await tester.pump();
      expect(result, isNull);
    });
  });
}
