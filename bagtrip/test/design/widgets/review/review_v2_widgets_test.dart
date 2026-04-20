// Widget tests for the review step v2 components (editorial single-scroll UX).
// ignore_for_file: avoid_redundant_argument_values

// BudgetStripeEntry lives in budget_stripe.dart and is re-used as the entry
// type for ReviewBudgetReveal.
import 'package:bagtrip/design/widgets/review/budget_stripe.dart';
import 'package:bagtrip/design/widgets/review/review_budget_reveal.dart';
import 'package:bagtrip/design/widgets/review/review_cinematic_hero.dart';
import 'package:bagtrip/design/widgets/review/review_day_card.dart';
import 'package:bagtrip/design/widgets/review/review_day_timeline.dart';
import 'package:bagtrip/design/widgets/review/review_decision_inline.dart';
import 'package:bagtrip/design/widgets/review/review_inline_flight.dart';
import 'package:bagtrip/design/widgets/review/review_inline_hotel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_widget.dart';

void main() {
  group('ReviewCinematicHero', () {
    testWidgets('renders city, country and metadata', (tester) async {
      await pumpLocalized(
        tester,
        const ReviewCinematicHero(
          city: 'Lisbon',
          country: 'Portugal',
          dateRangeLabel: '12 — 19 Apr',
          durationLabel: '7 days',
          travelersLabel: '2 travelers',
          coverImageUrl: 'https://example.com/cover.jpg',
        ),
      );
      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('PORTUGAL'), findsOneWidget);
      expect(find.text('12 — 19 Apr'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('2 travelers'), findsOneWidget);
    });

    testWidgets('back and close buttons fire their callbacks', (tester) async {
      var backTapped = false;
      var closeTapped = false;
      await pumpLocalized(
        tester,
        ReviewCinematicHero(
          city: 'Lisbon',
          country: 'Portugal',
          dateRangeLabel: '12 — 19 Apr',
          durationLabel: '7 days',
          travelersLabel: '2 travelers',
          coverImageUrl: 'https://example.com/cover.jpg',
          onBack: () => backTapped = true,
          onClose: () => closeTapped = true,
        ),
      );
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(backTapped, isTrue);
      expect(closeTapped, isTrue);
    });

    testWidgets(
      'never renders an edit-dates affordance (review is read-only)',
      (tester) async {
        await pumpLocalized(
          tester,
          const ReviewCinematicHero(
            city: 'Lisbon',
            country: 'Portugal',
            dateRangeLabel: '12 — 19 Apr',
            durationLabel: '7 days',
            travelersLabel: '2 travelers',
            coverImageUrl: 'https://example.com/cover.jpg',
          ),
        );
        expect(find.byIcon(Icons.edit_outlined), findsNothing);
      },
    );
  });

  group('ReviewInlineFlight', () {
    const data = ReviewInlineFlightData(
      originIata: 'CDG',
      destinationIata: 'LIS',
      departureTime: '14:20',
      arrivalTime: '16:40',
      durationLabel: '2h20',
      airline: 'Air France · AF1234',
      priceLabel: '240 €',
      tagLabel: 'Outbound',
    );

    testWidgets('renders IATA codes, times, duration and price', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: ReviewInlineFlight(data: data),
        ),
      );
      expect(find.text('CDG'), findsOneWidget);
      expect(find.text('LIS'), findsOneWidget);
      expect(find.text('14:20'), findsOneWidget);
      expect(find.text('16:40'), findsOneWidget);
      expect(find.text('2h20'), findsOneWidget);
      expect(find.text('240 €'), findsOneWidget);
      expect(find.text('OUTBOUND'), findsOneWidget);
    });

    testWidgets('omits tag when empty', (tester) async {
      await pumpLocalized(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: ReviewInlineFlight(
            data: ReviewInlineFlightData(
              originIata: 'CDG',
              destinationIata: 'LIS',
              departureTime: '14:20',
              arrivalTime: '16:40',
              durationLabel: '',
              airline: 'Air France',
              priceLabel: '',
              tagLabel: '',
            ),
          ),
        ),
      );
      expect(find.text('OUTBOUND'), findsNothing);
    });

    testWidgets('renders em-dash placeholder when IATA codes are empty', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: ReviewInlineFlight(
            data: ReviewInlineFlightData(
              originIata: '',
              destinationIata: '',
              departureTime: '',
              arrivalTime: '',
              durationLabel: '',
              airline: '',
              priceLabel: '',
              tagLabel: '',
            ),
          ),
        ),
      );
      expect(find.text('—'), findsNWidgets(2));
    });
  });

  group('ReviewInlineHotel', () {
    testWidgets('renders name, stars and composed subtitle', (tester) async {
      await pumpLocalized(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: ReviewInlineHotel(
            data: ReviewInlineHotelData(
              name: 'Memmo Alfama',
              rating: 4,
              arrivalLabel: 'Check-in',
              staySummary: '6 nights',
              subtitle: 'Alfama district',
            ),
          ),
        ),
      );
      expect(find.text('Memmo Alfama'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.text('CHECK-IN'), findsOneWidget);
      expect(find.text('6 nights · Alfama district'), findsOneWidget);
    });

    testWidgets('hides stars row when rating is 0', (tester) async {
      await pumpLocalized(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: ReviewInlineHotel(
            data: ReviewInlineHotelData(
              name: 'Unrated Inn',
              rating: 0,
              arrivalLabel: 'Check-in',
              staySummary: '2 nights',
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });
  });

  group('ReviewDayCard', () {
    testWidgets('renders serif day number, uppercase date, and events', (
      tester,
    ) async {
      const data = ReviewDayCardData(
        dayNumber: 1,
        dateLabel: 'Mon 12 Apr',
        flights: [
          ReviewInlineFlightData(
            originIata: 'CDG',
            destinationIata: 'LIS',
            departureTime: '14:20',
            arrivalTime: '16:40',
            durationLabel: '2h20',
            airline: 'AF',
            priceLabel: '',
            tagLabel: 'Outbound',
          ),
        ],
        hotelArrival: ReviewInlineHotelData(
          name: 'Memmo Alfama',
          rating: 4,
          arrivalLabel: 'Check-in',
          staySummary: '6 nights',
        ),
        activities: [
          ReviewDayActivity(title: 'Tram 28', description: 'Hop on'),
        ],
      );
      await pumpLocalized(
        tester,
        const ReviewDayCard(
          data: data,
          freeDayLabel: 'A free day',
          dayTitle: 'Mon 12 Apr',
        ),
      );
      expect(find.text('01'), findsOneWidget);
      expect(find.text('MON 12 APR'), findsOneWidget);
      expect(find.byType(ReviewInlineFlight), findsOneWidget);
      expect(find.byType(ReviewInlineHotel), findsOneWidget);
      expect(find.text('Tram 28'), findsOneWidget);
      expect(find.text('Hop on'), findsOneWidget);
    });

    testWidgets('shows free-day note when day has no events', (tester) async {
      const data = ReviewDayCardData(
        dayNumber: 2,
        dateLabel: 'Tue 13 Apr',
        flights: [],
        hotelArrival: null,
        activities: [],
      );
      await pumpLocalized(
        tester,
        const ReviewDayCard(
          data: data,
          freeDayLabel: 'A free day',
          dayTitle: 'Tue 13 Apr',
        ),
      );
      expect(find.text('A free day'), findsOneWidget);
    });
  });

  group('ReviewDayTimeline', () {
    testWidgets('iterates days without rendering a section header', (
      tester,
    ) async {
      const days = [
        ReviewDayCardData(
          dayNumber: 1,
          dateLabel: 'Mon',
          flights: [],
          hotelArrival: null,
          activities: [ReviewDayActivity(title: 'A')],
        ),
        ReviewDayCardData(
          dayNumber: 2,
          dateLabel: 'Tue',
          flights: [],
          hotelArrival: null,
          activities: [ReviewDayActivity(title: 'B')],
        ),
      ];
      await pumpLocalized(
        tester,
        ReviewDayTimeline(
          days: days,
          freeDayLabel: 'A free day',
          dayTitleBuilder: (data) => data.dateLabel,
        ),
      );
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('ReviewBudgetReveal', () {
    testWidgets('renders eyebrow, total, per-person line and legend', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const ReviewBudgetReveal(
          header: 'The budget',
          perPersonLabel: '925 € per traveler',
          total: 1850,
          entries: [
            BudgetStripeEntry(
              label: 'Flights',
              amount: 480,
              color: Colors.blue,
            ),
          ],
          subtitle: 'estimation · 7 days',
        ),
        size: const Size(420, 900),
      );
      expect(find.text('THE BUDGET'), findsOneWidget);
      expect(find.text('1850 €'), findsOneWidget);
      expect(find.text('925 € per traveler'), findsOneWidget);
      expect(find.text('Flights'), findsOneWidget);
      expect(find.text('480 €'), findsOneWidget);
    });

    testWidgets('hides per-person line when empty', (tester) async {
      await pumpLocalized(
        tester,
        const ReviewBudgetReveal(
          header: 'The budget',
          perPersonLabel: '',
          total: 1000,
          entries: [],
          subtitle: 'estimation',
        ),
      );
      expect(find.textContaining('per traveler'), findsNothing);
    });
  });

  group('ReviewDecisionInline', () {
    testWidgets('renders header and both labels, fires callbacks', (
      tester,
    ) async {
      var primaryTapped = false;
      var secondaryTapped = false;
      await pumpLocalized(
        tester,
        ReviewDecisionInline(
          header: 'YOUR CALL',
          primaryLabel: 'Plan this trip',
          secondaryLabel: 'See other destinations',
          onPrimary: () => primaryTapped = true,
          onSecondary: () => secondaryTapped = true,
        ),
      );
      expect(find.text('YOUR CALL'), findsOneWidget);
      expect(find.text('Plan this trip'), findsOneWidget);
      expect(find.text('See other destinations'), findsOneWidget);
      await tester.tap(find.text('Plan this trip'));
      await tester.tap(find.text('See other destinations'));
      await tester.pump();
      expect(primaryTapped, isTrue);
      expect(secondaryTapped, isTrue);
    });

    testWidgets('shows spinner when isPrimaryLoading', (tester) async {
      await pumpLocalized(
        tester,
        const ReviewDecisionInline(
          header: 'YOUR CALL',
          primaryLabel: 'Plan this trip',
          secondaryLabel: 'See other destinations',
          onPrimary: null,
          onSecondary: null,
          isPrimaryLoading: true,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
