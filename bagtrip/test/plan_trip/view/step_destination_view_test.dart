import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/ai_destination.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/plan_trip/view/step_destination_view.dart';
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
        child: const StepDestinationView(),
      ),
    );
    await tester.pump();
  }

  const paris = LocationResult(
    name: 'Paris',
    iataCode: 'PAR',
    city: 'Paris',
    countryCode: 'FR',
    countryName: 'France',
    subType: 'CITY',
  );
  const rome = LocationResult(
    name: 'Rome',
    iataCode: 'ROM',
    city: 'Rome',
    countryCode: 'IT',
    countryName: 'Italy',
    subType: 'CITY',
  );
  const aiLisbon = AiDestination(city: 'Lisbon', country: 'Portugal');
  const aiBarcelona = AiDestination(city: 'Barcelona', country: 'Spain');

  group('StepDestinationView', () {
    testWidgets('renders default state', (tester) async {
      await pump(tester, const PlanTripState());
      expect(find.byType(StepDestinationView), findsOneWidget);
    });

    testWidgets('renders while searching destinations', (tester) async {
      await pump(tester, const PlanTripState(isSearching: true));
      expect(find.byType(StepDestinationView), findsOneWidget);
    });

    testWidgets('renders search results panel when results populated', (
      tester,
    ) async {
      await pump(tester, const PlanTripState(searchResults: [paris, rome]));
      expect(find.byType(StepDestinationView), findsOneWidget);
    });

    testWidgets('renders selected manual destination badge', (tester) async {
      await pump(tester, const PlanTripState(selectedManualDestination: paris));
      expect(find.byType(StepDestinationView), findsOneWidget);
    });

    testWidgets('renders while loading AI suggestions', (tester) async {
      await pump(tester, const PlanTripState(isLoadingAiSuggestions: true));
      expect(find.byType(StepDestinationView), findsOneWidget);
    });

    testWidgets('renders with AI suggestions populated', (tester) async {
      await pump(
        tester,
        const PlanTripState(aiSuggestions: [aiLisbon, aiBarcelona]),
      );
      expect(find.byType(StepDestinationView), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await pump(tester, const PlanTripState(error: NetworkError('offline')));
      expect(find.byType(StepDestinationView), findsOneWidget);
    });
  });
}
