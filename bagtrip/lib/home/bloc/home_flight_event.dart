part of 'home_flight_bloc.dart';

@immutable
sealed class HomeFlightEvent {}

class SearchDepartureAirport extends HomeFlightEvent {
  final String keyword;

  SearchDepartureAirport(this.keyword);
}
