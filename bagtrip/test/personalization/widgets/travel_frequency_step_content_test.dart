import 'package:bagtrip/personalization/widgets/travel_frequency_step_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('TravelFrequencyStepContent', () {
    testWidgets('renders with null selection', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1200,
          child: TravelFrequencyStepContent(selectedId: null, onSelect: (_) {}),
        ),
      );
      await tester.pump();
      expect(find.byType(TravelFrequencyStepContent), findsOneWidget);
    });

    testWidgets('renders with selected option', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1200,
          child: TravelFrequencyStepContent(
            selectedId: '3-5',
            onSelect: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TravelFrequencyStepContent), findsOneWidget);
    });
  });
}
