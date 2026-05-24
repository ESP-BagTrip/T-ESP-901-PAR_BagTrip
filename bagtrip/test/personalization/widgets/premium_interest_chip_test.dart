import 'package:bagtrip/personalization/widgets/premium_interest_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('PremiumInterestChip', () {
    testWidgets('renders unselected', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 400,
          height: 200,
          child: PremiumInterestChip(
            label: 'Beach',
            selected: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PremiumInterestChip), findsOneWidget);
    });

    testWidgets('renders selected', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 400,
          height: 200,
          child: PremiumInterestChip(
            label: 'Culture',
            selected: true,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PremiumInterestChip), findsOneWidget);
    });
  });
}
