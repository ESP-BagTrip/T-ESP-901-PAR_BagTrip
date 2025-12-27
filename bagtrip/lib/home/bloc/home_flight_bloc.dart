// ignore_for_file: depend_on_referenced_packages

import 'package:bagtrip/home/models/flight_segment.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../service/LocationService.dart';

part 'home_flight_event.dart';
part 'home_flight_state.dart';

class HomeFlightBloc extends Bloc<HomeFlightEvent, HomeFlightState> {
  final LocationService _locationService;

  HomeFlightBloc({LocationService? locationService})
    : _locationService = locationService ?? LocationService(),
      super(HomeFlightInitial()) {
    on<SearchDepartureAirport>(_onSearchDepartureAirport);
    on<SearchArrivalAirport>(_onSearchArrivalAirport);
    on<SetTripType>(_onSetTripType);
    on<SetAdults>(_onSetAdults);
    on<SetChildren>(_onSetChildren);
    on<SetInfants>(_onSetInfants);
    on<SetTravelClass>(_onSetTravelClass);
    on<SelectDepartureAirport>(_onSelectDepartureAirport);
    on<SelectArrivalAirport>(_onSelectArrivalAirport);
    on<SetDepartureDate>(_onSetDepartureDate);
    on<SetReturnDate>(_onSetReturnDate);
    on<SetMaxPrice>(_onSetMaxPrice);
    on<AddFlightSegment>(_onAddFlightSegment);
    on<RemoveFlightSegment>(_onRemoveFlightSegment);
    on<SelectMultiDestDepartureAirport>(_onSelectMultiDestDepartureAirport);
    on<SelectMultiDestArrivalAirport>(_onSelectMultiDestArrivalAirport);
    on<SetMultiDestDate>(_onSetMultiDestDate);
    on<SearchFlights>(_onSearchFlights);
  }

  HomeFlightLoaded _currentState() {
    if (state is HomeFlightLoaded) {
      return state as HomeFlightLoaded;
    }
    return HomeFlightLoaded();
  }

  Future<void> _onSearchDepartureAirport(
    SearchDepartureAirport event,
    Emitter<HomeFlightState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(isLoading: true, clearError: true));

    try {
      final airports = await _locationService.searchLocationsByKeyword(
        event.keyword,
        'AIRPORT',
      );
      emit(current.copyWith(isLoading: false, searchResults: airports));
    } catch (e) {
      emit(current.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onSearchArrivalAirport(
    SearchArrivalAirport event,
    Emitter<HomeFlightState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(isLoading: true, clearError: true));

    try {
      final airports = await _locationService.searchLocationsByKeyword(
        event.keyword,
        'AIRPORT',
      );
      emit(current.copyWith(isLoading: false, searchResults: airports));
    } catch (e) {
      emit(current.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onSetTripType(
    SetTripType event,
    Emitter<HomeFlightState> emit,
  ) async {
    emit(_currentState().copyWith(tripTypeIndex: event.index));
  }

  Future<void> _onSetAdults(
    SetAdults event,
    Emitter<HomeFlightState> emit,
  ) async {
    emit(_currentState().copyWith(adults: event.count));
  }

  Future<void> _onSetChildren(
    SetChildren event,
    Emitter<HomeFlightState> emit,
  ) async {
    emit(_currentState().copyWith(children: event.count));
  }

  Future<void> _onSetInfants(
    SetInfants event,
    Emitter<HomeFlightState> emit,
  ) async {
    emit(_currentState().copyWith(infants: event.count));
  }

  Future<void> _onSetTravelClass(
    SetTravelClass event,
    Emitter<HomeFlightState> emit,
  ) async {
    emit(_currentState().copyWith(selectedClass: event.index));
  }

  Future<void> _onSelectDepartureAirport(
    SelectDepartureAirport event,
    Emitter<HomeFlightState> emit,
  ) async {
    emit(_currentState().copyWith(departureAirport: event.airport));
  }

  Future<void> _onSelectArrivalAirport(
    SelectArrivalAirport event,
    Emitter<HomeFlightState> emit,
  ) async {
    emit(_currentState().copyWith(arrivalAirport: event.airport));
  }

  Future<void> _onSetDepartureDate(
    SetDepartureDate event,
    Emitter<HomeFlightState> emit,
  ) async {
    emit(_currentState().copyWith(departureDate: event.date));
  }

  Future<void> _onSetReturnDate(
    SetReturnDate event,
    Emitter<HomeFlightState> emit,
  ) async {
    emit(_currentState().copyWith(returnDate: event.date));
  }

  Future<void> _onSetMaxPrice(
    SetMaxPrice event,
    Emitter<HomeFlightState> emit,
  ) async {
    emit(_currentState().copyWith(maxPrice: event.price));
  }

  Future<void> _onAddFlightSegment(
    AddFlightSegment event,
    Emitter<HomeFlightState> emit,
  ) async {
    final current = _currentState();
    final updatedSegments = List<FlightSegment>.from(current.multiDestSegments);
    updatedSegments.add(FlightSegment());
    emit(current.copyWith(multiDestSegments: updatedSegments));
  }

  Future<void> _onRemoveFlightSegment(
    RemoveFlightSegment event,
    Emitter<HomeFlightState> emit,
  ) async {
    final current = _currentState();
    if (event.index < current.multiDestSegments.length) {
      final updatedSegments = List<FlightSegment>.from(
        current.multiDestSegments,
      );
      updatedSegments.removeAt(event.index);
      emit(current.copyWith(multiDestSegments: updatedSegments));
    }
  }

  Future<void> _onSelectMultiDestDepartureAirport(
    SelectMultiDestDepartureAirport event,
    Emitter<HomeFlightState> emit,
  ) async {
    final current = _currentState();
    if (event.index < current.multiDestSegments.length) {
      final updatedSegments = List<FlightSegment>.from(
        current.multiDestSegments,
      );
      updatedSegments[event.index] = updatedSegments[event.index].copyWith(
        departureAirport: event.airport,
      );
      emit(current.copyWith(multiDestSegments: updatedSegments));
    }
  }

  Future<void> _onSelectMultiDestArrivalAirport(
    SelectMultiDestArrivalAirport event,
    Emitter<HomeFlightState> emit,
  ) async {
    final current = _currentState();
    if (event.index < current.multiDestSegments.length) {
      final updatedSegments = List<FlightSegment>.from(
        current.multiDestSegments,
      );
      updatedSegments[event.index] = updatedSegments[event.index].copyWith(
        arrivalAirport: event.airport,
      );
      emit(current.copyWith(multiDestSegments: updatedSegments));
    }
  }

  Future<void> _onSetMultiDestDate(
    SetMultiDestDate event,
    Emitter<HomeFlightState> emit,
  ) async {
    final current = _currentState();
    if (event.index < current.multiDestSegments.length) {
      final updatedSegments = List<FlightSegment>.from(
        current.multiDestSegments,
      );
      updatedSegments[event.index] = updatedSegments[event.index].copyWith(
        departureDate: event.date,
      );
      emit(current.copyWith(multiDestSegments: updatedSegments));
    }
  }

  Future<void> _onSearchFlights(
    SearchFlights event,
    Emitter<HomeFlightState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(isLoading: true, clearError: true));

    try {
      emit(current.copyWith(isLoading: false));
    } catch (e) {
      emit(current.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
