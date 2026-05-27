// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/models/user_role.dart';
import 'package:bagtrip/trip_detail/view/panels/trip_panel_empty_state.dart';
import 'package:bagtrip/design/widgets/review/boarding_pass_card.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/validation_status.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/view/panels/flights_panel.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_fixtures.dart';

class _MockTripDetailBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

void main() {
  late _MockTripDetailBloc bloc;

  setUpAll(() {
    registerFallbackValue(CreateFlightFromDetail(data: <String, dynamic>{}));
    registerFallbackValue(DeleteFlightFromDetail(flightId: 'x'));
    registerFallbackValue(ValidateFlightFromDetail(flightId: 'x'));
  });

  setUp(() {
    bloc = _MockTripDetailBloc();
    when(() => bloc.state).thenReturn(
      TripDetailLoaded(
        trip: makeTrip(),
        activities: const [],
        flights: const [],
        accommodations: const [],
        baggageItems: const [],
        shares: const [],
        userRole: UserRole.owner,
        selectedDayIndex: 0,
        deferredLoaded: true,
        sectionErrors: const {},
        completionResult: const CompletionResult(percentage: 0, segments: {}),
      ),
    );
  });

  Future<void> pump(WidgetTester tester, Widget panel) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider<TripDetailBloc>.value(value: bloc, child: panel),
        ),
      ),
    );
  }

  testWidgets('empty state shows CTA when canEdit is true', (tester) async {
    await pump(
      tester,
      const FlightsPanel(
        tripId: 'trip-1',
        flights: [],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(TripPanelEmptyState), findsOneWidget);
    expect(find.text('Add now'), findsOneWidget);
  });

  testWidgets('empty state shows countdown when trip start is in future', (
    tester,
  ) async {
    final start = DateTime.now().add(const Duration(days: 26));
    await pump(
      tester,
      FlightsPanel(
        tripId: 'trip-1',
        flights: const [],
        tripStartDate: start,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.textContaining('26 days'), findsOneWidget);
  });

  testWidgets('renders one BoardingPassCard per flight', (tester) async {
    final flights = [
      makeManualFlight(id: 'f1', flightNumber: 'AF123'),
      makeManualFlight(id: 'f2', flightNumber: 'AF456'),
    ];
    await pump(
      tester,
      FlightsPanel(
        tripId: 'trip-1',
        flights: flights,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(BoardingPassCard), findsNWidgets(2));
  });

  testWidgets('suggested flight shows IA capsule on card', (tester) async {
    final flights = [
      makeManualFlight(
        id: 'f1',
        flightNumber: 'AF123',
        validationStatus: ValidationStatus.suggested,
      ),
    ];
    await pump(
      tester,
      FlightsPanel(
        tripId: 'trip-1',
        flights: flights,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.text('IA'), findsOneWidget);
  });

  testWidgets('PanelFab visible in edit mode', (tester) async {
    await pump(
      tester,
      FlightsPanel(
        tripId: 'trip-1',
        flights: [makeManualFlight()],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(PanelFab), findsOneWidget);
  });

  testWidgets('PanelFab hidden in viewer mode', (tester) async {
    await pump(
      tester,
      FlightsPanel(
        tripId: 'trip-1',
        flights: [makeManualFlight()],
        canEdit: false,
        isCompleted: false,
        role: 'VIEWER',
      ),
    );
    expect(find.byType(PanelFab), findsNothing);
  });

  testWidgets('sorts flights by departure date ascending', (tester) async {
    final later = makeManualFlight(
      id: 'later',
      flightNumber: 'AF999',
      departureDate: DateTime(2026, 12, 1),
    );
    final earlier = makeManualFlight(
      id: 'earlier',
      flightNumber: 'AF111',
      departureDate: DateTime(2026, 6, 1),
    );
    await pump(
      tester,
      FlightsPanel(
        tripId: 'trip-1',
        flights: [later, earlier],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    // First BoardingPassCard in document order should correspond to the
    // earlier-departing flight.
    final cards = tester
        .widgetList<BoardingPassCard>(find.byType(BoardingPassCard))
        .toList();
    expect(cards, hasLength(2));
    expect(cards.first.flight.airlineLine, contains('AF111'));
  });

  testWidgets(
    'suggested flight uses horizontal dismissible and validates on right swipe',
    (tester) async {
      final suggested = makeManualFlight(
        id: 's1',
        validationStatus: ValidationStatus.suggested,
      );
      await pump(
        tester,
        FlightsPanel(
          tripId: 'trip-1',
          flights: [suggested],
          canEdit: true,
          isCompleted: false,
          role: 'OWNER',
        ),
      );

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.direction, DismissDirection.horizontal);
      expect(dismissible.background, isNotNull);
      expect(dismissible.secondaryBackground, isNotNull);

      await tester.drag(find.byType(BoardingPassCard), const Offset(400, 0));
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(any(that: isA<ValidateFlightFromDetail>())),
      ).called(1);
    },
  );

  testWidgets('manual flight only allows delete swipe direction', (
    tester,
  ) async {
    final manual = makeManualFlight(
      id: 'm1',
      validationStatus: ValidationStatus.manual,
    );
    await pump(
      tester,
      FlightsPanel(
        tripId: 'trip-1',
        flights: [manual],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );

    final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    expect(dismissible.direction, DismissDirection.endToStart);
  });
}
