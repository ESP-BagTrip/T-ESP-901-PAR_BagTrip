// ignore_for_file: depend_on_referenced_packages

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
  }

  Future<void> _onSearchDepartureAirport(
    SearchDepartureAirport event,
    Emitter<HomeFlightState> emit,
  ) async {
    emit(HomeFlightLoading());

    try {
      final airports = await _locationService.searchLocationsByKeyword(
        event.keyword,
        'AIRPORT',
      );
      emit(HomeFlightAirportsLoaded(airports));
    } catch (e) {
      emit(HomeFlightError(e.toString()));
    }
  }
}
