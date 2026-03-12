part of 'flight_search_bloc.dart';

@immutable
sealed class FlightSearchState {}

final class FlightSearchInitial extends FlightSearchState {}

final class FlightSearchLoaded extends FlightSearchState {
  final int tripTypeIndex;
  final int adults;
  final int children;
  final int infants;
  final int selectedClass;
  final Map<String, dynamic>? departureAirport;
  final Map<String, dynamic>? arrivalAirport;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final List<FlightSegment> multiDestSegments;
  final double? maxPrice;
  final List<Map<String, dynamic>>? searchResults;
  final bool isLoading;
  final String? errorMessage;
  final bool showValidationErrors;

  FlightSearchLoaded({
    this.tripTypeIndex = 0,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.selectedClass = 0,
    this.departureAirport,
    this.arrivalAirport,
    this.departureDate,
    this.returnDate,
    List<FlightSegment>? multiDestSegments,
    this.maxPrice,
    this.searchResults,
    this.isLoading = false,
    this.errorMessage,
    this.showValidationErrors = false,
  }) : multiDestSegments =
           multiDestSegments ?? [FlightSegment(), FlightSegment()];

  FlightSearchLoaded copyWith({
    int? tripTypeIndex,
    int? adults,
    int? children,
    int? infants,
    int? selectedClass,
    Map<String, dynamic>? departureAirport,
    Map<String, dynamic>? arrivalAirport,
    DateTime? departureDate,
    DateTime? returnDate,
    List<FlightSegment>? multiDestSegments,
    double? maxPrice,
    List<Map<String, dynamic>>? searchResults,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? showValidationErrors,
  }) {
    return FlightSearchLoaded(
      tripTypeIndex: tripTypeIndex ?? this.tripTypeIndex,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      infants: infants ?? this.infants,
      selectedClass: selectedClass ?? this.selectedClass,
      departureAirport: departureAirport ?? this.departureAirport,
      arrivalAirport: arrivalAirport ?? this.arrivalAirport,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      multiDestSegments: multiDestSegments ?? this.multiDestSegments,
      maxPrice: maxPrice ?? this.maxPrice,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
    );
  }
}
