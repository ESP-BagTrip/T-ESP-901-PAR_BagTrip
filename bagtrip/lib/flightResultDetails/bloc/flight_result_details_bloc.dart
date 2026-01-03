import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'flight_result_details_event.dart';
part 'flight_result_details_state.dart';

class FlightResultDetailsBloc
    extends Bloc<FlightResultDetailsEvent, FlightResultDetailsState> {
  FlightResultDetailsBloc() : super(FlightResultDetailsInitial()) {
    on<LoadFlightDetails>((event, emit) {
      emit(FlightResultDetailsLoaded());
    });
  }
}
