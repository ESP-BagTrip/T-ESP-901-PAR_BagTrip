import 'package:bagtrip/personalization/widgets/travel_types_step_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('TravelTypesStepContent', () {
    testWidgets('renders with empty selection', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1200,
          child: TravelTypesStepContent(
            selectedIds: const <String>{},
            onToggle: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TravelTypesStepContent), findsOneWidget);
    });

    testWidgets('renders with one selected', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1200,
          child: TravelTypesStepContent(
            selectedIds: const {'beach'},
            onToggle: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TravelTypesStepContent), findsOneWidget);
    });

    testWidgets('renders with multiple selected', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1200,
          child: TravelTypesStepContent(
            selectedIds: const {'beach', 'city', 'gastronomy'},
            onToggle: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TravelTypesStepContent), findsOneWidget);
    });
  });
}
