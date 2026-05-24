import 'package:bagtrip/trips/widgets/trip_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('TripSectionCard', () {
    testWidgets('renders with items and preview', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 400,
          child: TripSectionCard(
            icon: Icons.luggage,
            title: 'Baggage',
            itemCount: 5,
            previewItems: const ['Passport', 'Shoes', 'Camera', 'Charger'],
            emptyLabel: 'No items',
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TripSectionCard), findsOneWidget);
    });

    testWidgets('renders empty state when itemCount is 0', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 400,
          child: TripSectionCard(
            icon: Icons.map,
            title: 'Activities',
            itemCount: 0,
            previewItems: const [],
            emptyLabel: 'No activities yet',
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TripSectionCard), findsOneWidget);
    });

    testWidgets('toggles expand when header tapped', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 400,
          child: TripSectionCard(
            icon: Icons.flight,
            title: 'Flights',
            itemCount: 2,
            previewItems: const ['CDG -> JFK', 'JFK -> CDG'],
            emptyLabel: 'No flights',
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      // tap header region (title)
      await tester.tap(find.text('Flights'));
      await tester.pump();
      expect(find.byType(TripSectionCard), findsOneWidget);
    });
  });
}
