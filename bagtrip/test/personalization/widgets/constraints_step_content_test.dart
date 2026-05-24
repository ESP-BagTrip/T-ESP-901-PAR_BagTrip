import 'package:bagtrip/personalization/widgets/constraints_step_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('ConstraintsStepContent', () {
    testWidgets('renders with null value', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 400,
          child: ConstraintsStepContent(value: null, onChanged: (_) {}),
        ),
      );
      await tester.pump();
      expect(find.byType(ConstraintsStepContent), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders with prefilled value', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 400,
          child: ConstraintsStepContent(
            value: 'No Asia, April 10-20',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ConstraintsStepContent), findsOneWidget);
    });
  });
}
