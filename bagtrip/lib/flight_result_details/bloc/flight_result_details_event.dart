part of 'flight_result_details_bloc.dart';

@immutable
sealed class FlightResultDetailsEvent {}

class LoadFlightDetails extends FlightResultDetailsEvent {
  final Flight flight;

  LoadFlightDetails(this.flight);
}
