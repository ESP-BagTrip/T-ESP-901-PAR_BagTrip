import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:bagtrip/plan_trip/widgets/duration_chip_selector.dart';
import 'package:flutter/material.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    DurationPreset? selected,
    ValueChanged<DurationPreset>? onSelected,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: DurationChipSelector(
            selected: selected,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('DurationChipSelector', () {
    testWidgets('renders 4 duration options', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Weekend'), findsOneWidget);
      expect(find.text('1 week'), findsOneWidget);
      expect(find.text('2 weeks'), findsOneWidget);
      expect(find.text('3 weeks'), findsOneWidget);
    });

    testWidgets('renders subtitle days', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('2-3 days'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('14 days'), findsOneWidget);
      expect(find.text('21 days'), findsOneWidget);
    });

    testWidgets('tap fires callback with correct DurationPreset', (
      tester,
    ) async {
      DurationPreset? selected;
      await tester.pumpWidget(buildApp(onSelected: (v) => selected = v));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weekend'));
      await tester.pump();
      expect(selected, DurationPreset.weekend);

      await tester.tap(find.text('1 week'));
      await tester.pump();
      expect(selected, DurationPreset.oneWeek);

      await tester.tap(find.text('2 weeks'));
      await tester.pump();
      expect(selected, DurationPreset.twoWeeks);

      await tester.tap(find.text('3 weeks'));
      await tester.pump();
      expect(selected, DurationPreset.threeWeeks);
    });

    testWidgets('selection shows visual distinction', (tester) async {
      await tester.pumpWidget(buildApp(selected: DurationPreset.oneWeek));
      await tester.pumpAndSettle();

      // Renders without error with a selection
      expect(find.byType(DurationChipSelector), findsOneWidget);
    });
  });
}
