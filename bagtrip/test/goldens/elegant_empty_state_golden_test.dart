@Tags(['golden'])
library;

import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('ElegantEmptyState goldens', () {
    testWidgets('default — icon + title only', (tester) async {
      await setGoldenSize(tester);
      await tester.pumpWidget(
        goldenWrapper(
          const ElegantEmptyState(
            icon: Icons.flight_takeoff,
            title: 'No trips yet',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ElegantEmptyState),
        matchesGoldenFile('goldens/elegant_empty_state_default.png'),
      );
    });

    testWidgets('with CTA button', (tester) async {
      await setGoldenSize(tester);
      await tester.pumpWidget(
        goldenWrapper(
          ElegantEmptyState(
            icon: Icons.flight_takeoff,
            title: 'No trips yet',
            subtitle: 'Plan your first adventure',
            ctaLabel: 'Plan a trip',
            ctaIcon: Icons.add,
            onCta: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ElegantEmptyState),
        matchesGoldenFile('goldens/elegant_empty_state_with_cta.png'),
      );
    });

    testWidgets('with secondary action', (tester) async {
      await setGoldenSize(tester);
      await tester.pumpWidget(
        goldenWrapper(
          ElegantEmptyState(
            icon: Icons.luggage,
            title: 'Baggage list empty',
            subtitle: 'Add items to your packing list',
            ctaLabel: 'Add items',
            onCta: () {},
            secondaryCtaLabel: 'Use AI suggestions',
            onSecondaryCta: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ElegantEmptyState),
        matchesGoldenFile('goldens/elegant_empty_state_with_secondary.png'),
      );
    });
  });
}
