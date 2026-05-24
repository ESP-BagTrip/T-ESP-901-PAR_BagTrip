// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/flight_search/view/flight_search_form.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_widget.dart';

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
  });

  Future<void> pump(WidgetTester tester, FlightSearchState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<FlightSearchState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<FlightSearchBloc>.value(
        value: mockBloc,
        child: const SizedBox(
          width: 400,
          height: 800,
          child: FlightSearchForm(),
        ),
      ),
      size: const Size(400, 1200),
    );
    await tester.pump();
  }

  group('FlightSearchForm', () {
    testWidgets('renders on initial state', (tester) async {
      await pump(tester, FlightSearchInitial());
      expect(find.byType(FlightSearchForm), findsOneWidget);
    });

    testWidgets('renders default loaded state (one-way)', (tester) async {
      await pump(tester, FlightSearchLoaded());
      expect(find.byType(FlightSearchForm), findsOneWidget);
    });

    testWidgets('renders round trip loaded state with selected airports', (
      tester,
    ) async {
      await pump(
        tester,
        FlightSearchLoaded(
          tripTypeIndex: 1,
          departureAirport: const {
            'iataCode': 'CDG',
            'city': 'Paris',
            'name': 'Charles de Gaulle',
          },
          arrivalAirport: const {
            'iataCode': 'JFK',
            'city': 'New York',
            'name': 'JFK',
          },
          departureDate: DateTime(2025, 6, 10),
          returnDate: DateTime(2025, 6, 20),
          adults: 2,
          children: 1,
          infants: 0,
          selectedClass: 1,
          maxPrice: 800,
        ),
      );
      expect(find.byType(FlightSearchForm), findsOneWidget);
    });

    testWidgets('renders multi-destination trip type', (tester) async {
      await pump(tester, FlightSearchLoaded(tripTypeIndex: 2));
      expect(find.byType(FlightSearchForm), findsOneWidget);
    });

    testWidgets('renders loaded state with a validation/network error', (
      tester,
    ) async {
      await pump(
        tester,
        FlightSearchLoaded(
          error: const NetworkError('offline'),
          showValidationErrors: true,
        ),
      );
      expect(find.byType(FlightSearchForm), findsOneWidget);
    });
  });
}
