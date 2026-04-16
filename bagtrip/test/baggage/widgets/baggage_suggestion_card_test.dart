import 'package:bagtrip/baggage/widgets/baggage_suggestion_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('BaggageSuggestionCard', () {
    testWidgets('renders with reason', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 200,
          child: BaggageSuggestionCard(
            suggestion: makeSuggestedBaggageItem(),
            onAccept: () {},
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(BaggageSuggestionCard), findsOneWidget);
    });

    testWidgets('renders without reason', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 200,
          child: BaggageSuggestionCard(
            suggestion: makeSuggestedBaggageItem(reason: null),
            onAccept: () {},
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(BaggageSuggestionCard), findsOneWidget);
    });
  });
}
