import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/home/widgets/active_trip_day_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness({
    required int totalDays,
    required int selectedDayIndex0,
    required DateTime tripStartDate,
    int? calendarTodayIndex0,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ActiveTripDayNavigator(
          totalDays: totalDays,
          selectedDayIndex0: selectedDayIndex0,
          tripStartDate: tripStartDate,
          calendarTodayIndex0: calendarTodayIndex0,
          onDaySelected: (_) {},
        ),
      ),
    );
  }

  testWidgets('selected day chip uses primaryDark fill', (tester) async {
    final start = DateTime(2026, 5, 20);
    await tester.pumpWidget(
      buildHarness(
        totalDays: 5,
        selectedDayIndex0: 2,
        tripStartDate: start,
        calendarTodayIndex0: 2,
      ),
    );
    await tester.pump();

    final containers = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final selectedChip = containers.firstWhere(
      (c) =>
          c.decoration is BoxDecoration &&
          (c.decoration! as BoxDecoration).color == ColorName.primaryDark,
    );
    expect(selectedChip.decoration, isA<BoxDecoration>());
    final decoration = selectedChip.decoration! as BoxDecoration;
    expect(decoration.color, ColorName.primaryDark);
    expect(decoration.borderRadius, AppRadius.medium12);
  });

  testWidgets('day chips are square not circular', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        totalDays: 3,
        selectedDayIndex0: 0,
        tripStartDate: DateTime(2026, 5),
      ),
    );
    await tester.pump();

    final chip = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    final decoration = chip.decoration! as BoxDecoration;
    expect(decoration.shape, isNot(BoxShape.circle));
    expect(decoration.borderRadius, AppRadius.medium12);
  });
}
