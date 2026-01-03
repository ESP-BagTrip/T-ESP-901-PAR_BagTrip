part of 'flight_result_details_bloc.dart';

@immutable
sealed class FlightResultDetailsState {}

final class FlightResultDetailsInitial extends FlightResultDetailsState {}

final class FlightResultDetailsLoaded extends FlightResultDetailsState {
  final Flight flight;

  FlightResultDetailsLoaded(this.flight);
}
