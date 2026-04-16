import 'package:bagtrip/activities/widgets/activity_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ActivityForm', () {
    testWidgets('renders in create mode', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1600,
          child: ActivityForm(tripId: 'trip-1', onSave: (_) {}),
        ),
      );
      await tester.pump();
      expect(find.byType(ActivityForm), findsOneWidget);
    });

    testWidgets('renders in edit mode with existing activity', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1600,
          child: ActivityForm(
            tripId: 'trip-1',
            activity: makeActivity(endTime: '11:00'),
            onSave: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ActivityForm), findsOneWidget);
    });

    testWidgets('renders with initialDate', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 1600,
          child: ActivityForm(
            tripId: 'trip-1',
            initialDate: DateTime(2024, 7, 15),
            onSave: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ActivityForm), findsOneWidget);
    });
  });
}
