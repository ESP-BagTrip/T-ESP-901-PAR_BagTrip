import 'package:bagtrip/design/widgets/review/animated_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {bool disableAnimations = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: child),
      ),
    );
  }

  group('AnimatedCount', () {
    testWidgets('renders target value on first mount', (tester) async {
      await tester.pumpWidget(
        wrap(AnimatedCount(value: 7, formatter: (n) => '$n items')),
      );
      expect(find.text('7 items'), findsOneWidget);
    });

    testWidgets('tweens between values on change', (tester) async {
      await tester.pumpWidget(
        wrap(AnimatedCount(value: 3, formatter: (n) => '$n items')),
      );
      expect(find.text('3 items'), findsOneWidget);

      await tester.pumpWidget(
        wrap(AnimatedCount(value: 7, formatter: (n) => '$n items')),
      );
      // Mid-transition shouldn't yet show the final target.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('7 items'), findsNothing);

      // After the full duration, the target is reached.
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('7 items'), findsOneWidget);
    });

    testWidgets('snaps to target when reduce-motion is active', (tester) async {
      await tester.pumpWidget(
        wrap(
          AnimatedCount(value: 3, formatter: (n) => '$n items'),
          disableAnimations: true,
        ),
      );

      await tester.pumpWidget(
        wrap(
          AnimatedCount(value: 9, formatter: (n) => '$n items'),
          disableAnimations: true,
        ),
      );

      // No pump loop needed — it should snap immediately.
      await tester.pump();
      expect(find.text('9 items'), findsOneWidget);
    });
  });
}
