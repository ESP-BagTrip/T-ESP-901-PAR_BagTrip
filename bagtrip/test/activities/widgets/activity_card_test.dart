import 'package:bagtrip/activities/widgets/activity_card.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ActivityCard', () {
    testWidgets('renders manual activity', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 300,
          child: ActivityCard(
            activity: makeActivity(),
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ActivityCard), findsOneWidget);
    });

    testWidgets('renders suggested activity with validate callback', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 300,
          child: ActivityCard(
            activity: makeActivity(
              validationStatus: ValidationStatus.suggested,
              endTime: '11:00',
            ),
            onEdit: () {},
            onDelete: () {},
            onValidate: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ActivityCard), findsOneWidget);
    });

    testWidgets('renders validated activity in viewer mode', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 300,
          child: ActivityCard(
            activity: makeActivity(
              validationStatus: ValidationStatus.validated,
            ),
            onEdit: () {},
            onDelete: () {},
            isViewer: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ActivityCard), findsOneWidget);
    });
  });
}
