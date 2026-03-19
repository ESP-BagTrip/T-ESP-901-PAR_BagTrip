import 'package:bagtrip/design/widgets/streaming_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({required List<StreamingChecklistItem> items}) {
    return MaterialApp(
      home: Scaffold(body: StreamingChecklist(items: items)),
    );
  }

  group('StreamingChecklist', () {
    testWidgets('renders pending items with radio_button_unchecked', (
      tester,
    ) async {
      final items = [
        const StreamingChecklistItem(
          label: 'Flights',
          icon: Icons.flight,
          isDone: false,
        ),
        const StreamingChecklistItem(
          label: 'Hotels',
          icon: Icons.hotel,
          isDone: false,
        ),
      ];

      await tester.pumpWidget(buildApp(items: items));
      await tester.pump();

      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('renders done items with check_circle', (tester) async {
      final items = [
        const StreamingChecklistItem(
          label: 'Flights',
          icon: Icons.flight,
          isDone: true,
        ),
        const StreamingChecklistItem(
          label: 'Hotels',
          icon: Icons.hotel,
          isDone: true,
        ),
      ];

      await tester.pumpWidget(buildApp(items: items));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
    });

    testWidgets('renders correct number of items', (tester) async {
      final items = [
        const StreamingChecklistItem(
          label: 'Flights',
          icon: Icons.flight,
          isDone: false,
        ),
        const StreamingChecklistItem(
          label: 'Hotels',
          icon: Icons.hotel,
          isDone: true,
        ),
        const StreamingChecklistItem(
          label: 'Activities',
          icon: Icons.local_activity,
          isDone: false,
        ),
      ];

      await tester.pumpWidget(buildApp(items: items));
      await tester.pump();

      expect(find.text('Flights'), findsOneWidget);
      expect(find.text('Hotels'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);

      expect(find.byIcon(Icons.flight), findsOneWidget);
      expect(find.byIcon(Icons.hotel), findsOneWidget);
      expect(find.byIcon(Icons.local_activity), findsOneWidget);

      // 1 done + 2 pending
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
    });

    testWidgets('renders mixed done and pending states correctly', (
      tester,
    ) async {
      final items = [
        const StreamingChecklistItem(
          label: 'Flights',
          icon: Icons.flight,
          isDone: true,
        ),
        const StreamingChecklistItem(
          label: 'Hotels',
          icon: Icons.hotel,
          isDone: false,
        ),
      ];

      await tester.pumpWidget(buildApp(items: items));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });
  });
}
