part of 'home_flight_bloc.dart';

@immutable
sealed class HomeFlightState {}

final class HomeFlightInitial extends HomeFlightState {}

final class HomeFlightLoading extends HomeFlightState {}

final class HomeFlightAirportsLoaded extends HomeFlightState {
  final List<Map<String, dynamic>> airports;

  HomeFlightAirportsLoaded(this.airports);
}

final class HomeFlightError extends HomeFlightState {
  final String message;

  HomeFlightError(this.message);
}
