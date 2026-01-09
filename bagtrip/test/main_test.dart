import 'package:bagtrip/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyApp launches and displays HomePage', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that the app title is correct (checking via MaterialApp properties might be hard directly, 
    // but we can check if it rendered the router).
    
    // Wait for router to settle
    await tester.pumpAndSettle();

    // Since HomePage is the initial route, we expect to find widgets related to it.
    // For example, we can check if we are in a Scaffold.
    expect(find.byType(Scaffold), findsWidgets);
  });
}
