import 'package:bagtrip/design/widgets/review/activity_tile.dart';
import 'package:bagtrip/design/widgets/review/boarding_pass_card.dart';
import 'package:bagtrip/design/widgets/review/budget_stripe.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/design/widgets/review/hotel_stats_grid.dart';
import 'package:bagtrip/design/widgets/review/pack_item.dart';
import 'package:bagtrip/design/widgets/review/panel_chips_bar.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/review_hero.dart';
import 'package:bagtrip/design/widgets/review/timeline_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_widget.dart';

void main() {
  group('HeroNavButton', () {
    testWidgets('renders icon and fires onPressed', (tester) async {
      var tapped = false;
      await pumpLocalized(
        tester,
        Container(
          color: Colors.black,
          child: HeroNavButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => tapped = true,
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      await tester.tap(find.byType(HeroNavButton));
      expect(tapped, isTrue);
    });
  });

  group('PillCtaButton', () {
    testWidgets('renders label in filled variant and fires onTap', (
      tester,
    ) async {
      var tapped = false;
      await pumpLocalized(
        tester,
        PillCtaButton(label: 'Save', onTap: () => tapped = true),
      );
      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.byType(PillCtaButton));
      expect(tapped, isTrue);
    });

    testWidgets('shows spinner when isLoading', (tester) async {
      await pumpLocalized(
        tester,
        const PillCtaButton(label: 'Save', onTap: null, isLoading: true),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disabled when onTap is null and not loading', (tester) async {
      await pumpLocalized(
        tester,
        const PillCtaButton(label: 'Save', onTap: null),
      );
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('renders outlined variant', (tester) async {
      await pumpLocalized(
        tester,
        PillCtaButton(
          label: 'Complete',
          variant: PillVariant.outlined,
          onTap: () {},
        ),
      );
      expect(find.text('Complete'), findsOneWidget);
    });

    testWidgets('renders danger variant', (tester) async {
      await pumpLocalized(
        tester,
        PillCtaButton(
          label: 'Delete',
          variant: PillVariant.danger,
          onTap: () {},
        ),
      );
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  group('PanelChipsBar', () {
    testWidgets('renders labels without badges when incompleteFlags is null', (
      tester,
    ) async {
      late TabController controller;
      await pumpLocalized(
        tester,
        DefaultTabController(
          length: 3,
          child: Builder(
            builder: (context) {
              controller = DefaultTabController.of(context);
              return PanelChipsBar(
                labels: const ['A', 'B', 'C'],
                controller: controller,
              );
            },
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('asserts when incompleteFlags length mismatches', (
      tester,
    ) async {
      late TabController controller;
      await pumpLocalized(
        tester,
        DefaultTabController(
          length: 2,
          child: Builder(
            builder: (context) {
              controller = DefaultTabController.of(context);
              return const Placeholder();
            },
          ),
        ),
      );
      expect(
        () => PanelChipsBar(
          labels: const ['A', 'B'],
          controller: controller,
          incompleteFlags: const [true],
        ),
        throwsAssertionError,
      );
    });
  });

  group('HotelStatsGrid', () {
    testWidgets('renders 4 entries', (tester) async {
      await pumpLocalized(
        tester,
        const HotelStatsGrid(
          entries: [
            ('Check-in', '5 Jun'),
            ('Check-out', '10 Jun'),
            ('Nights', '5'),
            ('Per night', '120€'),
          ],
        ),
      );
      expect(find.text('CHECK-IN'), findsOneWidget);
      expect(find.text('5 Jun'), findsOneWidget);
      expect(find.text('Per night'.toUpperCase()), findsOneWidget);
    });

    testWidgets('renders empty when fewer than 4 entries', (tester) async {
      await pumpLocalized(tester, const HotelStatsGrid(entries: [('A', 'B')]));
      expect(find.text('A'.toUpperCase()), findsNothing);
    });
  });

  group('ActivityTile', () {
    testWidgets('renders title and category', (tester) async {
      await pumpLocalized(
        tester,
        const ActivityTile(
          title: 'Museum visit',
          description: 'Gulbenkian',
          category: 'CULTURE',
        ),
      );
      expect(find.text('Museum visit'), findsOneWidget);
      expect(find.text('Gulbenkian'), findsOneWidget);
      expect(find.text('CULTURE'), findsOneWidget);
    });

    testWidgets('becomes tappable when onTap is provided', (tester) async {
      var tapped = false;
      await pumpLocalized(
        tester,
        ActivityTile(
          title: 'Museum',
          description: '',
          category: 'CULTURE',
          onTap: () => tapped = true,
        ),
      );
      await tester.tap(find.byType(ActivityTile));
      expect(tapped, isTrue);
    });
  });

  group('PackItem', () {
    testWidgets('renders item and toggles on tap', (tester) async {
      var tapped = false;
      await pumpLocalized(
        tester,
        PackItem(
          item: 'Passport',
          reason: '',
          checked: false,
          onTap: () => tapped = true,
        ),
      );
      expect(find.text('Passport'), findsOneWidget);
      await tester.tap(find.byType(PackItem));
      expect(tapped, isTrue);
    });

    testWidgets('renders edit/delete icons when callbacks are provided', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        PackItem(
          item: 'Passport',
          reason: 'ID',
          checked: true,
          onTap: () {},
          onEdit: () {},
          onDelete: () {},
        ),
      );
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });

  group('TimelineCard', () {
    testWidgets('renders event title and subtitle', (tester) async {
      await pumpLocalized(
        tester,
        TimelineCard(
          event: const TimelineEvent(
            dayOffset: 0,
            type: TimelineEventType.activity,
            title: 'Walking tour',
            subtitle: 'Old town',
            badge: 'ACTIVITY',
          ),
          firstDate: DateTime(2026, 6),
        ),
      );
      expect(find.text('Walking tour'), findsOneWidget);
      expect(find.text('Old town'), findsOneWidget);
    });
  });

  group('BoardingPassCard', () {
    testWidgets('renders origin/destination and flight meta', (tester) async {
      await pumpLocalized(
        tester,
        const BoardingPassCard(
          title: 'Outbound',
          flight: BoardingPassModel(
            origin: 'CDG',
            destination: 'LIS',
            subtitle: 'AF123',
            departure: '08:00',
            arrival: '10:00',
            airlineLine: 'AIR FRANCE · OUTBOUND',
            flightDate: 'Thursday 5 June 2026',
          ),
        ),
      );
      expect(find.text('CDG'), findsOneWidget);
      expect(find.text('LIS'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
    });
  });

  group('BudgetStripe', () {
    testWidgets('renders total and entries', (tester) async {
      await pumpLocalized(
        tester,
        const BudgetStripe(
          total: 1000,
          subtitle: 'Estimation · 5 days',
          entries: [
            BudgetStripeEntry(
              label: 'Flights',
              amount: 300,
              color: Colors.blue,
            ),
            BudgetStripeEntry(label: 'Hotel', amount: 500, color: Colors.teal),
            BudgetStripeEntry(label: 'Food', amount: 200, color: Colors.orange),
          ],
        ),
      );
      expect(find.text('Flights'), findsOneWidget);
      expect(find.text('Hotel'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('supports onEntryTap', (tester) async {
      var tappedIndex = -1;
      await pumpLocalized(
        tester,
        BudgetStripe(
          total: 100,
          subtitle: 'Est',
          entries: const [
            BudgetStripeEntry(
              label: 'Flights',
              amount: 100,
              color: Colors.blue,
            ),
          ],
          onEntryTap: (index) => tappedIndex = index,
        ),
      );
      await tester.tap(find.text('Flights'));
      expect(tappedIndex, 0);
    });
  });

  group('ReviewHero', () {
    testWidgets('renders city, days, budget and fires back/close', (
      tester,
    ) async {
      var back = false;
      var close = false;
      await pumpLocalized(
        tester,
        ReviewHero(
          city: 'Lisbon',
          daysLabel: '5 DAYS',
          dateRangeLabel: '5 – 10 Jun',
          budgetLabel: '1 000 €',
          onBack: () => back = true,
          onClose: () => close = true,
        ),
      );
      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('1 000 €'), findsOneWidget);
      expect(find.text('5 – 10 Jun'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(back, isTrue);
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(close, isTrue);
    });

    testWidgets('shows overflow and trailing/status slots', (tester) async {
      var overflow = false;
      await pumpLocalized(
        tester,
        ReviewHero(
          city: 'Lisbon',
          daysLabel: '5 DAYS',
          dateRangeLabel: '5 – 10 Jun',
          budgetLabel: '1 000 €',
          onOverflow: () => overflow = true,
          trailing: const Icon(Icons.circle, key: Key('trailing-slot')),
          statusBadge: const Text('READ-ONLY', key: Key('status-badge-slot')),
        ),
      );
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      expect(overflow, isTrue);
      expect(find.byKey(const Key('trailing-slot')), findsOneWidget);
      expect(find.byKey(const Key('status-badge-slot')), findsOneWidget);
    });

    testWidgets('fires onEditDates when tapping the date/budget column', (
      tester,
    ) async {
      var edited = false;
      await pumpLocalized(
        tester,
        ReviewHero(
          city: 'Lisbon',
          daysLabel: '5 DAYS',
          dateRangeLabel: '5 – 10 Jun',
          budgetLabel: '1 000 €',
          onEditDates: () => edited = true,
        ),
      );
      await tester.tap(find.text('1 000 €'));
      expect(edited, isTrue);
    });
  });
}
