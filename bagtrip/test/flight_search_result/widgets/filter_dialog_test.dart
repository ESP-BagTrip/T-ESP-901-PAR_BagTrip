// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/flight_search_result/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bagtrip/flight_search_result/widgets/filter_dialog.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

class _MockFlightSearchResultBloc
    extends MockBloc<FlightSearchResultEvent, FlightSearchResultState>
    implements FlightSearchResultBloc {}

Flight _makeFlight({String id = 'f1', String? airline = 'Air France'}) {
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
    price: 100,
  );
}

FlightSearchResultLoaded _makeLoaded({
  List<Flight>? flights,
  String? priceSort,
  String? selectedAirline,
  bool? cabinBagIncluded,
  bool? checkedBagIncluded,
  TimeOfDay? departureTimeBefore,
  TimeOfDay? departureTimeAfter,
}) {
  final f = flights ?? [_makeFlight()];
  return FlightSearchResultLoaded(
    flights: f,
    filteredFlights: f,
    departureDate: DateTime(2025, 6, 15),
    departureCode: 'CDG',
    arrivalCode: 'LHR',
    adults: 1,
    children: 0,
    infants: 0,
    travelClass: 'ECONOMY',
    priceSort: priceSort,
    selectedAirline: selectedAirline,
    cabinBagIncluded: cabinBagIncluded,
    checkedBagIncluded: checkedBagIncluded,
    departureTimeBefore: departureTimeBefore,
    departureTimeAfter: departureTimeAfter,
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
    final seed = _makeLoaded();
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<FlightSearchResultState>.empty(),
      initialState: seed,
    );
  });

  Future<void> pump(WidgetTester tester, FlightSearchResultLoaded state) async {
    await pumpLocalized(
      tester,
      BlocProvider<FlightSearchResultBloc>.value(
        value: mockBloc,
        child: SizedBox(
          width: 500,
          height: 700,
          child: FilterDialog(state: state),
        ),
      ),
      size: const Size(500, 800),
    );
    await tester.pump();
  }

  group('FilterDialog', () {
    testWidgets('renders with no flights (no airlines dropdown)', (
      tester,
    ) async {
      await pump(tester, _makeLoaded(flights: const []));
      expect(find.byType(FilterDialog), findsOneWidget);
    });

    testWidgets('renders with airlines dropdown and no filters applied', (
      tester,
    ) async {
      await pump(
        tester,
        _makeLoaded(
          flights: [
            _makeFlight(id: 'f1', airline: 'Air France'),
            _makeFlight(id: 'f2', airline: 'Lufthansa'),
          ],
        ),
      );
      expect(find.byType(FilterDialog), findsOneWidget);
    });

    testWidgets('renders with all filters pre-selected', (tester) async {
      await pump(
        tester,
        _makeLoaded(
          flights: [_makeFlight(id: 'f1', airline: 'Air France')],
          priceSort: 'lowest',
          selectedAirline: 'Air France',
          cabinBagIncluded: true,
          checkedBagIncluded: true,
          departureTimeBefore: const TimeOfDay(hour: 20, minute: 0),
          departureTimeAfter: const TimeOfDay(hour: 6, minute: 0),
        ),
      );
      expect(find.byType(FilterDialog), findsOneWidget);
    });
  });
}
