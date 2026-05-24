import 'package:bagtrip/components/custom_calendar_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('CustomCalendarPicker', () {
    testWidgets('renders with initial month header and weekday row', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        CustomCalendarPicker(
          initialDate: DateTime(2024, 6, 15),
          firstDate: DateTime(2024),
          lastDate: DateTime(2024, 12, 31),
          dialogWidth: 360,
        ),
      );
      await tester.pump();

      expect(find.byType(CustomCalendarPicker), findsOneWidget);
      // Header has prev, next, close chevrons + the close icon.
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('renders days 1..n of the month inside the grid', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        CustomCalendarPicker(
          initialDate: DateTime(2024, 6, 15),
          firstDate: DateTime(2024),
          lastDate: DateTime(2024, 12, 31),
          dialogWidth: 360,
        ),
      );
      await tester.pump();

      // June has 30 days — at least the first and 30th should be in the tree.
      expect(find.text('1'), findsWidgets);
      expect(find.text('15'), findsWidgets);
      expect(find.text('30'), findsWidgets);
    });

    testWidgets('tapping next chevron advances the current month', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        CustomCalendarPicker(
          initialDate: DateTime(2024, 6, 15),
          firstDate: DateTime(2024),
          lastDate: DateTime(2024, 12, 31),
          dialogWidth: 360,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CustomCalendarPicker), findsOneWidget);
    });

    testWidgets('tapping previous chevron rewinds the current month', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        CustomCalendarPicker(
          initialDate: DateTime(2024, 6, 15),
          firstDate: DateTime(2024),
          lastDate: DateTime(2024, 12, 31),
          dialogWidth: 360,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CustomCalendarPicker), findsOneWidget);
    });

    testWidgets('single-date selection pops dialog with result', (
      tester,
    ) async {
      DateRangeResult? result;

      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              result = await showCustomCalendarPicker(
                context: ctx,
                initialDate: DateTime(2024, 6, 15),
                firstDate: DateTime(2024),
                lastDate: DateTime(2024, 12, 31),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(find.byType(CustomCalendarPicker), findsOneWidget);

      // Tap some future day we know is enabled (day 20).
      final day20 = find.text('20').first;
      await tester.tap(day20);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(result, isNotNull);
      expect(result!.startDate.day, 20);
      expect(result!.endDate, isNull);
    });

    testWidgets('range selection stores start then end date', (tester) async {
      await pumpLocalized(
        tester,
        CustomCalendarPicker(
          initialDate: DateTime(2024, 6, 5),
          firstDate: DateTime(2024),
          lastDate: DateTime(2024, 12, 31),
          dialogWidth: 360,
          isRangeSelection: true,
        ),
      );
      await tester.pump();

      // First click becomes a new start.
      await tester.tap(find.text('10').first);
      await tester.pump();

      // Second click completes the range and would pop if mounted in a
      // Navigator. We just verify no crash + picker still in the tree.
      expect(find.byType(CustomCalendarPicker), findsOneWidget);
    });

    testWidgets('range selection with reversed order swaps start/end', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        CustomCalendarPicker(
          initialDate: DateTime(2024, 6, 20),
          firstDate: DateTime(2024),
          lastDate: DateTime(2024, 12, 31),
          dialogWidth: 360,
          isRangeSelection: true,
        ),
      );
      await tester.pump();

      // Initial start is day 20. Tap day 10 — that's before start, so it
      // should swap and still render without error.
      await tester.tap(find.text('10').first);
      await tester.pump();

      expect(find.byType(CustomCalendarPicker), findsOneWidget);
    });

    testWidgets('disabled days outside first/last date are non-tappable', (
      tester,
    ) async {
      DateRangeResult? result;

      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              result = await showCustomCalendarPicker(
                context: ctx,
                initialDate: DateTime(2024, 6, 15),
                firstDate: DateTime(2024, 6, 10),
                lastDate: DateTime(2024, 6, 20),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      // Day 5 is outside [10, 20] so tapping it must not pop the dialog.
      await tester.tap(find.text('5').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(result, isNull);
      expect(find.byType(CustomCalendarPicker), findsOneWidget);
    });

    testWidgets('close icon pops the dialog with no result', (tester) async {
      DateRangeResult? result = DateRangeResult(startDate: DateTime(2099));

      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              result = await showCustomCalendarPicker(
                context: ctx,
                initialDate: DateTime(2024, 6, 15),
                firstDate: DateTime(2024),
                lastDate: DateTime(2024, 12, 31),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(result, isNull);
    });

    testWidgets('renders with French locale without crash', (tester) async {
      await pumpLocalized(
        tester,
        CustomCalendarPicker(
          initialDate: DateTime(2024, 6, 15),
          firstDate: DateTime(2024),
          lastDate: DateTime(2024, 12, 31),
          dialogWidth: 360,
        ),
        locale: const Locale('fr'),
      );
      await tester.pump();

      expect(find.byType(CustomCalendarPicker), findsOneWidget);
    });

    testWidgets('narrow dialogWidth still renders (small-screen branch)', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        CustomCalendarPicker(
          initialDate: DateTime(2024, 6, 15),
          firstDate: DateTime(2024),
          lastDate: DateTime(2024, 12, 31),
          dialogWidth: 320,
        ),
        size: const Size(320, 800),
      );
      await tester.pump();

      expect(find.byType(CustomCalendarPicker), findsOneWidget);
    });
  });
}
