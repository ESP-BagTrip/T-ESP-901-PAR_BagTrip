import 'package:bagtrip/plan_trip/widgets/traveler_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    required int value,
    required ValueChanged<int> onChanged,
    int min = 1,
    int max = 10,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TravelerStepper(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
        ),
      ),
    );
  }

  group('TravelerStepper', () {
    testWidgets('renders current count', (tester) async {
      await tester.pumpWidget(buildApp(value: 3, onChanged: (_) {}));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('plus fires callback with count + 1', (tester) async {
      int? result;
      await tester.pumpWidget(buildApp(value: 2, onChanged: (v) => result = v));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      expect(result, 3);
    });

    testWidgets('minus fires callback with count - 1', (tester) async {
      int? result;
      await tester.pumpWidget(buildApp(value: 5, onChanged: (v) => result = v));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();

      expect(result, 4);
    });

    testWidgets('cannot go below min', (tester) async {
      int? result;
      await tester.pumpWidget(buildApp(value: 1, onChanged: (v) => result = v));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();

      expect(result, isNull);
    });

    testWidgets('cannot go above max', (tester) async {
      int? result;
      await tester.pumpWidget(
        buildApp(value: 10, onChanged: (v) => result = v),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      expect(result, isNull);
    });

    testWidgets('renders both icons', (tester) async {
      await tester.pumpWidget(buildApp(value: 5, onChanged: (_) {}));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });
  });
}
