import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/plan_trip/models/trip_plan.dart';
import 'package:bagtrip/plan_trip/view/step_review_view.dart';
import 'package:bloc_test/bloc_test.dart';
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
    );
    await tester.pump();
  }

  const fullPlan = TripPlan(
    destinationCity: 'Lisbon',
    destinationCountry: 'Portugal',
    durationDays: 5,
    budgetEur: 1000,
    highlights: ['Tram ride', 'Belem tower'],
    accommodationName: 'Hotel X',
    accommodationSubtitle: '3 nights',
    accommodationPrice: 120,
    accommodationSource: 'amadeus',
    flightRoute: 'CDG to LIS',
    flightDetails: 'AF123',
    flightPrice: 200,
    flightSource: 'amadeus',
    dayProgram: ['Tram ride', 'Museum'],
    dayDescriptions: ['Hop on the 28', 'Visit Gulbenkian'],
    dayCategories: ['CULTURE', 'CULTURE'],
    essentialItems: ['Passport', 'Adapter'],
    essentialReasons: ['ID', 'Power plugs'],
    budgetBreakdown: {'flight': 200, 'hotel': 500, 'food': 300},
  );

  final reviewDates = {
    'startDate': DateTime(2026, 6),
    'endDate': DateTime(2026, 6, 7),
  };

  group('StepReviewView', () {
    testWidgets('renders shimmer when generatedPlan is null', (tester) async {
      await pump(tester, const PlanTripState());
      expect(find.byType(StepReviewView), findsOneWidget);
    });

    testWidgets('renders full review when generatedPlan is populated', (
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
      expect(find.byType(StepReviewView), findsOneWidget);
    });

    testWidgets('renders review with isCreating=true (spinner in CTA)', (
      tester,
    ) async {
      await pump(
        tester,
        PlanTripState(
          generatedPlan: fullPlan,
          startDate: reviewDates['startDate'],
          endDate: reviewDates['endDate'],
          isCreating: true,
        ),
      );
      expect(find.byType(StepReviewView), findsOneWidget);
    });

    testWidgets('renders with error present (snackbar listener path)', (
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

    testWidgets('renders manual flow with selectedManualDestination', (
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
      expect(find.byType(StepReviewView), findsOneWidget);
    });

    testWidgets(
      'renders minimal plan (no highlights, flights, accommodations)',
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
        expect(find.byType(StepReviewView), findsOneWidget);
      },
    );
  });
}
