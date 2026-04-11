// Test fixtures enumerate default values explicitly so it's obvious at a
// glance which parameters the scenario is pinning.
// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/flight_search_result/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';

Flight _makeFlight({
  String id = 'flight-1',
  double price = 100,
  String airline = 'AF',
  String duration = '2h30',
  String departureTime = '08:00',
  DateTime? departureDateTime,
}) {
  return Flight(
    id: id,
    departureTime: departureTime,
    arrivalTime: '10:30',
    departureAirport: 'Paris CDG',
    departureCode: 'CDG',
    arrivalAirport: 'London LHR',
    arrivalCode: 'LHR',
    duration: duration,
    airline: airline,
    price: price,
    departureDateTime: departureDateTime,
  );
}

void main() {
  late MockLocationService mockLocationService;
  late MockTransportRepository mockTransportRepository;

  setUp(() {
    mockLocationService = MockLocationService();
    mockTransportRepository = MockTransportRepository();
  });

  FlightSearchResultBloc buildBloc() => FlightSearchResultBloc(
    locationService: mockLocationService,
    transportRepository: mockTransportRepository,
  );

  final baseDeparture = DateTime(2025, 6, 15);

  LoadFlights baseLoadEvent({String? tripId, double? maxPrice}) => LoadFlights(
    tripId: tripId,
    departureCode: 'CDG',
    arrivalCode: 'LHR',
    departureDate: baseDeparture,
    adults: 1,
    children: 0,
    infants: 0,
    travelClass: 'economy',
    maxPrice: maxPrice,
  );

  group('FlightSearchResultBloc', () {
    // ── LoadFlights ─────────────────────────────────────────────────────

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'LoadFlights (proxy path, no tripId) '
      'emits [Loading, Loaded] with the flights returned by location_service',
      build: () {
        when(
          () => mockLocationService.searchFlights(
            departureCode: any(named: 'departureCode'),
            arrivalCode: any(named: 'arrivalCode'),
            departureDate: any(named: 'departureDate'),
            returnDate: any(named: 'returnDate'),
            adults: any(named: 'adults'),
            children: any(named: 'children'),
            infants: any(named: 'infants'),
            travelClass: any(named: 'travelClass'),
            multiDestSegments: any(named: 'multiDestSegments'),
          ),
        ).thenAnswer(
          (_) async => Success([
            _makeFlight(id: 'f1', price: 100),
            _makeFlight(id: 'f2', price: 200),
          ]),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(baseLoadEvent()),
      expect: () => [
        isA<FlightSearchResultLoading>(),
        isA<FlightSearchResultLoaded>(),
      ],
      verify: (bloc) {
        final state = bloc.state as FlightSearchResultLoaded;
        expect(state.flights.length, 2);
        expect(state.filteredFlights.length, 2);
        expect(state.tripId, isNull);
        verify(
          () => mockLocationService.searchFlights(
            departureCode: 'CDG',
            arrivalCode: 'LHR',
            departureDate: '2025-06-15',
            adults: 1,
            children: 0,
            infants: 0,
            travelClass: 'ECONOMY',
          ),
        ).called(1);
        // Should NOT call the persisted endpoint when tripId is null.
        verifyNever(
          () => mockTransportRepository.searchFlightsPersisted(
            tripId: any(named: 'tripId'),
            originIata: any(named: 'originIata'),
            destinationIata: any(named: 'destinationIata'),
            departureDate: any(named: 'departureDate'),
            adults: any(named: 'adults'),
            travelClass: any(named: 'travelClass'),
            currency: any(named: 'currency'),
          ),
        );
      },
    );

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'LoadFlights with maxPrice filters results on the initial emit',
      build: () {
        when(
          () => mockLocationService.searchFlights(
            departureCode: any(named: 'departureCode'),
            arrivalCode: any(named: 'arrivalCode'),
            departureDate: any(named: 'departureDate'),
            returnDate: any(named: 'returnDate'),
            adults: any(named: 'adults'),
            children: any(named: 'children'),
            infants: any(named: 'infants'),
            travelClass: any(named: 'travelClass'),
            multiDestSegments: any(named: 'multiDestSegments'),
          ),
        ).thenAnswer(
          (_) async => Success([
            _makeFlight(id: 'cheap', price: 80),
            _makeFlight(id: 'mid', price: 150),
            _makeFlight(id: 'expensive', price: 300),
          ]),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(baseLoadEvent(maxPrice: 200)),
      verify: (bloc) {
        final state = bloc.state as FlightSearchResultLoaded;
        expect(state.flights.length, 3);
        expect(state.filteredFlights.length, 2);
        expect(state.filteredFlights.map((f) => f.id), ['cheap', 'mid']);
        expect(state.maxPrice, 200);
      },
    );

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'LoadFlights emits [Loading, Error] when the search fails',
      build: () {
        when(
          () => mockLocationService.searchFlights(
            departureCode: any(named: 'departureCode'),
            arrivalCode: any(named: 'arrivalCode'),
            departureDate: any(named: 'departureDate'),
            returnDate: any(named: 'returnDate'),
            adults: any(named: 'adults'),
            children: any(named: 'children'),
            infants: any(named: 'infants'),
            travelClass: any(named: 'travelClass'),
            multiDestSegments: any(named: 'multiDestSegments'),
          ),
        ).thenAnswer((_) async => const Failure(NetworkError('offline')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(baseLoadEvent()),
      expect: () => [
        isA<FlightSearchResultLoading>(),
        isA<FlightSearchResultError>(),
      ],
      verify: (bloc) {
        final state = bloc.state as FlightSearchResultError;
        expect(state.error, isA<NetworkError>());
      },
    );

    // ── FilterFlightsByPrice ────────────────────────────────────────────

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'FilterFlightsByPrice re-filters the already-loaded list',
      build: () => buildBloc(),
      seed: () => FlightSearchResultLoaded(
        flights: [
          _makeFlight(id: 'a', price: 50),
          _makeFlight(id: 'b', price: 150),
          _makeFlight(id: 'c', price: 250),
        ],
        filteredFlights: [
          _makeFlight(id: 'a', price: 50),
          _makeFlight(id: 'b', price: 150),
          _makeFlight(id: 'c', price: 250),
        ],
        departureDate: baseDeparture,
        departureCode: 'CDG',
        arrivalCode: 'LHR',
        adults: 1,
        children: 0,
        infants: 0,
        travelClass: 'economy',
      ),
      act: (bloc) => bloc.add(FilterFlightsByPrice(100)),
      verify: (bloc) {
        final state = bloc.state as FlightSearchResultLoaded;
        expect(state.filteredFlights.length, 1);
        expect(state.filteredFlights.first.id, 'a');
        expect(state.maxPrice, 100);
      },
    );

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'FilterFlightsByPrice(null) restores the full flight list',
      build: () => buildBloc(),
      seed: () => FlightSearchResultLoaded(
        flights: [
          _makeFlight(id: 'a', price: 50),
          _makeFlight(id: 'b', price: 150),
          _makeFlight(id: 'c', price: 250),
        ],
        filteredFlights: [_makeFlight(id: 'a', price: 50)],
        maxPrice: 100,
        departureDate: baseDeparture,
        departureCode: 'CDG',
        arrivalCode: 'LHR',
        adults: 1,
        children: 0,
        infants: 0,
        travelClass: 'economy',
      ),
      act: (bloc) => bloc.add(FilterFlightsByPrice(null)),
      verify: (bloc) {
        // NB: `maxPrice` is not cleared on the state (freezed `copyWith`
        // treats `null` as "leave unchanged"), but the filteredFlights
        // list IS restored to the full set. Document the current behavior
        // here; tightening it would require an explicit "clear filter"
        // flag on the event.
        final state = bloc.state as FlightSearchResultLoaded;
        expect(state.filteredFlights.length, 3);
      },
    );

    // ── SortFlights ─────────────────────────────────────────────────────

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'SortFlights(price) sorts ascending',
      build: () => buildBloc(),
      seed: () => FlightSearchResultLoaded(
        flights: [],
        filteredFlights: [
          _makeFlight(id: 'c', price: 300),
          _makeFlight(id: 'a', price: 100),
          _makeFlight(id: 'b', price: 200),
        ],
        departureDate: baseDeparture,
        departureCode: 'CDG',
        arrivalCode: 'LHR',
        adults: 1,
        children: 0,
        infants: 0,
        travelClass: 'economy',
      ),
      act: (bloc) => bloc.add(SortFlights('price')),
      verify: (bloc) {
        final state = bloc.state as FlightSearchResultLoaded;
        expect(state.filteredFlights.map((f) => f.id), ['a', 'b', 'c']);
        expect(state.sortBy, 'price');
      },
    );

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'SortFlights(departure) sorts by departure time ascending',
      build: () => buildBloc(),
      seed: () => FlightSearchResultLoaded(
        flights: [],
        filteredFlights: [
          _makeFlight(id: 'late', departureTime: '22:00'),
          _makeFlight(id: 'early', departureTime: '06:00'),
          _makeFlight(id: 'noon', departureTime: '12:00'),
        ],
        departureDate: baseDeparture,
        departureCode: 'CDG',
        arrivalCode: 'LHR',
        adults: 1,
        children: 0,
        infants: 0,
        travelClass: 'economy',
      ),
      act: (bloc) => bloc.add(SortFlights('departure')),
      verify: (bloc) {
        final state = bloc.state as FlightSearchResultLoaded;
        expect(state.filteredFlights.map((f) => f.id), [
          'early',
          'noon',
          'late',
        ]);
      },
    );

    // ── SelectFlight ────────────────────────────────────────────────────

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'SelectFlight stores the selection on the loaded state',
      build: () => buildBloc(),
      seed: () => FlightSearchResultLoaded(
        flights: [],
        filteredFlights: [],
        departureDate: baseDeparture,
        departureCode: 'CDG',
        arrivalCode: 'LHR',
        adults: 1,
        children: 0,
        infants: 0,
        travelClass: 'economy',
      ),
      act: (bloc) => bloc.add(SelectFlight(_makeFlight(id: 'chosen'))),
      verify: (bloc) {
        final state = bloc.state as FlightSearchResultLoaded;
        expect(state.selectedFlight?.id, 'chosen');
      },
    );

    // ── ApplyFilters ────────────────────────────────────────────────────

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'ApplyFilters(airline) keeps only matching airline',
      build: () => buildBloc(),
      seed: () => FlightSearchResultLoaded(
        flights: [
          _makeFlight(id: 'af1', airline: 'AF', price: 100),
          _makeFlight(id: 'lh1', airline: 'LH', price: 120),
          _makeFlight(id: 'af2', airline: 'AF', price: 150),
        ],
        filteredFlights: [],
        departureDate: baseDeparture,
        departureCode: 'CDG',
        arrivalCode: 'LHR',
        adults: 1,
        children: 0,
        infants: 0,
        travelClass: 'economy',
      ),
      act: (bloc) => bloc.add(ApplyFilters(selectedAirline: 'AF')),
      verify: (bloc) {
        final state = bloc.state as FlightSearchResultLoaded;
        expect(state.filteredFlights.length, 2);
        expect(state.filteredFlights.every((f) => f.airline == 'AF'), isTrue);
        expect(state.selectedAirline, 'AF');
      },
    );

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'ApplyFilters(priceSort=lowest) sorts ascending',
      build: () => buildBloc(),
      seed: () => FlightSearchResultLoaded(
        flights: [
          _makeFlight(id: 'c', price: 300),
          _makeFlight(id: 'a', price: 100),
          _makeFlight(id: 'b', price: 200),
        ],
        filteredFlights: [],
        departureDate: baseDeparture,
        departureCode: 'CDG',
        arrivalCode: 'LHR',
        adults: 1,
        children: 0,
        infants: 0,
        travelClass: 'economy',
      ),
      act: (bloc) => bloc.add(ApplyFilters(priceSort: 'lowest')),
      verify: (bloc) {
        final state = bloc.state as FlightSearchResultLoaded;
        expect(state.filteredFlights.map((f) => f.id), ['a', 'b', 'c']);
        expect(state.priceSort, 'lowest');
      },
    );

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'ApplyFilters(priceSort=highest) sorts descending',
      build: () => buildBloc(),
      seed: () => FlightSearchResultLoaded(
        flights: [
          _makeFlight(id: 'a', price: 100),
          _makeFlight(id: 'c', price: 300),
          _makeFlight(id: 'b', price: 200),
        ],
        filteredFlights: [],
        departureDate: baseDeparture,
        departureCode: 'CDG',
        arrivalCode: 'LHR',
        adults: 1,
        children: 0,
        infants: 0,
        travelClass: 'economy',
      ),
      act: (bloc) => bloc.add(ApplyFilters(priceSort: 'highest')),
      verify: (bloc) {
        final state = bloc.state as FlightSearchResultLoaded;
        expect(state.filteredFlights.map((f) => f.id), ['c', 'b', 'a']);
      },
    );

    blocTest<FlightSearchResultBloc, FlightSearchResultState>(
      'ApplyFilters(departureTimeBefore) drops flights departing after cutoff',
      build: () => buildBloc(),
      seed: () => FlightSearchResultLoaded(
        flights: [
          _makeFlight(
            id: 'early',
            departureDateTime: DateTime(2025, 6, 15, 6, 0),
          ),
          _makeFlight(
            id: 'late',
            departureDateTime: DateTime(2025, 6, 15, 14, 0),
          ),
        ],
        filteredFlights: [],
        departureDate: baseDeparture,
        departureCode: 'CDG',
        arrivalCode: 'LHR',
        adults: 1,
        children: 0,
        infants: 0,
        travelClass: 'economy',
      ),
      act: (bloc) => bloc.add(
        ApplyFilters(departureTimeBefore: const TimeOfDay(hour: 10, minute: 0)),
      ),
      verify: (bloc) {
        final state = bloc.state as FlightSearchResultLoaded;
        expect(state.filteredFlights.length, 1);
        expect(state.filteredFlights.first.id, 'early');
      },
    );
  });
}
