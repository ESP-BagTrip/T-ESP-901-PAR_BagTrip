import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/flight_search/models/flight_segment.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';

void main() {
  late MockLocationService mockLocationService;

  setUp(() {
    mockLocationService = MockLocationService();
  });

  group('FlightSearchBloc', () {
    // ── Form state ──────────────────────────────────────────────────────

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SetTripType updates tripTypeIndex',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(SetTripType(2)),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.tripTypeIndex,
          'tripTypeIndex',
          2,
        ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SetAdults updates adults',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(SetAdults(3)),
      expect: () => [
        isA<FlightSearchLoaded>().having((s) => s.adults, 'adults', 3),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SetChildren updates children',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(SetChildren(2)),
      expect: () => [
        isA<FlightSearchLoaded>().having((s) => s.children, 'children', 2),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SetInfants updates infants',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(SetInfants(1)),
      expect: () => [
        isA<FlightSearchLoaded>().having((s) => s.infants, 'infants', 1),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SetTravelClass updates selectedClass',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(SetTravelClass(2)),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.selectedClass,
          'selectedClass',
          2,
        ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SetDepartureDate updates departureDate',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(SetDepartureDate(DateTime(2024, 7, 15))),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.departureDate,
          'departureDate',
          DateTime(2024, 7, 15),
        ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SetReturnDate updates returnDate',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(SetReturnDate(DateTime(2024, 7, 20))),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.returnDate,
          'returnDate',
          DateTime(2024, 7, 20),
        ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SetMaxPrice updates maxPrice',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(SetMaxPrice(500.0)),
      expect: () => [
        isA<FlightSearchLoaded>().having((s) => s.maxPrice, 'maxPrice', 500.0),
      ],
    );

    // ── Airport selection ───────────────────────────────────────────────

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SelectDepartureAirport updates departureAirport',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(
        SelectDepartureAirport({'iataCode': 'CDG', 'name': 'Paris CDG'}),
      ),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.departureAirport,
          'departureAirport',
          {'iataCode': 'CDG', 'name': 'Paris CDG'},
        ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SelectArrivalAirport updates arrivalAirport',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(
        SelectArrivalAirport({'iataCode': 'JFK', 'name': 'New York JFK'}),
      ),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.arrivalAirport,
          'arrivalAirport',
          {'iataCode': 'JFK', 'name': 'New York JFK'},
        ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SwapAirports swaps departure and arrival',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      seed: () => FlightSearchLoaded(
        departureAirport: {'iataCode': 'CDG', 'name': 'Paris CDG'},
        arrivalAirport: {'iataCode': 'JFK', 'name': 'New York JFK'},
      ),
      act: (bloc) => bloc.add(SwapAirports()),
      expect: () => [
        isA<FlightSearchLoaded>()
            .having((s) => s.departureAirport, 'departureAirport', {
              'iataCode': 'JFK',
              'name': 'New York JFK',
            })
            .having((s) => s.arrivalAirport, 'arrivalAirport', {
              'iataCode': 'CDG',
              'name': 'Paris CDG',
            }),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SearchDepartureAirport success emits loading then results',
      build: () {
        when(
          () => mockLocationService.searchLocationsByKeyword(any(), any()),
        ).thenAnswer(
          (_) async => const Success([
            {'iataCode': 'CDG', 'name': 'Paris CDG'},
          ]),
        );
        return FlightSearchBloc(locationService: mockLocationService);
      },
      act: (bloc) => bloc.add(SearchDepartureAirport('Paris')),
      expect: () => [
        isA<FlightSearchLoaded>().having((s) => s.isLoading, 'isLoading', true),
        isA<FlightSearchLoaded>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.searchResults?.length, 'searchResults.length', 1),
      ],
      verify: (_) {
        verify(
          () =>
              mockLocationService.searchLocationsByKeyword('Paris', 'AIRPORT'),
        ).called(1);
      },
    );

    // ── Multi-destination ───────────────────────────────────────────────

    blocTest<FlightSearchBloc, FlightSearchState>(
      'AddFlightSegment adds segment with smart chaining from previous arrival',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      seed: () => FlightSearchLoaded(
        multiDestSegments: [
          const FlightSegment(
            departureAirport: {'iataCode': 'CDG'},
            arrivalAirport: {'iataCode': 'JFK'},
          ),
        ],
      ),
      act: (bloc) => bloc.add(AddFlightSegment()),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.multiDestSegments.length,
          'segments count',
          2,
        ),
      ],
      verify: (bloc) {
        final state = bloc.state as FlightSearchLoaded;
        // Smart chaining: new segment departure == previous arrival
        expect(state.multiDestSegments.last.departureAirport, {
          'iataCode': 'JFK',
        });
      },
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'RemoveFlightSegment removes segment at index',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      seed: () => FlightSearchLoaded(
        multiDestSegments: [
          const FlightSegment(departureAirport: {'iataCode': 'CDG'}),
          const FlightSegment(departureAirport: {'iataCode': 'JFK'}),
          const FlightSegment(departureAirport: {'iataCode': 'LAX'}),
        ],
      ),
      act: (bloc) => bloc.add(RemoveFlightSegment(1)),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.multiDestSegments.length,
          'segments count',
          2,
        ),
      ],
      verify: (bloc) {
        final state = bloc.state as FlightSearchLoaded;
        expect(state.multiDestSegments[0].departureAirport, {
          'iataCode': 'CDG',
        });
        expect(state.multiDestSegments[1].departureAirport, {
          'iataCode': 'LAX',
        });
      },
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SelectMultiDestDepartureAirport updates segment departure',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      seed: () => FlightSearchLoaded(
        multiDestSegments: [const FlightSegment(), const FlightSegment()],
      ),
      act: (bloc) =>
          bloc.add(SelectMultiDestDepartureAirport(0, {'iataCode': 'ORY'})),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.multiDestSegments[0].departureAirport,
          'segment[0].departure',
          {'iataCode': 'ORY'},
        ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SelectMultiDestArrivalAirport updates segment arrival',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      seed: () => FlightSearchLoaded(
        multiDestSegments: [const FlightSegment(), const FlightSegment()],
      ),
      act: (bloc) =>
          bloc.add(SelectMultiDestArrivalAirport(1, {'iataCode': 'BCN'})),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.multiDestSegments[1].arrivalAirport,
          'segment[1].arrival',
          {'iataCode': 'BCN'},
        ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SetMultiDestDate updates segment date',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      seed: () => FlightSearchLoaded(
        multiDestSegments: [const FlightSegment(), const FlightSegment()],
      ),
      act: (bloc) => bloc.add(SetMultiDestDate(0, DateTime(2024, 8))),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.multiDestSegments[0].departureDate,
          'segment[0].date',
          DateTime(2024, 8),
        ),
      ],
    );

    // ── Actions ─────────────────────────────────────────────────────────

    blocTest<FlightSearchBloc, FlightSearchState>(
      'SearchFlights emits loading then not loading',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(SearchFlights()),
      expect: () => [
        isA<FlightSearchLoaded>().having((s) => s.isLoading, 'isLoading', true),
        isA<FlightSearchLoaded>().having(
          (s) => s.isLoading,
          'isLoading',
          false,
        ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'ShowValidationErrors sets showValidationErrors to true',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(ShowValidationErrors()),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.showValidationErrors,
          'showValidationErrors',
          true,
        ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'InitWithPrefilledData emits FlightSearchLoaded with prefilled data',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      act: (bloc) => bloc.add(
        InitWithPrefilledData(
          departureAirport: {'iataCode': 'CDG'},
          arrivalAirport: {'iataCode': 'JFK'},
          departureDate: DateTime(2024, 7),
          returnDate: DateTime(2024, 7, 10),
          adults: 2,
        ),
      ),
      expect: () => [
        isA<FlightSearchLoaded>()
            .having((s) => s.departureAirport, 'departureAirport', {
              'iataCode': 'CDG',
            })
            .having((s) => s.arrivalAirport, 'arrivalAirport', {
              'iataCode': 'JFK',
            })
            .having((s) => s.departureDate, 'departureDate', DateTime(2024, 7))
            .having((s) => s.returnDate, 'returnDate', DateTime(2024, 7, 10))
            .having((s) => s.adults, 'adults', 2),
      ],
    );

    // ── Edge cases ──────────────────────────────────────────────────────

    blocTest<FlightSearchBloc, FlightSearchState>(
      'AddFlightSegment from initial state creates FlightSearchLoaded then adds segment',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      // initial state is FlightSearchInitial — _currentState() returns new FlightSearchLoaded()
      act: (bloc) => bloc.add(AddFlightSegment()),
      expect: () => [
        isA<FlightSearchLoaded>().having(
          (s) => s.multiDestSegments.length,
          'segments count',
          3, // default 2 + 1 added
        ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'RemoveFlightSegment out-of-bounds is a no-op',
      build: () => FlightSearchBloc(locationService: mockLocationService),
      seed: () =>
          FlightSearchLoaded(multiDestSegments: [const FlightSegment()]),
      act: (bloc) => bloc.add(RemoveFlightSegment(5)),
      expect: () => <FlightSearchState>[],
    );
  });
}
