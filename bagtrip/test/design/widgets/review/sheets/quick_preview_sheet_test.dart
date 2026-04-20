import 'package:bagtrip/design/widgets/review/sheets/quick_preview_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget hostWith(Widget sheet) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => sheet,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders title, subtitle, body and primary action', (
    tester,
  ) async {
    await tester.pumpWidget(
      hostWith(
        QuickPreviewSheet(
          icon: Icons.flight_takeoff_rounded,
          title: 'Paris → Kyoto',
          subtitle: 'Outbound',
          body: const Text('Flight details here'),
          primaryAction: QuickPreviewAction(
            label: 'Edit',
            icon: Icons.edit_rounded,
            onPressed: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Paris → Kyoto'), findsOneWidget);
    expect(find.text('OUTBOUND'), findsOneWidget);
    expect(find.text('Flight details here'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('fires primary action', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      hostWith(
        QuickPreviewSheet(
          icon: Icons.edit_rounded,
          title: 'Item',
          body: const Text('body'),
          primaryAction: QuickPreviewAction(
            label: 'Edit',
            icon: Icons.edit_rounded,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(pressed, isTrue);
  });

  testWidgets('renders secondary and destructive actions when provided', (
    tester,
  ) async {
    var secondary = false;
    var destructive = false;
    await tester.pumpWidget(
      hostWith(
        QuickPreviewSheet(
          icon: Icons.edit_rounded,
          title: 'Item',
          body: const Text('body'),
          primaryAction: QuickPreviewAction(
            label: 'Edit',
            icon: Icons.edit_rounded,
            onPressed: () {},
          ),
          secondaryAction: QuickPreviewAction(
            label: 'Duplicate',
            icon: Icons.copy_rounded,
            onPressed: () => secondary = true,
          ),
          destructiveAction: QuickPreviewAction(
            label: 'Delete',
            icon: Icons.delete_outline_rounded,
            onPressed: () => destructive = true,
            isDestructive: true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    expect(secondary, isTrue);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(destructive, isTrue);
  });

  testWidgets('open-full footer pops sheet and calls callback', (tester) async {
    var openFullFired = false;
    await tester.pumpWidget(
      hostWith(
        QuickPreviewSheet(
          icon: Icons.edit_rounded,
          title: 'Item',
          body: const Text('body'),
          primaryAction: QuickPreviewAction(
            label: 'Edit',
            icon: Icons.edit_rounded,
            onPressed: () {},
          ),
          openFullLabel: 'Open full breakdown',
          onOpenFull: () => openFullFired = true,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Open full breakdown'), findsOneWidget);
    await tester.tap(find.text('Open full breakdown'));
    await tester.pumpAndSettle();

    expect(openFullFired, isTrue);
    // sheet is dismissed: the label disappears.
    expect(find.text('Open full breakdown'), findsNothing);
  });

  testWidgets('hides open-full footer when callback missing', (tester) async {
    await tester.pumpWidget(
      hostWith(
        QuickPreviewSheet(
          icon: Icons.edit_rounded,
          title: 'Item',
          body: const Text('body'),
          primaryAction: QuickPreviewAction(
            label: 'Edit',
            icon: Icons.edit_rounded,
            onPressed: () {},
          ),
          openFullLabel: 'Open full',
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Open full'), findsNothing);
  });
}
