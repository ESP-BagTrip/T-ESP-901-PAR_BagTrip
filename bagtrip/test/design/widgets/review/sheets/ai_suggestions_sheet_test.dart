import 'package:bagtrip/design/widgets/review/sheets/ai_suggestions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required List<String> suggestions,
    String title = 'Suggestions',
    String? subtitle,
    String? disclaimer,
    String? emptyTitle,
    String? emptySubtitle,
    Widget Function(BuildContext, String, int)? itemBuilder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AiSuggestionsSheet<String>(
                      title: title,
                      subtitle: subtitle,
                      disclaimer: disclaimer,
                      emptyTitle: emptyTitle,
                      emptySubtitle: emptySubtitle,
                      suggestions: suggestions,
                      itemBuilder:
                          itemBuilder ??
                          (_, item, _) => ListTile(title: Text(item)),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders title and items via itemBuilder', (tester) async {
    await openSheet(
      tester,
      title: 'AI Suggestions',
      suggestions: ['Louvre', 'Eiffel Tower', 'Notre-Dame'],
    );

    expect(find.text('AI Suggestions'), findsOneWidget);
    expect(find.text('Louvre'), findsOneWidget);
    expect(find.text('Eiffel Tower'), findsOneWidget);
    expect(find.text('Notre-Dame'), findsOneWidget);
  });

  testWidgets('renders caps subtitle when provided', (tester) async {
    await openSheet(
      tester,
      title: 'AI Suggestions',
      subtitle: 'Activities',
      suggestions: const ['A'],
    );

    expect(find.text('ACTIVITIES'), findsOneWidget);
  });

  testWidgets('renders disclaimer at the end when provided', (tester) async {
    await openSheet(
      tester,
      suggestions: const ['A'],
      disclaimer: 'Verify before booking',
    );

    expect(find.text('Verify before booking'), findsOneWidget);
  });

  testWidgets('renders empty state when suggestions is empty', (tester) async {
    await openSheet(
      tester,
      suggestions: const [],
      emptyTitle: 'No suggestions',
      emptySubtitle: 'Try again in a moment',
    );

    expect(find.text('No suggestions'), findsOneWidget);
    expect(find.text('Try again in a moment'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
  });

  testWidgets('close button dismisses the sheet', (tester) async {
    await openSheet(tester, suggestions: const ['A', 'B']);

    expect(find.text('A'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsNothing);
  });
}
