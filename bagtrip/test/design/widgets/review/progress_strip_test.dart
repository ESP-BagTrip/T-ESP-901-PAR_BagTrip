import 'package:bagtrip/design/widgets/review/progress_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildUnder({required String label, required double progress}) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ProgressStrip(label: label, progress: progress),
        ),
      ),
    );
  }

  testWidgets('renders label and rounded percent', (tester) async {
    await tester.pumpWidget(
      buildUnder(label: '4 OF 12 PACKED', progress: 0.33),
    );

    expect(find.text('4 OF 12 PACKED'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
  });

  testWidgets('clamps progress > 1 to 100%', (tester) async {
    await tester.pumpWidget(buildUnder(label: 'DONE', progress: 1.5));

    expect(find.text('100%'), findsOneWidget);
    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 1.0);
  });

  testWidgets('clamps negative progress to 0%', (tester) async {
    await tester.pumpWidget(buildUnder(label: 'START', progress: -0.2));

    expect(find.text('0%'), findsOneWidget);
    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 0.0);
  });
}
