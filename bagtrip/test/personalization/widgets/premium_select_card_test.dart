import 'package:bagtrip/personalization/widgets/premium_select_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('PremiumSelectCard', () {
    testWidgets('renders with icon unselected', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 600,
          height: 200,
          child: PremiumSelectCard(
            icon: Icons.person_outline,
            label: 'Solo',
            selected: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PremiumSelectCard), findsOneWidget);
    });

    testWidgets('renders selected with description', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 600,
          height: 300,
          child: PremiumSelectCard(
            icon: Icons.hotel_outlined,
            label: 'Comfort',
            description: 'Balanced travel',
            selected: true,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PremiumSelectCard), findsOneWidget);
    });

    testWidgets('renders with emoji instead of icon', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 600,
          height: 200,
          child: PremiumSelectCard(
            emoji: '🌴',
            label: 'Beach',
            selected: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PremiumSelectCard), findsOneWidget);
    });
  });
}
