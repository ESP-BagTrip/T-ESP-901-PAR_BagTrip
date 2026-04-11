import 'package:bagtrip/personalization/widgets/welcome_step_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('WelcomeStepContent', () {
    testWidgets('renders with onStart only', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1200,
          child: WelcomeStepContent(totalSteps: 6, onStart: () {}),
        ),
      );
      await tester.pump();
      expect(find.byType(WelcomeStepContent), findsOneWidget);
    });

    testWidgets('renders with onStart and onSkip', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1200,
          child: WelcomeStepContent(
            totalSteps: 6,
            onStart: () {},
            onSkip: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(WelcomeStepContent), findsOneWidget);
    });

    testWidgets('renders with small width', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 320,
          height: 1200,
          child: WelcomeStepContent(totalSteps: 5, onStart: () {}),
        ),
      );
      await tester.pump();
      expect(find.byType(WelcomeStepContent), findsOneWidget);
    });
  });
}
