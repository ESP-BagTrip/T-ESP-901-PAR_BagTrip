import 'package:bagtrip/baggage/widgets/baggage_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('BaggageItemTile', () {
    testWidgets('renders unpacked item', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 200,
          child: BaggageItemTile(
            item: makeBaggageItem(),
            onToggle: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(BaggageItemTile), findsOneWidget);
    });

    testWidgets('renders packed item', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 200,
          child: BaggageItemTile(
            item: makeBaggageItem(
              isPacked: true,
              category: 'CLOTHING',
              quantity: 2,
            ),
            onToggle: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(BaggageItemTile), findsOneWidget);
    });

    testWidgets('renders in read-only mode', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 200,
          child: BaggageItemTile(
            item: makeBaggageItem(),
            isReadOnly: true,
            onToggle: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(BaggageItemTile), findsOneWidget);
    });
  });
}
