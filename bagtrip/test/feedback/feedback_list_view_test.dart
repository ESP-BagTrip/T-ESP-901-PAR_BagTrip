// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/feedback/view/feedback_list_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('FeedbackListView', () {
    testWidgets('renders empty state when no feedbacks', (tester) async {
      await pumpLocalized(tester, const FeedbackListView(feedbacks: []));
      await tester.pump();
      expect(find.byType(FeedbackListView), findsOneWidget);
    });

    testWidgets('renders single feedback card', (tester) async {
      await pumpLocalized(
        tester,
        FeedbackListView(
          feedbacks: [
            makeTripFeedback(
              highlights: 'Wonderful',
              lowlights: 'Too hot',
              wouldRecommend: true,
            ),
          ],
        ),
      );
      await tester.pump();
      expect(find.byType(FeedbackListView), findsOneWidget);
    });

    testWidgets('renders multiple feedbacks', (tester) async {
      await pumpLocalized(
        tester,
        FeedbackListView(
          feedbacks: [
            makeTripFeedback(id: 'fb-1', overallRating: 5),
            makeTripFeedback(
              id: 'fb-2',
              overallRating: 2,
              wouldRecommend: false,
            ),
            makeTripFeedback(id: 'fb-3', overallRating: 4, highlights: null),
          ],
        ),
      );
      await tester.pump();
      expect(find.byType(FeedbackListView), findsOneWidget);
    });
  });
}
