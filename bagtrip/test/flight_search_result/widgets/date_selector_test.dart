// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/flight_search_result/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bagtrip/flight_search_result/widgets/date_selector.dart';
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
  String id = 'f1',
  double price = 100,
  DateTime? departureDateTime,
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
    price: price,
    departureDateTime: departureDateTime,
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

  Future<void> pump(
    WidgetTester tester, {
    required List<Flight> flights,
    int selectedDateIndex = 1,
    Size size = const Size(400, 600),
  }) async {
    await pumpLocalized(
      tester,
      BlocProvider<FlightSearchResultBloc>.value(
        value: mockBloc,
        child: SizedBox(
          width: size.width,
          child: DateSelector(
            selectedDateIndex: selectedDateIndex,
            departureDate: DateTime(2025, 6, 15),
            flights: flights,
          ),
        ),
      ),
      size: size,
    );
    await tester.pump();
  }

  group('DateSelector', () {
    testWidgets('renders on wide screen with flights', (tester) async {
      await pump(
        tester,
        flights: [
          _makeFlight(
            id: 'f1',
            price: 100,
            departureDateTime: DateTime(2025, 6, 15, 8),
          ),
          _makeFlight(
            id: 'f2',
            price: 200,
            departureDateTime: DateTime(2025, 6, 16, 9),
          ),
        ],
      );
      expect(find.byType(DateSelector), findsOneWidget);
    });

    testWidgets('renders on small screen (iPhone SE width) with no flights', (
      tester,
    ) async {
      await pump(tester, flights: const [], size: const Size(320, 700));
      expect(find.byType(DateSelector), findsOneWidget);
    });

    testWidgets('renders with flight missing departureDateTime (fallback)', (
      tester,
    ) async {
      await pump(tester, flights: [_makeFlight(id: 'f1', price: 150)]);
      expect(find.byType(DateSelector), findsOneWidget);
    });
  });
}
