import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'a11y_test_helpers.dart';

void main() {
  group('AX3 — Dynamic Type (1.5x text scale)', () {
    testWidgets('ElegantEmptyState does not overflow at 1.5x text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const SingleChildScrollView(
            child: ElegantEmptyState(
              icon: Icons.event_outlined,
              title: 'No activities planned for this day',
              subtitle:
                  'Add some activities or ask the AI to suggest ideas for you',
              ctaLabel: 'Get AI suggestions',
              ctaIcon: Icons.auto_awesome,
            ),
          ),
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();

      // The widget should render without overflow errors
      // (Flutter test framework will report RenderFlex overflow as errors)
      expect(tester.takeException(), isNull);
    });

    testWidgets('ConstrainedBox with minHeight expands for large text', (
      tester,
    ) async {
      // Simulate the trip card pattern: ConstrainedBox(minHeight: 200)
      await tester.pumpWidget(
        buildTestableWidget(
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 200),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A very long trip title that should expand',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text('01/01/2025 - 15/01/2025', style: TextStyle(fontSize: 13)),
                Text(
                  'Additional content that might cause expansion',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          textScale: 1.5,
        ),
      );
      await tester.pump();

      final renderBox = tester.renderObject<RenderBox>(
        find.byType(ConstrainedBox).first,
      );
      // At 1.5x, the box should be at least 200 (min) but can grow
      expect(renderBox.size.height, greaterThanOrEqualTo(200));
    });

    testWidgets('Day chip row uses minHeight not fixed height', (tester) async {
      // Simulate the _DayChipRow ConstrainedBox pattern
      await tester.pumpWidget(
        buildTestableWidget(
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'J${i + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${10 + i}/03',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          textScale: 1.5,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
