import 'package:bagtrip/trip_detail/view/panels/skipped_panel_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_widget.dart';

void main() {
  group('SkippedPanelState', () {
    testWidgets('renders title (upper), message, resume CTA', (tester) async {
      await pumpLocalized(
        tester,
        SkippedPanelState(
          title: 'Flights are on you',
          message: 'BagTrip will not track your flights.',
          resumeLabel: 'Let BagTrip track my flights again',
          onResume: () {},
        ),
      );
      expect(find.text('FLIGHTS ARE ON YOU'), findsOneWidget);
      expect(find.text('BagTrip will not track your flights.'), findsOneWidget);
      expect(find.text('Let BagTrip track my flights again'), findsOneWidget);
    });

    testWidgets('resume CTA fires callback', (tester) async {
      var tapped = false;
      await pumpLocalized(
        tester,
        SkippedPanelState(
          title: 'Stays are on you',
          message: 'You are handling accommodations yourself.',
          resumeLabel: 'Resume',
          onResume: () => tapped = true,
        ),
      );
      await tester.tap(find.text('Resume'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('hides resume CTA when onResume is null (viewer mode)', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const SkippedPanelState(
          title: 'Stays are on you',
          message: 'Accommodations are not tracked.',
          resumeLabel: 'Resume',
        ),
      );
      expect(find.text('Resume'), findsNothing);
    });
  });
}
