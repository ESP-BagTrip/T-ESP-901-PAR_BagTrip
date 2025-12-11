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

  FlightSearchResultLoaded({
    required this.flights,
    required this.filteredFlights,
    this.selectedFlight,
    this.maxPrice,
    this.sortBy = 'price',
    this.selectedDateIndex = 0,
  });

  FlightSearchResultLoaded copyWith({
    List<Flight>? flights,
    List<Flight>? filteredFlights,
    Flight? selectedFlight,
    double? maxPrice,
    String? sortBy,
    int? selectedDateIndex,
  }) {
    return FlightSearchResultLoaded(
      flights: flights ?? this.flights,
      filteredFlights: filteredFlights ?? this.filteredFlights,
      selectedFlight: selectedFlight ?? this.selectedFlight,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
      selectedDateIndex: selectedDateIndex ?? this.selectedDateIndex,
    );
  }
}

final class FlightSearchResultError extends FlightSearchResultState {
  final String message;

  FlightSearchResultError(this.message);
}
