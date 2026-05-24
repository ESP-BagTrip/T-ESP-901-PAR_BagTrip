part of 'flight_search_result_bloc.dart';

@immutable
sealed class FlightSearchResultEvent {}

class LoadFlights extends FlightSearchResultEvent {
  final String? tripId;
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
  // Phase 4 follow-up — when set, the page is in replace mode: tapping
  // a result must pop with that Flight so the caller can dispatch
  // ReplaceFlightFromDetail (atomic DELETE+CREATE) on the original row.
  final String? replaceFlightId;

  LoadFlights({
    this.tripId,
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
    this.replaceFlightId,
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

class ApplyFilters extends FlightSearchResultEvent {
  final String? priceSort; // 'lowest' or 'highest'
  final String? selectedAirline;
  final bool? cabinBagIncluded;
  final bool? checkedBagIncluded;
  final TimeOfDay? departureTimeBefore;
  final TimeOfDay? departureTimeAfter;

  ApplyFilters({
    this.priceSort,
    this.selectedAirline,
    this.cabinBagIncluded,
    this.checkedBagIncluded,
    this.departureTimeBefore,
    this.departureTimeAfter,
  });
}
