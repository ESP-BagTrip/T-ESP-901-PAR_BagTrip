// ignore_for_file: depend_on_referenced_packages

import 'package:bagtrip/flight_search/models/flight_segment.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../service/location_service.dart';

part 'flight_search_event.dart';
part 'flight_search_state.dart';

class FlightSearchBloc extends Bloc<FlightSearchEvent, FlightSearchState> {
  final LocationService _locationService;

  FlightSearchBloc({LocationService? locationService})
    : _locationService = locationService ?? getIt<LocationService>(),
      super(FlightSearchInitial()) {
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
    on<ShowValidationErrors>(_onShowValidationErrors);
    on<SwapAirports>(_onSwapAirports);
    on<InitWithPrefilledData>(_onInitWithPrefilledData);
  }

  FlightSearchLoaded _currentState() {
    if (state is FlightSearchLoaded) {
      return state as FlightSearchLoaded;
    }
    return FlightSearchLoaded();
  }

  Future<void> _onSearchDepartureAirport(
    SearchDepartureAirport event,
    Emitter<FlightSearchState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(isLoading: true, clearError: true));

    final result = await _locationService.searchLocationsByKeyword(
      event.keyword,
      'AIRPORT',
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          current.copyWith(
            isLoading: false,
            searchResults: data,
            clearError: true,
          ),
        );
      case Failure(:final error):
        emit(current.copyWith(isLoading: false, errorMessage: error.message));
    }
  }

  Future<void> _onSearchArrivalAirport(
    SearchArrivalAirport event,
    Emitter<FlightSearchState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(isLoading: true, clearError: true));

    final result = await _locationService.searchLocationsByKeyword(
      event.keyword,
      'AIRPORT',
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          current.copyWith(
            isLoading: false,
            searchResults: data,
            clearError: true,
          ),
        );
      case Failure(:final error):
        emit(current.copyWith(isLoading: false, errorMessage: error.message));
    }
  }

  Future<void> _onSetTripType(
    SetTripType event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(_currentState().copyWith(tripTypeIndex: event.index));
  }

  Future<void> _onSetAdults(
    SetAdults event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(_currentState().copyWith(adults: event.count));
  }

  Future<void> _onSetChildren(
    SetChildren event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(_currentState().copyWith(children: event.count));
  }

  Future<void> _onSetInfants(
    SetInfants event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(_currentState().copyWith(infants: event.count));
  }

  Future<void> _onSetTravelClass(
    SetTravelClass event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(_currentState().copyWith(selectedClass: event.index));
  }

  Future<void> _onSelectDepartureAirport(
    SelectDepartureAirport event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(_currentState().copyWith(departureAirport: event.airport));
  }

  Future<void> _onSelectArrivalAirport(
    SelectArrivalAirport event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(_currentState().copyWith(arrivalAirport: event.airport));
  }

  Future<void> _onSetDepartureDate(
    SetDepartureDate event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(_currentState().copyWith(departureDate: event.date));
  }

  Future<void> _onSetReturnDate(
    SetReturnDate event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(_currentState().copyWith(returnDate: event.date));
  }

  Future<void> _onSetMaxPrice(
    SetMaxPrice event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(_currentState().copyWith(maxPrice: event.price));
  }

  Future<void> _onAddFlightSegment(
    AddFlightSegment event,
    Emitter<FlightSearchState> emit,
  ) async {
    final current = _currentState();
    final updatedSegments = List<FlightSegment>.from(current.multiDestSegments);

    // Smart chaining: use previous arrival as new departure
    Map<String, dynamic>? nextDeparture;
    if (updatedSegments.isNotEmpty) {
      nextDeparture = updatedSegments.last.arrivalAirport;
    }

    updatedSegments.add(FlightSegment(departureAirport: nextDeparture));
    emit(current.copyWith(multiDestSegments: updatedSegments));
  }

  Future<void> _onRemoveFlightSegment(
    RemoveFlightSegment event,
    Emitter<FlightSearchState> emit,
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
    Emitter<FlightSearchState> emit,
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
    Emitter<FlightSearchState> emit,
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
    Emitter<FlightSearchState> emit,
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
    Emitter<FlightSearchState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(isLoading: true, clearError: true));

    try {
      emit(current.copyWith(isLoading: false));
    } catch (e) {
      emit(current.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onShowValidationErrors(
    ShowValidationErrors event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(_currentState().copyWith(showValidationErrors: true));
  }

  Future<void> _onSwapAirports(
    SwapAirports event,
    Emitter<FlightSearchState> emit,
  ) async {
    final current = _currentState();
    emit(
      current.copyWith(
        departureAirport: current.arrivalAirport,
        arrivalAirport: current.departureAirport,
      ),
    );
  }

  Future<void> _onInitWithPrefilledData(
    InitWithPrefilledData event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(
      FlightSearchLoaded(
        arrivalAirport: event.arrivalAirport,
        departureDate: event.departureDate,
        returnDate: event.returnDate,
        adults: event.adults ?? 1,
      ),
    );
  }
}
