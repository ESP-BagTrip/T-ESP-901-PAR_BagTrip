import 'package:bagtrip/components/adaptive/adaptive_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('AdaptiveAppBar.build', () {
    testWidgets('returns a Material AppBar on Android', (tester) async {
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => Scaffold(
            appBar: AdaptiveAppBar.build(
              context: ctx,
              title: 'Title',
              actions: const [Icon(Icons.settings)],
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders with leading widget and bottom', (tester) async {
      final bottom = PreferredSize(
        preferredSize: const Size.fromHeight(20),
        child: Container(height: 20, color: Colors.amber),
      );
      await pumpLocalized(
        tester,
        Builder(
          builder: (ctx) => Scaffold(
            appBar: AdaptiveAppBar.build(
              context: ctx,
              title: 'X',
              leading: const BackButton(),
              bottom: bottom,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });
  });
}
