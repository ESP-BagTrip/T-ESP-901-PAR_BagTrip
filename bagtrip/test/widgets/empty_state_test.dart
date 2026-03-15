import 'package:bagtrip/components/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EmptyState', () {
    testWidgets('shows icon and title', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const EmptyState(
            icon: Icons.event_outlined,
            title: 'No activities',
          ),
        ),
      );

      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
      expect(find.text('No activities'), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const EmptyState(
            icon: Icons.event_outlined,
            title: 'No activities',
            subtitle: 'Add activities to plan your trip',
          ),
        ),
      );

      expect(find.text('Add activities to plan your trip'), findsOneWidget);
    });

    testWidgets('no subtitle when null', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const EmptyState(
            icon: Icons.event_outlined,
            title: 'No activities',
          ),
        ),
      );

      // Only icon + title Text widgets
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('shows action widget when provided', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: EmptyState(
            icon: Icons.search,
            title: 'No results',
            action: ElevatedButton(
              onPressed: () {},
              child: const Text('Reset filters'),
            ),
          ),
        ),
      );

      expect(find.text('Reset filters'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
