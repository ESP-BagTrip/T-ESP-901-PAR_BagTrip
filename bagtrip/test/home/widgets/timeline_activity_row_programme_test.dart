import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/home/widgets/timeline_activity_row.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  Widget buildHarness({required TimelineActivityRow row}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: TickerMode(enabled: false, child: row)),
    );
  }

  testWidgets('programme current activity capsule uses secondary fill', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      buildHarness(
        row: TimelineActivityRow(
          activity: makeActivity(
            id: 'a1',
            tripId: 't1',
            title: 'Museum',
            date: DateTime(now.year, now.month, now.day),
            startTime: '00:00',
          ),
          isCurrent: true,
          isLast: true,
          useProgrammeCapsuleColors: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('NOW'), findsOneWidget);
    final label = tester.widget<Text>(find.text('NOW'));
    expect(label.style?.color, Colors.white);

    final capsule = tester.widget<Container>(
      find.ancestor(
        of: find.text('NOW'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color == ColorName.secondary,
        ),
      ),
    );
    expect((capsule.decoration! as BoxDecoration).color, ColorName.secondary);
  });

  testWidgets('programme timed activity capsule uses primaryDark fill', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      buildHarness(
        row: TimelineActivityRow(
          activity: makeActivity(
            id: 'a2',
            tripId: 't1',
            title: 'Dinner',
            date: DateTime(now.year, now.month, now.day),
            startTime: '20:00',
          ),
          isLast: true,
          useProgrammeCapsuleColors: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('20:00'), findsOneWidget);
    final label = tester.widget<Text>(find.text('20:00'));
    expect(label.style?.color, Colors.white);

    final capsule = tester.widget<Container>(
      find.ancestor(
        of: find.text('20:00'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color == ColorName.primaryDark,
        ),
      ),
    );
    expect((capsule.decoration! as BoxDecoration).color, ColorName.primaryDark);
  });
}
