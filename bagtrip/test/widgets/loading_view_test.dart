import 'package:bagtrip/components/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('LoadingView', () {
    testWidgets('renders spinner', (tester) async {
      await tester.pumpWidget(buildApp(child: const LoadingView()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(
        buildApp(child: const LoadingView(message: 'Loading trips...')),
      );

      expect(find.text('Loading trips...'), findsOneWidget);
    });

    testWidgets('no message widget when null', (tester) async {
      await tester.pumpWidget(buildApp(child: const LoadingView()));

      // Only the spinner, no Text widget for message
      expect(find.byType(Text), findsNothing);
    });
  });
}
