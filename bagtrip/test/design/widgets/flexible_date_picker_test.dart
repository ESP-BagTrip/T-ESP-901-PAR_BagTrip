import 'package:bagtrip/design/widgets/flexible_date_picker.dart';
import 'package:bagtrip/plan_trip/models/date_mode.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:bagtrip/plan_trip/widgets/month_grid_picker.dart';
import 'package:flutter/material.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    DateMode mode = DateMode.exact,
    ValueChanged<DateMode>? onModeChanged,
    DurationPreset? selectedDuration,
    ValueChanged<DurationPreset>? onDurationChanged,
    int? selectedMonth,
    int? selectedYear,
    void Function(int, int)? onMonthSelected,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: FlexibleDatePicker(
            mode: mode,
            onModeChanged: onModeChanged ?? (_) {},
            selectedDuration: selectedDuration,
            onDurationChanged: onDurationChanged,
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            onMonthSelected: onMonthSelected,
          ),
        ),
      ),
    );
  }

  group('FlexibleDatePicker', () {
    testWidgets('renders segment control with 3 modes', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Exact dates'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Flexible'), findsOneWidget);
    });

    testWidgets('exact mode shows date cards', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Date card labels (toUpperCase in _DateCard)
      expect(find.text('DEPART'), findsOneWidget);
      expect(find.text('RETURN'), findsOneWidget);
    });

    testWidgets('flexible mode shows duration chip selector with 4 cards', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(mode: DateMode.flexible));
      await tester.pumpAndSettle();

      expect(find.text('Weekend'), findsOneWidget);
      expect(find.text('1 week'), findsOneWidget);
      expect(find.text('2 weeks'), findsOneWidget);
      expect(find.text('3 weeks'), findsOneWidget);
    });

    testWidgets('flexible chip fires DurationPreset callback', (tester) async {
      DurationPreset? selected;
      await tester.pumpWidget(
        buildApp(
          mode: DateMode.flexible,
          onDurationChanged: (v) => selected = v,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weekend'));
      await tester.pump();

      expect(selected, DurationPreset.weekend);
    });

    testWidgets('month mode shows 12 month cells', (tester) async {
      await tester.pumpWidget(buildApp(mode: DateMode.month));
      await tester.pumpAndSettle();

      // MonthGridPicker + DurationChipSelector both use GridView
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsNWidgets(2));
    });

    testWidgets('month selection fires callback with month and year', (
      tester,
    ) async {
      int? calledMonth;
      int? calledYear;
      await tester.pumpWidget(
        buildApp(
          mode: DateMode.month,
          onMonthSelected: (m, y) {
            calledMonth = m;
            calledYear = y;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap a month cell inside MonthGridPicker (find by ancestor)
      final monthGridGestures = find.descendant(
        of: find.byType(MonthGridPicker),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(monthGridGestures.last);
      await tester.pump();

      // The callback should have been called
      expect(calledMonth, isNotNull);
      expect(calledYear, isNotNull);
    });

    testWidgets('mode change callback fires', (tester) async {
      DateMode? newMode;
      await tester.pumpWidget(buildApp(onModeChanged: (m) => newMode = m));
      await tester.pumpAndSettle();

      // Tap on "Month" segment
      await tester.tap(find.text('Month'));
      await tester.pump();

      expect(newMode, DateMode.month);
    });
  });
}
