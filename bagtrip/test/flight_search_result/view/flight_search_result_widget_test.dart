// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/flight_search_result/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/flight_search_result/models/baggage_info.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bagtrip/flight_search_result/widgets/flight_search_result_widget.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

class _MockFlightSearchResultBloc
    extends MockBloc<FlightSearchResultEvent, FlightSearchResultState>
    implements FlightSearchResultBloc {}

Flight _makeFlight({
  String id = 'flight-1',
  double price = 150,
  String airline = 'Air France',
  DateTime? departureDateTime,
  String? returnDepartureTime,
  BaggageInfo? checkedBags,
  BaggageInfo? cabinBags,
}) {
  return Flight(
    id: id,
    departureTime: '08:00',
    arrivalTime: '10:30',
    departureAirport: 'Paris CDG',
    departureCode: 'CDG',
    arrivalAirport: 'London LHR',
    arrivalCode: 'LHR',
    duration: '2h30',
    airline: airline,
    price: price,
    departureDateTime: departureDateTime ?? DateTime(2025, 6, 15, 8),
    arrivalDateTime: DateTime(2025, 6, 15, 10, 30),
    returnDepartureTime: returnDepartureTime,
    checkedBags: checkedBags,
    cabinBags: cabinBags,
  );
}

FlightSearchResultLoaded _makeLoaded({
  List<Flight>? flights,
  List<Flight>? filteredFlights,
  Map<int, List<Flight>>? segmentResults,
  List<String>? segmentLabels,
}) {
  final f = flights ?? <Flight>[];
  return FlightSearchResultLoaded(
    flights: f,
    filteredFlights: filteredFlights ?? f,
    departureDate: DateTime(2025, 6, 15),
    departureCode: 'CDG',
    arrivalCode: 'LHR',
    adults: 1,
    children: 0,
    infants: 0,
    travelClass: 'ECONOMY',
    segmentResults: segmentResults,
    segmentLabels: segmentLabels,
  );
}

void main() {
  late _MockFlightSearchResultBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(FilterFlightsByPrice(null));
    registerFallbackValue(FlightSearchResultInitial());
  });

  setUp(() {
    mockBloc = _MockFlightSearchResultBloc();
  });

  Future<void> pump(WidgetTester tester, FlightSearchResultState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<FlightSearchResultState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<FlightSearchResultBloc>.value(
        value: mockBloc,
        child: const SizedBox(
          width: 400,
          height: 800,
          child: FlightSearchResultView(),
        ),
      ),
      size: const Size(800, 1400),
    );
    await tester.pump();
  }

  group('FlightSearchResultView', () {
    testWidgets('renders SizedBox.shrink on initial state', (tester) async {
      await pump(tester, FlightSearchResultInitial());
      expect(find.byType(FlightSearchResultView), findsOneWidget);
    });

    testWidgets('renders shimmer on loading state', (tester) async {
      await pump(tester, FlightSearchResultLoading());
      expect(find.byType(FlightSearchResultView), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await pump(
        tester,
        FlightSearchResultError(const NetworkError('offline')),
      );
      expect(find.byType(FlightSearchResultView), findsOneWidget);
    });

    testWidgets('renders empty loaded state (no flights at all)', (
      tester,
    ) async {
      await pump(tester, _makeLoaded());
      expect(find.byType(FlightSearchResultView), findsOneWidget);
    });

    testWidgets(
      'renders empty filtered state with flights present (price filter)',
      (tester) async {
        await pump(
          tester,
          _makeLoaded(
            flights: [_makeFlight(id: 'f1', price: 500)],
            filteredFlights: const [],
          ),
        );
        expect(find.byType(FlightSearchResultView), findsOneWidget);
      },
    );

    testWidgets('renders populated loaded state with flights', (tester) async {
      await pump(
        tester,
        _makeLoaded(
          flights: [
            _makeFlight(id: 'f1', price: 100),
            _makeFlight(
              id: 'f2',
              price: 200,
              checkedBags: const BaggageInfo(quantity: 1, weight: 23),
              cabinBags: const BaggageInfo(quantity: 1),
            ),
          ],
        ),
      );
      expect(find.byType(FlightSearchResultView), findsOneWidget);
    });

    testWidgets('renders multi-destination results with tabs', (tester) async {
      await pump(
        tester,
        _makeLoaded(
          flights: [_makeFlight(id: 'f1', price: 100)],
          segmentResults: {
            0: [_makeFlight(id: 's1', price: 100)],
            1: [_makeFlight(id: 's2', price: 120)],
          },
          segmentLabels: const ['CDG → LHR', 'LHR → JFK'],
        ),
      );
      expect(find.byType(FlightSearchResultView), findsOneWidget);
    });
  });
}
