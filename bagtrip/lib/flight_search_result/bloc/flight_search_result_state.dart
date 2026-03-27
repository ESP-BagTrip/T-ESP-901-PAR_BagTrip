part of 'flight_search_result_bloc.dart';

@immutable
sealed class FlightSearchResultState {}

final class FlightSearchResultInitial extends FlightSearchResultState {}

final class FlightSearchResultLoading extends FlightSearchResultState {}

final class FlightSearchResultLoaded extends FlightSearchResultState {
  final List<Flight> flights;
  final List<Flight> filteredFlights;
  final Flight? selectedFlight;
  final double? maxPrice;
  final String sortBy;
  final int selectedDateIndex;
  final DateTime departureDate;
  final DateTime? returnDate;
  // Store original search parameters for date change
  final String departureCode;
  final String arrivalCode;
  final int adults;
  final int children;
  final int infants;
  final String travelClass;
  final List<FlightSegment>? multiDestSegments;
  // Filters
  final String? priceSort; // 'lowest' or 'highest'
  final String? selectedAirline;
  final bool? cabinBagIncluded;
  final bool? checkedBagIncluded;
  final TimeOfDay? departureTimeBefore;
  final TimeOfDay? departureTimeAfter;

  FlightSearchResultLoaded({
    required this.flights,
    required this.filteredFlights,
    this.selectedFlight,
    this.maxPrice,
    this.sortBy = 'price',
    this.selectedDateIndex = 0,
    required this.departureDate,
    this.returnDate,
    required this.departureCode,
    required this.arrivalCode,
    required this.adults,
    required this.children,
    required this.infants,
    required this.travelClass,
    this.multiDestSegments,
    this.priceSort,
    this.selectedAirline,
    this.cabinBagIncluded,
    this.checkedBagIncluded,
    this.departureTimeBefore,
    this.departureTimeAfter,
  });

  FlightSearchResultLoaded copyWith({
    List<Flight>? flights,
    List<Flight>? filteredFlights,
    Flight? selectedFlight,
    double? maxPrice,
    String? sortBy,
    int? selectedDateIndex,
    DateTime? departureDate,
    DateTime? returnDate,
    String? departureCode,
    String? arrivalCode,
    int? adults,
    int? children,
    int? infants,
    String? travelClass,
    List<FlightSegment>? multiDestSegments,
    String? priceSort,
    String? selectedAirline,
    bool? cabinBagIncluded,
    bool? checkedBagIncluded,
    TimeOfDay? departureTimeBefore,
    TimeOfDay? departureTimeAfter,
  }) {
    return FlightSearchResultLoaded(
      flights: flights ?? this.flights,
      filteredFlights: filteredFlights ?? this.filteredFlights,
      selectedFlight: selectedFlight ?? this.selectedFlight,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
      selectedDateIndex: selectedDateIndex ?? this.selectedDateIndex,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      departureCode: departureCode ?? this.departureCode,
      arrivalCode: arrivalCode ?? this.arrivalCode,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      infants: infants ?? this.infants,
      travelClass: travelClass ?? this.travelClass,
      multiDestSegments: multiDestSegments ?? this.multiDestSegments,
      priceSort: priceSort ?? this.priceSort,
      selectedAirline: selectedAirline ?? this.selectedAirline,
      cabinBagIncluded: cabinBagIncluded ?? this.cabinBagIncluded,
      checkedBagIncluded: checkedBagIncluded ?? this.checkedBagIncluded,
      departureTimeBefore: departureTimeBefore ?? this.departureTimeBefore,
      departureTimeAfter: departureTimeAfter ?? this.departureTimeAfter,
    );
  }
}

final class FlightSearchResultError extends FlightSearchResultState {
  final AppError error;

  FlightSearchResultError(this.error);
}
