import 'package:bagtrip/personalization/widgets/companions_step_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('CompanionsStepContent', () {
    testWidgets('renders with null selection', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1600,
          child: CompanionsStepContent(selectedId: null, onSelect: (_) {}),
        ),
      );
      await tester.pump();
      expect(find.byType(CompanionsStepContent), findsOneWidget);
    });

    testWidgets('renders with couple selected', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1600,
          child: CompanionsStepContent(selectedId: 'couple', onSelect: (_) {}),
        ),
      );
      await tester.pump();
      expect(find.byType(CompanionsStepContent), findsOneWidget);
    });
  });
}
