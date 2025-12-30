part of 'flight_search_result_bloc.dart';

@immutable
sealed class FlightSearchResultEvent {}

class LoadFlights extends FlightSearchResultEvent {
  final String departureCode;
  final String arrivalCode;
  final DateTime departureDate;
  final DateTime? returnDate;
  final int adults;
  final int children;
  final int infants;
  final String travelClass;
  final List<FlightSegment>? multiDestSegments;
  final double? maxPrice;

  LoadFlights({
    required this.departureCode,
    required this.arrivalCode,
    required this.departureDate,
    this.returnDate,
    required this.adults,
    required this.children,
    required this.infants,
    required this.travelClass,
    this.multiDestSegments,
    this.maxPrice,
  });
}

class FilterFlightsByPrice extends FlightSearchResultEvent {
  final double? maxPrice;

  FilterFlightsByPrice(this.maxPrice);
}

class SortFlights extends FlightSearchResultEvent {
  final String sortBy;

  SortFlights(this.sortBy);
}

class SelectFlight extends FlightSearchResultEvent {
  final Flight flight;

  SelectFlight(this.flight);
}

class SelectDate extends FlightSearchResultEvent {
  final int dateIndex;

  SelectDate(this.dateIndex);
}
