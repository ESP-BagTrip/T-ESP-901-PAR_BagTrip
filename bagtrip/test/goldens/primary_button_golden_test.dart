@Tags(['golden'])
library;

import 'package:bagtrip/design/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('PrimaryButton goldens', () {
    testWidgets('default enabled', (tester) async {
      await setGoldenSize(tester);
      await tester.pumpWidget(
        goldenWrapper(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PrimaryButton(label: 'Create my trip', onPressed: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_default.png'),
      );
    });

    testWidgets('loading state', (tester) async {
      await setGoldenSize(tester);
      await tester.pumpWidget(
        goldenWrapper(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PrimaryButton(
              label: 'Create my trip',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_loading.png'),
      );
    });

    testWidgets('disabled (null onPressed)', (tester) async {
      await setGoldenSize(tester);
      await tester.pumpWidget(
        goldenWrapper(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: PrimaryButton(label: 'Create my trip'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_disabled.png'),
      );
    });
  });
}
