import 'package:bagtrip/components/adaptive/adaptive_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('showAdaptiveEditDialog', () {
    testWidgets('returns edited text on confirm', (tester) async {
      String? result;
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              result = await showAdaptiveEditDialog(
                context: ctx,
                title: 'Edit name',
                currentValue: 'Jane',
                confirmLabel: 'Save',
                cancelLabel: 'Cancel',
                placeholder: 'Your name',
                keyboardType: TextInputType.name,
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(find.text('Edit name'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Mary');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(result, 'Mary');
    });

    testWidgets('returns null on cancel', (tester) async {
      String? result = 'not-null';
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              result = await showAdaptiveEditDialog(
                context: ctx,
                title: 'Edit',
                confirmLabel: 'OK',
                cancelLabel: 'Cancel',
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(result, isNull);
    });

    testWidgets('renders without placeholder when null', (tester) async {
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showAdaptiveEditDialog(
              context: ctx,
              title: 'Quick edit',
              confirmLabel: 'OK',
              cancelLabel: 'Cancel',
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(find.text('Quick edit'), findsOneWidget);
    });
  });
}
