// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/booking/bloc/booking_bloc.dart';
import 'package:bagtrip/flight_result_details/bloc/flight_result_details_bloc.dart';
import 'package:bagtrip/flight_result_details/view/flight_result_details_view.dart';
import 'package:bagtrip/flight_search_result/models/baggage_info.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

class _MockFlightResultDetailsBloc
    extends MockBloc<FlightResultDetailsEvent, FlightResultDetailsState>
    implements FlightResultDetailsBloc {}

class _MockBookingBloc extends MockBloc<BookingEvent, BookingState>
    implements BookingBloc {}

Flight _makeFlight({
  String id = 'flight-1',
  String? tripId,
  String? flightOfferId,
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
    airline: 'Air France',
    aircraftType: 'A320',
    price: 150,
    departureDateTime: DateTime(2025, 6, 15, 8),
    arrivalDateTime: DateTime(2025, 6, 15, 10, 30),
    returnDepartureTime: returnDepartureTime,
    returnArrivalTime: returnDepartureTime != null ? '16:00' : null,
    returnDepartureCode: returnDepartureTime != null ? 'LHR' : null,
    returnArrivalCode: returnDepartureTime != null ? 'CDG' : null,
    returnDuration: returnDepartureTime != null ? '2h30' : null,
    tripId: tripId,
    flightOfferId: flightOfferId,
    checkedBags: checkedBags,
    cabinBags: cabinBags,
  );
}

void main() {
  late _MockFlightResultDetailsBloc mockDetailsBloc;
  late _MockBookingBloc mockBookingBloc;

  setUpAll(() {
    registerFallbackValue(LoadFlightDetails(_makeFlight()));
    registerFallbackValue(FlightResultDetailsInitial());
    registerFallbackValue(LoadBookings());
    registerFallbackValue(BookingInitial());
  });

  setUp(() {
    mockDetailsBloc = _MockFlightResultDetailsBloc();
    mockBookingBloc = _MockBookingBloc();

    when(() => mockBookingBloc.state).thenReturn(BookingInitial());
    whenListen(
      mockBookingBloc,
      const Stream<BookingState>.empty(),
      initialState: BookingInitial(),
    );
  });

  Future<void> pump(
    WidgetTester tester,
    FlightResultDetailsState detailsSeed,
  ) async {
    when(() => mockDetailsBloc.state).thenReturn(detailsSeed);
    whenListen(
      mockDetailsBloc,
      const Stream<FlightResultDetailsState>.empty(),
      initialState: detailsSeed,
    );
    await pumpLocalized(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<FlightResultDetailsBloc>.value(value: mockDetailsBloc),
          BlocProvider<BookingBloc>.value(value: mockBookingBloc),
        ],
        child: const FlightResultDetailsView(),
      ),
      size: const Size(800, 1600),
    );
    await tester.pump();
  }

  group('FlightResultDetailsView', () {
    testWidgets('renders loading view on initial state', (tester) async {
      await pump(tester, FlightResultDetailsInitial());
      expect(find.byType(FlightResultDetailsView), findsOneWidget);
    });

    testWidgets('renders one-way flight loaded state', (tester) async {
      await pump(tester, FlightResultDetailsLoaded(_makeFlight()));
      expect(find.byType(FlightResultDetailsView), findsOneWidget);
    });

    testWidgets('renders round-trip flight loaded state', (tester) async {
      await pump(
        tester,
        FlightResultDetailsLoaded(_makeFlight(returnDepartureTime: '14:00')),
      );
      expect(find.byType(FlightResultDetailsView), findsOneWidget);
    });

    testWidgets('renders loaded state with baggage info', (tester) async {
      await pump(
        tester,
        FlightResultDetailsLoaded(
          _makeFlight(
            checkedBags: const BaggageInfo(
              quantity: 1,
              weight: 23,
              weightUnit: 'KG',
            ),
            cabinBags: const BaggageInfo(quantity: 1),
          ),
        ),
      );
      expect(find.byType(FlightResultDetailsView), findsOneWidget);
    });

    testWidgets(
      'renders loaded state with tripId and flightOfferId (book button shown)',
      (tester) async {
        await pump(
          tester,
          FlightResultDetailsLoaded(
            _makeFlight(tripId: 'trip-1', flightOfferId: 'offer-1'),
          ),
        );
        expect(find.byType(FlightResultDetailsView), findsOneWidget);
      },
    );
  });
}
