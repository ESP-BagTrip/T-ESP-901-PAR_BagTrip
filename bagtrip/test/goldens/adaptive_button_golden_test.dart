@Tags(['golden'])
library;

import 'package:bagtrip/components/adaptive/adaptive_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('AdaptiveButton goldens', () {
    testWidgets('default enabled', (tester) async {
      await setGoldenSize(tester);
      await tester.pumpWidget(
        goldenWrapper(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AdaptiveButton(label: 'Continue', onPressed: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AdaptiveButton),
        matchesGoldenFile('goldens/adaptive_button_default.png'),
      );
    });

    testWidgets('loading state', (tester) async {
      await setGoldenSize(tester);
      await tester.pumpWidget(
        goldenWrapper(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AdaptiveButton(
              label: 'Continue',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(AdaptiveButton),
        matchesGoldenFile('goldens/adaptive_button_loading.png'),
      );
    });

    testWidgets('disabled (null onPressed)', (tester) async {
      await setGoldenSize(tester);
      await tester.pumpWidget(
        goldenWrapper(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AdaptiveButton(label: 'Continue'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AdaptiveButton),
        matchesGoldenFile('goldens/adaptive_button_disabled.png'),
      );
    });
  });
}
