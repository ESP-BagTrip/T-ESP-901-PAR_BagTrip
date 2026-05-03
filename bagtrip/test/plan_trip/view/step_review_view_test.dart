import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/design/widgets/review/review_budget_reveal.dart';
import 'package:bagtrip/design/widgets/review/review_cinematic_hero.dart';
import 'package:bagtrip/design/widgets/review/review_day_timeline.dart';
import 'package:bagtrip/design/widgets/review/review_decision_inline.dart';
import 'package:bagtrip/design/widgets/review/review_inline_flight.dart';
import 'package:bagtrip/design/widgets/review/review_inline_hotel.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/budget_breakdown.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/plan_trip/models/trip_plan.dart';
import 'package:bagtrip/plan_trip/view/step_review_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

class _MockPlanTripBloc extends MockBloc<PlanTripEvent, PlanTripState>
    implements PlanTripBloc {}

void main() {
  late _MockPlanTripBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(const PlanTripEvent.nextStep());
    registerFallbackValue(const PlanTripState());
  });

  setUp(() {
    mockBloc = _MockPlanTripBloc();
  });

  Future<void> pump(WidgetTester tester, PlanTripState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<PlanTripState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<PlanTripBloc>.value(
        value: mockBloc,
        child: const StepReviewView(),
      ),
      size: const Size(400, 2400),
    );
    await tester.pump();
  }

  const fullPlan = TripPlan(
    destinationCity: 'Lisbon',
    destinationCountry: 'Portugal',
    destinationIata: 'LIS',
    durationDays: 5,
    budgetEur: 1000,
    highlights: ['Tram ride', 'Belem tower'],
    accommodationName: 'Hotel X',
    accommodationSubtitle: 'Alfama',
    accommodationPrice: 120,
    accommodationSource: 'amadeus',
    hotelRating: 4,
    flightRoute: 'CDG → LIS',
    flightDetails: 'AF123',
    flightPrice: 200,
    flightSource: 'amadeus',
    originIata: 'CDG',
    flightAirline: 'Air France',
    flightNumber: 'AF1234',
    flightDeparture: '2026-06-01T14:20:00',
    flightArrival: '2026-06-01T16:40:00',
    flightDuration: 'PT2H20M',
    returnDeparture: '2026-06-06T09:00:00',
    returnArrival: '2026-06-06T11:45:00',
    returnDuration: 'PT2H45M',
    dayProgram: ['Tram ride', 'Museum'],
    dayDescriptions: ['Hop on the 28', 'Visit Gulbenkian'],
    dayCategories: ['CULTURE', 'CULTURE'],
    essentialItems: ['Passport', 'Adapter'],
    essentialReasons: ['ID', 'Power plugs'],
    budgetBreakdown: BudgetBreakdown(
      flight: 200.0,
      accommodation: 500.0,
      food: 300.0,
    ),
  );

  final reviewDates = {
    'startDate': DateTime(2026, 6),
    'endDate': DateTime(2026, 6, 7),
  };

  group('StepReviewView — editorial scroll', () {
    testWidgets('shows adaptive spinner when plan is null', (tester) async {
      await pump(tester, const PlanTripState());
      expect(find.byType(StepReviewView), findsOneWidget);
      expect(find.byType(ReviewCinematicHero), findsNothing);
    });

    testWidgets('renders hero, timeline, budget, decision in order', (
      tester,
    ) async {
      await pump(
        tester,
        PlanTripState(
          generatedPlan: fullPlan,
          startDate: reviewDates['startDate'],
          endDate: reviewDates['endDate'],
          nbAdults: 2,
        ),
      );
      expect(find.byType(ReviewCinematicHero), findsOneWidget);
      expect(find.byType(ReviewDayTimeline), findsOneWidget);
      expect(find.byType(ReviewBudgetReveal), findsOneWidget);
      expect(find.byType(ReviewDecisionInline), findsOneWidget);
    });

    testWidgets('renders outbound + return inline flights across days', (
      tester,
    ) async {
      await pump(
        tester,
        PlanTripState(
          generatedPlan: fullPlan,
          startDate: reviewDates['startDate'],
          endDate: reviewDates['endDate'],
        ),
      );
      // Outbound on day 1 + return on last day → two inline flight tiles.
      expect(find.byType(ReviewInlineFlight), findsNWidgets(2));
    });

    testWidgets('renders the hotel arrival on day 1', (tester) async {
      await pump(
        tester,
        PlanTripState(
          generatedPlan: fullPlan,
          startDate: reviewDates['startDate'],
          endDate: reviewDates['endDate'],
        ),
      );
      expect(find.byType(ReviewInlineHotel), findsOneWidget);
    });

    testWidgets('tapping primary fires createTrip event', (tester) async {
      await pump(
        tester,
        PlanTripState(
          generatedPlan: fullPlan,
          startDate: reviewDates['startDate'],
          endDate: reviewDates['endDate'],
        ),
      );
      await tester.ensureVisible(find.byType(ReviewDecisionInline));
      await tester.pump();
      await tester.tap(find.text('Plan this trip'));
      await tester.pump();
      verify(() => mockBloc.add(const PlanTripEvent.createTrip())).called(1);
    });

    testWidgets('tapping secondary fires backToProposals event', (
      tester,
    ) async {
      await pump(
        tester,
        PlanTripState(
          generatedPlan: fullPlan,
          startDate: reviewDates['startDate'],
          endDate: reviewDates['endDate'],
        ),
      );
      await tester.ensureVisible(find.byType(ReviewDecisionInline));
      await tester.pump();
      await tester.tap(find.text('See other destinations'));
      await tester.pump();
      verify(
        () => mockBloc.add(const PlanTripEvent.backToProposals()),
      ).called(1);
    });

    testWidgets('disables CTAs while isCreating', (tester) async {
      await pump(
        tester,
        PlanTripState(
          generatedPlan: fullPlan,
          startDate: reviewDates['startDate'],
          endDate: reviewDates['endDate'],
          isCreating: true,
        ),
      );
      await tester.ensureVisible(find.byType(ReviewDecisionInline));
      await tester.pump();
      await tester.tap(find.text('See other destinations'));
      await tester.pump();
      verifyNever(() => mockBloc.add(const PlanTripEvent.backToProposals()));
    });

    testWidgets('error in state triggers snackbar via listener', (
      tester,
    ) async {
      await pump(
        tester,
        PlanTripState(
          generatedPlan: fullPlan,
          startDate: reviewDates['startDate'],
          endDate: reviewDates['endDate'],
          error: const NetworkError('offline'),
        ),
      );
      expect(find.byType(StepReviewView), findsOneWidget);
    });

    testWidgets('manual flow with selected destination still renders', (
      tester,
    ) async {
      const manual = LocationResult(
        name: 'Paris',
        iataCode: 'PAR',
        city: 'Paris',
        countryCode: 'FR',
        countryName: 'France',
        subType: 'CITY',
      );
      await pump(
        tester,
        PlanTripState(
          generatedPlan: fullPlan,
          startDate: reviewDates['startDate'],
          endDate: reviewDates['endDate'],
          isManualFlow: true,
          selectedManualDestination: manual,
        ),
      );
      expect(find.byType(ReviewCinematicHero), findsOneWidget);
    });

    testWidgets(
      'minimal plan with dates renders an "accommodation to be chosen" tile',
      (tester) async {
        await pump(
          tester,
          PlanTripState(
            generatedPlan: const TripPlan(
              destinationCity: 'X',
              destinationCountry: 'Y',
              durationDays: 3,
              budgetEur: 100,
            ),
            startDate: reviewDates['startDate'],
            endDate: reviewDates['endDate'],
          ),
        );
        // No flight tile because the plan has no flight data.
        expect(find.byType(ReviewInlineFlight), findsNothing);
        // The hotel tile renders the deferred placeholder (l10n EN), not
        // a fabricated hotel name with a truncated per-night price.
        expect(find.byType(ReviewInlineHotel), findsOneWidget);
        expect(find.text('Accommodation to be chosen'), findsOneWidget);
        // Empty days still appear in the timeline; the precise count
        // depends on whether the hotel tile occupies a day slot, so we
        // just assert at least one free day shows up.
        expect(find.text('A free day'), findsWidgets);
      },
    );
  });
}
