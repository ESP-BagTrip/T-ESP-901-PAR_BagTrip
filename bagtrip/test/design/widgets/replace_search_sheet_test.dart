import 'package:bagtrip/design/widgets/replace_search_sheet.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget mount(ReplaceSearchSheet sheet) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: sheet),
    );
  }

  testWidgets('renders title + child slot', (tester) async {
    await tester.pumpWidget(
      mount(
        const ReplaceSearchSheet(
          title: 'Replace flight',
          child: Text('search-form-marker'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Replace flight'), findsOneWidget);
    expect(find.text('search-form-marker'), findsOneWidget);
  });

  testWidgets('renders subtitle when provided', (tester) async {
    await tester.pumpWidget(
      mount(
        const ReplaceSearchSheet(
          title: 'Replace flight',
          subtitle: 'CDG → HND',
          child: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CDG → HND'), findsOneWidget);
  });

  testWidgets('close button pops the route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showReplaceSearchSheet<void>(
                    context: context,
                    sheet: const ReplaceSearchSheet(
                      title: 'Replace flight',
                      child: SizedBox.shrink(),
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
    expect(find.byType(ReplaceSearchSheet), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(ReplaceSearchSheet), findsNothing);
  });

  testWidgets('custom onClose overrides the default pop', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      mount(
        ReplaceSearchSheet(
          title: 'Replace flight',
          onClose: () => calls++,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(calls, 1);
  });
}
