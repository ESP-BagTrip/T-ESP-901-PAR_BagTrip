import 'package:bagtrip/design/widgets/item_status_chip.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    required ItemStatusChipKind kind,
    bool compact = false,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: ItemStatusChip(kind: kind, compact: compact),
      ),
    );
  }

  group('ItemStatusChip — render', () {
    testWidgets('SUGGESTED renders auto_awesome icon + localised label (EN)', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(kind: ItemStatusChipKind.suggested));
      await tester.pump();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('AI suggestion'), findsOneWidget);
    });

    testWidgets('VALIDATED renders check_circle + localised label (EN)', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(kind: ItemStatusChipKind.validated));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Validated'), findsOneWidget);
    });

    testWidgets('MANUAL renders edit_note + localised label (EN)', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(kind: ItemStatusChipKind.manual));
      await tester.pump();

      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.text('Added by you'), findsOneWidget);
    });

    testWidgets('compact mode hides the label', (tester) async {
      await tester.pumpWidget(
        buildApp(kind: ItemStatusChipKind.suggested, compact: true),
      );
      await tester.pump();

      // Icon still present, but the label text is omitted.
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('AI suggestion'), findsNothing);
    });

    testWidgets('FR locale produces French label', (tester) async {
      await tester.pumpWidget(
        buildApp(
          kind: ItemStatusChipKind.suggested,
          locale: const Locale('fr'),
        ),
      );
      await tester.pump();

      expect(find.text("Proposé par l'IA"), findsOneWidget);
    });
  });

  group('ItemStatusChip — accessibility', () {
    testWidgets('exposes a Semantics node carrying the label', (tester) async {
      await tester.pumpWidget(buildApp(kind: ItemStatusChipKind.validated));
      await tester.pump();

      // The Semantics wrapper is the public a11y contract — the chip
      // must expose a label so VoiceOver / TalkBack read it instead
      // of "icon, icon".
      final semantics = tester.getSemantics(find.byType(ItemStatusChip));
      expect(semantics.label, contains('Validated'));
    });
  });

  group('ItemStatusChip.fromBackend', () {
    test('maps backend strings to enum kinds', () {
      expect(
        ItemStatusChip.fromBackend('SUGGESTED'),
        ItemStatusChipKind.suggested,
      );
      expect(
        ItemStatusChip.fromBackend('VALIDATED'),
        ItemStatusChipKind.validated,
      );
      expect(ItemStatusChip.fromBackend('MANUAL'), ItemStatusChipKind.manual);
    });

    test('falls back to manual for unknown / null inputs', () {
      // An unknown enum value never crashes the UI — it's rendered as
      // "added by you" until the backend tells us otherwise.
      expect(ItemStatusChip.fromBackend(null), ItemStatusChipKind.manual);
      expect(ItemStatusChip.fromBackend(''), ItemStatusChipKind.manual);
      expect(
        ItemStatusChip.fromBackend('SOMETHING_NEW'),
        ItemStatusChipKind.manual,
      );
    });
  });
}
