import 'package:bagtrip/design/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('renders label', (tester) async {
      await pumpLocalized(
        tester,
        PrimaryButton(label: 'Continue', onPressed: () {}),
      );
      await tester.pump();
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('renders with icon prefix', (tester) async {
      await pumpLocalized(
        tester,
        PrimaryButton(
          label: 'Next',
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {},
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('shows spinner when isLoading', (tester) async {
      await pumpLocalized(
        tester,
        PrimaryButton(label: 'Saving', isLoading: true, onPressed: () {}),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await pumpLocalized(tester, const PrimaryButton(label: 'Disabled'));
      await tester.pump();
      expect(find.byType(PrimaryButton), findsOneWidget);
    });
  });
}
