part of 'flight_result_details_bloc.dart';

@immutable
sealed class FlightResultDetailsState {}

final class FlightResultDetailsInitial extends FlightResultDetailsState {}

final class FlightResultDetailsLoaded extends FlightResultDetailsState {
  final Flight flight;
  final bool priceChanged;
  final Flight? oldFlight;

  FlightResultDetailsLoaded(
    this.flight, {
    this.priceChanged = false,
    this.oldFlight,
  });
}

final class FlightPriceConfirming extends FlightResultDetailsState {}

final class FlightPriceConfirmed extends FlightResultDetailsState {
  final Flight flight;
  final bool priceChanged;
  final Flight? oldFlight;

  FlightPriceConfirmed(
    this.flight, {
    this.priceChanged = false,
    this.oldFlight,
  });
}

final class FlightPriceError extends FlightResultDetailsState {
  final String message;
  final Flight originalFlight;

  FlightPriceError(this.message, this.originalFlight);
}
