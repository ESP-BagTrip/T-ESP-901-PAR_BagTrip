// ignore_for_file: depend_on_referenced_packages

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:bagtrip/flightSearchResult/models/flight.dart';

part 'flight_search_result_event.dart';
part 'flight_search_result_state.dart';

class FlightSearchResultBloc
    extends Bloc<FlightSearchResultEvent, FlightSearchResultState> {
  FlightSearchResultBloc() : super(FlightSearchResultInitial()) {
    on<LoadFlights>(_onLoadFlights);
    on<FilterFlightsByPrice>(_onFilterFlightsByPrice);
    on<SortFlights>(_onSortFlights);
    on<SelectFlight>(_onSelectFlight);
    on<SelectDate>(_onSelectDate);
  }

  FlightSearchResultLoaded _currentState() {
    if (state is FlightSearchResultLoaded) {
      return state as FlightSearchResultLoaded;
    }
    return FlightSearchResultLoaded(flights: [], filteredFlights: []);
  }

  Future<void> _onLoadFlights(
    LoadFlights event,
    Emitter<FlightSearchResultState> emit,
  ) async {
    emit(FlightSearchResultLoading());

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final flights = _generateMockFlights();

      emit(
        FlightSearchResultLoaded(flights: flights, filteredFlights: flights),
      );
    } catch (e) {
      emit(FlightSearchResultError(e.toString()));
    }
  }

  Future<void> _onFilterFlightsByPrice(
    FilterFlightsByPrice event,
    Emitter<FlightSearchResultState> emit,
  ) async {
    final current = _currentState();
    final filtered =
        current.flights
            .where((flight) => flight.price <= event.maxPrice)
            .toList();

    emit(current.copyWith(filteredFlights: filtered, maxPrice: event.maxPrice));
  }

  Future<void> _onSortFlights(
    SortFlights event,
    Emitter<FlightSearchResultState> emit,
  ) async {
    final current = _currentState();
    final sorted = List<Flight>.from(current.filteredFlights);

    switch (event.sortBy) {
      case 'price':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'duration':
        sorted.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 'departure':
        sorted.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
    }

    emit(current.copyWith(filteredFlights: sorted, sortBy: event.sortBy));
  }

  Future<void> _onSelectFlight(
    SelectFlight event,
    Emitter<FlightSearchResultState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(selectedFlight: event.flight));
  }

  Future<void> _onSelectDate(
    SelectDate event,
    Emitter<FlightSearchResultState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(selectedDateIndex: event.dateIndex));
  }

  List<Flight> _generateMockFlights() {
    return [
      Flight(
        id: '1',
        departureTime: '15:55',
        arrivalTime: '16:55',
        departureAirport: 'CDG',
        departureCode: 'CDG T2F',
        arrivalAirport: 'FCO',
        arrivalCode: 'FCO T1',
        duration: '1h00',
        airline: 'Air France',
        aircraftType: 'Airbus A321',
        price: 186.0,
        amenities: ['Bagage à main inclus'],
        co2Offset: 8,
      ),
      Flight(
        id: '2',
        departureTime: '15:55',
        arrivalTime: '16:55',
        departureAirport: 'CDG',
        departureCode: 'CDG T2F',
        arrivalAirport: 'FCO',
        arrivalCode: 'FCO T1',
        duration: '1h00',
        airline: 'Air France',
        aircraftType: 'Airbus A321',
        price: 167.0,
        amenities: ['Bagage à main inclus'],
        co2Offset: 8,
      ),
      Flight(
        id: '3',
        departureTime: '15:55',
        arrivalTime: '16:55',
        departureAirport: 'CDG',
        departureCode: 'CDG T2F',
        arrivalAirport: 'FCO',
        arrivalCode: 'FCO T1',
        duration: '1h00',
        airline: 'Air France',
        aircraftType: 'Airbus A321',
        price: 167.0,
        amenities: ['Bagage à main inclus'],
        co2Offset: 8,
      ),
      Flight(
        id: '4',
        departureTime: '15:55',
        arrivalTime: '16:55',
        departureAirport: 'CDG',
        departureCode: 'CDG T2F',
        arrivalAirport: 'FCO',
        arrivalCode: 'FCO T1',
        duration: '1h00',
        airline: 'Air France',
        aircraftType: 'Airbus A321',
        price: 167.0,
        amenities: ['Bagage à main inclus'],
        co2Offset: 8,
      ),
    ];
  }
}
