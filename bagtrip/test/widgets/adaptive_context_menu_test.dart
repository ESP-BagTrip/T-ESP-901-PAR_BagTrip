import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('AdaptiveContextMenu', () {
    testWidgets('returns child unchanged on Android (default test platform)', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        AdaptiveContextMenu(
          actions: [
            AdaptiveContextAction(
              label: 'Copy',
              icon: Icons.copy,
              onPressed: () {},
            ),
          ],
          child: const Text('Content'),
        ),
      );
      await tester.pump();
      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(AdaptiveContextMenu), findsOneWidget);
    });

    testWidgets('returns child unchanged when enabled is false', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        AdaptiveContextMenu(
          enabled: false,
          actions: [
            AdaptiveContextAction(
              label: 'Delete',
              icon: Icons.delete,
              isDestructive: true,
              onPressed: () {},
            ),
          ],
          child: const Text('Guarded'),
        ),
      );
      await tester.pump();
      expect(find.text('Guarded'), findsOneWidget);
    });

    testWidgets('returns child unchanged when actions list is empty', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const AdaptiveContextMenu(actions: [], child: Text('NoActions')),
      );
      await tester.pump();
      expect(find.text('NoActions'), findsOneWidget);
    });
  });
}
