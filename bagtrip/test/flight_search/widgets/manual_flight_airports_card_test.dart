// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/flight_search/widgets/manual_flight_airports_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

class _MockFlightSearchBloc
    extends MockBloc<FlightSearchEvent, FlightSearchState>
    implements FlightSearchBloc {}

void main() {
  late _MockFlightSearchBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(SetTripType(0));
    registerFallbackValue(FlightSearchInitial());
  });

  setUp(() {
    mockBloc = _MockFlightSearchBloc();
    when(() => mockBloc.state).thenReturn(FlightSearchLoaded());
    whenListen(
      mockBloc,
      const Stream<FlightSearchState>.empty(),
      initialState: FlightSearchLoaded(),
    );
  });

  Future<void> pump(WidgetTester tester, FlightSearchLoaded state) async {
    await pumpLocalized(
      tester,
      BlocProvider<FlightSearchBloc>.value(
        value: mockBloc,
        child: SizedBox(
          width: 400,
          child: ManualFlightAirportsCard(state: state),
        ),
      ),
      size: const Size(400, 1000),
    );
    await tester.pump();
  }

  group('ManualFlightAirportsCard', () {
    testWidgets('renders with no airports selected', (tester) async {
      await pump(tester, FlightSearchLoaded());
      expect(find.byType(ManualFlightAirportsCard), findsOneWidget);
    });

    testWidgets('renders with a departure airport only', (tester) async {
      await pump(
        tester,
        FlightSearchLoaded(
          departureAirport: const {
            'iataCode': 'CDG',
            'city': 'Paris',
            'name': 'Charles de Gaulle',
          },
        ),
      );
      expect(find.byType(ManualFlightAirportsCard), findsOneWidget);
    });

    testWidgets('renders with both departure and arrival airports', (
      tester,
    ) async {
      await pump(
        tester,
        FlightSearchLoaded(
          departureAirport: const {
            'iataCode': 'CDG',
            'city': 'Paris',
            'name': 'Charles de Gaulle',
          },
          arrivalAirport: const {
            'iataCode': 'JFK',
            'city': 'New York',
            'name': 'John F. Kennedy',
          },
        ),
      );
      expect(find.byType(ManualFlightAirportsCard), findsOneWidget);
    });

    testWidgets('renders with airport missing city/name fields', (
      tester,
    ) async {
      await pump(
        tester,
        FlightSearchLoaded(
          departureAirport: const {'iataCode': 'NCE'},
          arrivalAirport: const {'iataCode': 'LHR', 'name': 'Heathrow'},
        ),
      );
      expect(find.byType(ManualFlightAirportsCard), findsOneWidget);
    });
  });
}
