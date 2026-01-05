// ignore_for_file: depend_on_referenced_packages

import 'package:bagtrip/flightSearchResult/models/flight.dart';
import 'package:bagtrip/home/models/flight_segment.dart';
import 'package:bagtrip/service/LocationService.dart';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'flight_search_result_event.dart';
part 'flight_search_result_state.dart';

class FlightSearchResultBloc
    extends Bloc<FlightSearchResultEvent, FlightSearchResultState> {
  final LocationService _locationService;

  FlightSearchResultBloc({LocationService? locationService})
    : _locationService = locationService ?? LocationService(),
      super(FlightSearchResultInitial()) {
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
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final departureDateStr = dateFormatter.format(event.departureDate);
      final returnDateStr =
          event.returnDate != null
              ? dateFormatter.format(event.returnDate!)
              : null;

      final flights = await _locationService.searchFlights(
        departureCode: event.departureCode,
        arrivalCode: event.arrivalCode,
        departureDate: departureDateStr,
        returnDate: returnDateStr,
        adults: event.adults,
        children: event.children,
        infants: event.infants,
        travelClass: event.travelClass.toUpperCase(),
        multiDestSegments: event.multiDestSegments,
      );

      var filteredFlights = List<Flight>.from(flights);
      if (event.maxPrice != null) {
        filteredFlights =
            filteredFlights
                .where((flight) => flight.price <= event.maxPrice!)
                .toList();
      }

      emit(
        FlightSearchResultLoaded(
          flights: flights,
          filteredFlights: filteredFlights,
          maxPrice: event.maxPrice,
        ),
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
    List<Flight> filtered;

    if (event.maxPrice != null) {
      filtered =
          current.flights
              .where((flight) => flight.price <= event.maxPrice!)
              .toList();
    } else {
      filtered = List.from(current.flights);
    }

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
}
