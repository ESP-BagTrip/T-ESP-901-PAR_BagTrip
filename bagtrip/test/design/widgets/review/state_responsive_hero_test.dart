import 'package:bagtrip/design/subpage_state.dart';
import 'package:bagtrip/design/widgets/review/state_responsive_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Column(children: [child])),
  );

  group('StateResponsiveHero', () {
    testWidgets('sparse renders title + meta + trailing', (tester) async {
      await tester.pumpWidget(
        wrap(
          const StateResponsiveHero(
            title: 'Activities',
            density: HeroDensity.sparse,
            meta: Text('2 activities · 1 day'),
          ),
        ),
      );
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('2 activities · 1 day'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('dense renders compact title', (tester) async {
      await tester.pumpWidget(
        wrap(
          const StateResponsiveHero(
            title: 'Activities',
            density: HeroDensity.dense,
            meta: Text('12 activities · 4 days'),
          ),
        ),
      );
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('12 activities · 4 days'), findsOneWidget);
    });

    testWidgets('renders badge in top row when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          const StateResponsiveHero(
            title: 'Activities',
            density: HeroDensity.dense,
            badge: HeroBadge(label: 'READ ONLY'),
          ),
        ),
      );
      expect(find.text('READ ONLY'), findsOneWidget);
    });

    testWidgets('renders trailing actions', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          StateResponsiveHero(
            title: 'Activities',
            density: HeroDensity.sparse,
            trailing: [
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                onPressed: () => tapped = true,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.auto_awesome));
      expect(tapped, isTrue);
    });

    testWidgets('onBack override is called', (tester) async {
      var popped = false;
      await tester.pumpWidget(
        wrap(
          StateResponsiveHero(
            title: 'Activities',
            density: HeroDensity.sparse,
            onBack: () => popped = true,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(popped, isTrue);
    });
  });

  group('HeroBadge', () {
    testWidgets('uppercases label', (tester) async {
      await tester.pumpWidget(wrap(const HeroBadge(label: 'Read only')));
      expect(find.text('READ ONLY'), findsOneWidget);
    });
  });
}
