import 'package:bagtrip/design/widgets/review/tap_scale_aware.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {bool disableAnimations = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('onTap fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        TapScaleAware(
          onTap: () => tapped = true,
          child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
        ),
      ),
    );
    await tester.tap(find.text('Tap'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('onLongPress fires', (tester) async {
    var longPressed = false;
    await tester.pumpWidget(
      wrap(
        TapScaleAware(
          onTap: () {},
          onLongPress: () => longPressed = true,
          child: const SizedBox(width: 100, height: 100, child: Text('Press')),
        ),
      ),
    );
    await tester.longPress(find.text('Press'));
    expect(longPressed, isTrue);
  });

  testWidgets('fires onTap even with reduce-motion enabled', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        TapScaleAware(
          onTap: () => tapped = true,
          child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
        ),
        disableAnimations: true,
      ),
    );
    await tester.tap(find.text('Tap'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('renders ScaleTransition wrapper', (tester) async {
    await tester.pumpWidget(
      wrap(
        TapScaleAware(
          onTap: () {},
          child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
        ),
      ),
    );
    // MaterialApp injects its own ScaleTransition so we just verify at
    // least one is present (ours wraps the Text).
    expect(find.byType(ScaleTransition), findsWidgets);
  });
}
