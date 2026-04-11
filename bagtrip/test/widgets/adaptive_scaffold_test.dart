import 'package:bagtrip/components/adaptive/adaptive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('AdaptiveScaffold', () {
    testWidgets('renders as Material Scaffold on Android with appBar + body', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        AdaptiveScaffold(
          appBar: AppBar(title: const Text('Title')),
          body: const Text('Body'),
          backgroundColor: Colors.white,
        ),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('renders with FAB and bottomNavigationBar', (tester) async {
      await pumpLocalized(
        tester,
        AdaptiveScaffold(
          body: const SizedBox(height: 100),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });
}
