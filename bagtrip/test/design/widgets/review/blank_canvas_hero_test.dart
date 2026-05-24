import 'package:bagtrip/design/widgets/review/blank_canvas_hero.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {bool disableAnimations = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: SizedBox(height: 800, child: child)),
      ),
    );
  }

  group('BlankCanvasHero', () {
    testWidgets('renders icon + title + subtitle + primary', (tester) async {
      await tester.pumpWidget(
        wrap(
          BlankCanvasHero(
            icon: Icons.event_outlined,
            title: 'Your itinerary is empty',
            subtitle: 'Plan what makes this trip worth remembering.',
            primaryLabel: 'Add your first activity',
            onPrimary: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Your itinerary is empty'), findsOneWidget);
      expect(
        find.text('Plan what makes this trip worth remembering.'),
        findsOneWidget,
      );
      expect(find.text('Add your first activity'), findsOneWidget);
      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
      expect(find.byType(PillCtaButton), findsOneWidget);
    });

    testWidgets('renders secondary CTA when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          BlankCanvasHero(
            icon: Icons.event_outlined,
            title: 'Empty',
            subtitle: 'Add something.',
            primaryLabel: 'Add',
            onPrimary: () {},
            secondaryLabel: 'Let AI plan',
            onSecondary: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Let AI plan'), findsOneWidget);
      expect(find.byType(PillCtaButton), findsNWidgets(2));
    });

    testWidgets('primary CTA fires onPrimary', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          BlankCanvasHero(
            icon: Icons.event_outlined,
            title: 'Empty',
            subtitle: 'Add something.',
            primaryLabel: 'Add',
            onPrimary: () => tapped = true,
          ),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Add'));
      expect(tapped, isTrue);
    });

    testWidgets('back button fires onBack override', (tester) async {
      var back = false;
      await tester.pumpWidget(
        wrap(
          BlankCanvasHero(
            icon: Icons.event_outlined,
            title: 'Empty',
            subtitle: 'Add something.',
            primaryLabel: 'Add',
            onPrimary: () {},
            onBack: () => back = true,
          ),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(back, isTrue);
    });

    testWidgets('snaps entrance when reduceMotion is on', (tester) async {
      await tester.pumpWidget(
        wrap(
          BlankCanvasHero(
            icon: Icons.event_outlined,
            title: 'Empty',
            subtitle: 'Add something.',
            primaryLabel: 'Add',
            onPrimary: () {},
          ),
          disableAnimations: true,
        ),
      );
      // A single pump is enough — the entrance controller should be at 1.0
      // right after mount.
      await tester.pump();
      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('custom breathingIconBuilder is invoked', (tester) async {
      var builderCalled = false;
      await tester.pumpWidget(
        wrap(
          BlankCanvasHero(
            icon: Icons.event_outlined,
            title: 'Empty',
            subtitle: 'Add something.',
            primaryLabel: 'Add',
            onPrimary: () {},
            breathingIconBuilder: (ctx, child, t) {
              builderCalled = true;
              return child;
            },
          ),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      expect(builderCalled, isTrue);
    });
  });

  group('BlankCanvasBreathing', () {
    test('all helpers return non-null builders', () {
      expect(BlankCanvasBreathing.pulse(), isNotNull);
      expect(BlankCanvasBreathing.tilt(), isNotNull);
      expect(BlankCanvasBreathing.softShadow(), isNotNull);
      expect(BlankCanvasBreathing.rotate(), isNotNull);
      expect(BlankCanvasBreathing.drift(), isNotNull);
    });
  });
}
