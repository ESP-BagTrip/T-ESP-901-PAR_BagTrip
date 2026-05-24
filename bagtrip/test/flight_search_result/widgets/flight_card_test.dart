// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/flight_search_result/models/baggage_info.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bagtrip/flight_search_result/widgets/flight_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

Flight _makeFlight({
  String id = 'flight-1',
  double price = 150,
  String? airline = 'Air France',
  String? aircraftType = 'A320',
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
    aircraftType: aircraftType,
    price: price,
    returnDepartureTime: returnDepartureTime,
    checkedBags: checkedBags,
    cabinBags: cabinBags,
  );
}

Future<void> _pumpCard(
  WidgetTester tester,
  Flight flight, {
  bool isSelected = false,
}) async {
  await pumpLocalized(
    tester,
    SizedBox(
      width: 800,
      child: FlightCard(flight: flight, isSelected: isSelected, onTap: () {}),
    ),
    size: const Size(800, 1200),
  );
  await tester.pump();
}

void main() {
  group('FlightCard', () {
    testWidgets('renders basic flight without baggage', (tester) async {
      await _pumpCard(tester, _makeFlight());
      expect(find.byType(FlightCard), findsOneWidget);
    });

    testWidgets('renders selected flight with full baggage info', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        _makeFlight(
          checkedBags: const BaggageInfo(
            quantity: 2,
            weight: 23,
            weightUnit: 'KG',
          ),
          cabinBags: const BaggageInfo(quantity: 1),
        ),
        isSelected: true,
      );
      expect(find.byType(FlightCard), findsOneWidget);
    });

    testWidgets('renders with cabin bag only', (tester) async {
      await _pumpCard(
        tester,
        _makeFlight(cabinBags: const BaggageInfo(quantity: 1)),
      );
      expect(find.byType(FlightCard), findsOneWidget);
    });

    testWidgets('renders with null airline and aircraft (fallback labels)', (
      tester,
    ) async {
      await _pumpCard(tester, _makeFlight(airline: null, aircraftType: null));
      expect(find.byType(FlightCard), findsOneWidget);
    });

    testWidgets('renders checked bag with weight only', (tester) async {
      await _pumpCard(
        tester,
        _makeFlight(
          checkedBags: const BaggageInfo(weight: 20, weightUnit: 'KG'),
        ),
      );
      expect(find.byType(FlightCard), findsOneWidget);
    });
  });
}
