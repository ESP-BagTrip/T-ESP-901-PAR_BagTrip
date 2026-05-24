import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/design/widgets/item_status_chip.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget mountSheet(ItemFormScaffold scaffold) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: scaffold),
    );
  }

  testWidgets('renders title, fields and actions in order', (tester) async {
    await tester.pumpWidget(
      mountSheet(
        ItemFormScaffold(
          title: 'New expense',
          fields: const Text('field-marker'),
          actions: [
            ElevatedButton(onPressed: () {}, child: const Text('save-btn')),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('New expense'), findsOneWidget);
    expect(find.text('field-marker'), findsOneWidget);
    expect(find.text('save-btn'), findsOneWidget);
  });

  testWidgets('renders subtitle and status chip when provided', (tester) async {
    await tester.pumpWidget(
      mountSheet(
        const ItemFormScaffold(
          title: 'Edit flight',
          subtitle: 'CDG → HND',
          statusKind: ItemStatusChipKind.suggested,
          fields: SizedBox.shrink(),
          actions: [],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CDG → HND'), findsOneWidget);
    expect(find.byType(ItemStatusChip), findsOneWidget);
  });

  testWidgets('default close button pops the route', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showItemFormSheet<void>(
                    context: context,
                    child: const ItemFormScaffold(
                      title: 'X',
                      fields: SizedBox.shrink(),
                      actions: [],
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemFormScaffold), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(ItemFormScaffold), findsNothing);
  });

  testWidgets('custom onClose overrides the default pop', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      mountSheet(
        ItemFormScaffold(
          title: 'X',
          fields: const SizedBox.shrink(),
          actions: const [],
          onClose: () => calls++,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('sheet content is capped at 80% of screen height', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      mountSheet(
        const ItemFormScaffold(
          title: 'Tall form',
          fields: SizedBox(height: 2000),
          actions: [],
        ),
      ),
    );
    await tester.pump();

    final maxHeight = 800 * ItemFormSheetLayout.maxHeightFactor;
    final constrainedBoxes = tester.widgetList<ConstrainedBox>(
      find.descendant(
        of: find.byType(ItemFormScaffold),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(
      constrainedBoxes.any((b) => b.constraints.maxHeight == maxHeight),
      isTrue,
    );
  });
}
