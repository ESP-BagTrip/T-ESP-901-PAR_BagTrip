part of 'flight_result_details_bloc.dart';

@immutable
sealed class FlightResultDetailsState {}

final class FlightResultDetailsInitial extends FlightResultDetailsState {}

final class FlightResultDetailsLoaded extends FlightResultDetailsState {
  // Add fields here later when we have the actual data model
  FlightResultDetailsLoaded();
}
