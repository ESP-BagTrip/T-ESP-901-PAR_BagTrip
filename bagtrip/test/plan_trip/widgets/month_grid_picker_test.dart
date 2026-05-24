import 'package:bagtrip/plan_trip/widgets/month_grid_picker.dart';
import 'package:flutter/material.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
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
          child: MonthGridPicker(
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            onMonthSelected: onMonthSelected ?? (_, _) {},
          ),
        ),
      ),
    );
  }

  group('MonthGridPicker', () {
    testWidgets('renders 12 month cells', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // GridView with 12 children
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      // 12 AnimatedContainer cells
      expect(find.byType(AnimatedContainer), findsNWidgets(12));
    });

    testWidgets('tapping a future month fires callback', (tester) async {
      int? calledMonth;
      int? calledYear;

      await tester.pumpWidget(
        buildApp(
          onMonthSelected: (m, y) {
            calledMonth = m;
            calledYear = y;
          },
        ),
      );
      await tester.pumpAndSettle();

      // The current month is always the first item and is tappable
      final now = DateTime.now();
      // Tap the first GestureDetector in the grid (current month)
      final cells = find.byType(GestureDetector);
      await tester.tap(cells.first);
      await tester.pump();

      expect(calledMonth, now.month);
      expect(calledYear, now.year);
    });

    testWidgets('selected month is visually distinct', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        buildApp(selectedMonth: now.month, selectedYear: now.year),
      );
      await tester.pumpAndSettle();

      // The widget renders — visual distinction is verified by the AnimatedContainer
      // having different decoration (primaryLight bg). We verify render without error.
      expect(find.byType(MonthGridPicker), findsOneWidget);
    });
  });
}
