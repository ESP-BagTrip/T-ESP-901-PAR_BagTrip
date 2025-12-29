part of 'home_flight_bloc.dart';

@immutable
sealed class HomeFlightEvent {}

class SearchDepartureAirport extends HomeFlightEvent {
  final String keyword;

  SearchDepartureAirport(this.keyword);
}

class SearchArrivalAirport extends HomeFlightEvent {
  final String keyword;

  SearchArrivalAirport(this.keyword);
}

class SetTripType extends HomeFlightEvent {
  final int index;

  SetTripType(this.index);
}

class SetAdults extends HomeFlightEvent {
  final int count;

  SetAdults(this.count);
}

class SetChildren extends HomeFlightEvent {
  final int count;

  SetChildren(this.count);
}

class SetInfants extends HomeFlightEvent {
  final int count;

  SetInfants(this.count);
}

class SetTravelClass extends HomeFlightEvent {
  final int index;

  SetTravelClass(this.index);
}

class SelectDepartureAirport extends HomeFlightEvent {
  final Map<String, dynamic> airport;

  SelectDepartureAirport(this.airport);
}

class SelectArrivalAirport extends HomeFlightEvent {
  final Map<String, dynamic> airport;

  SelectArrivalAirport(this.airport);
}

class SetDepartureDate extends HomeFlightEvent {
  final DateTime date;

  SetDepartureDate(this.date);
}

class SetReturnDate extends HomeFlightEvent {
  final DateTime date;

  SetReturnDate(this.date);
}

class SetMaxPrice extends HomeFlightEvent {
  final double price;

  SetMaxPrice(this.price);
}

class AddFlightSegment extends HomeFlightEvent {}

class RemoveFlightSegment extends HomeFlightEvent {
  final int index;

  RemoveFlightSegment(this.index);
}

class SelectMultiDestDepartureAirport extends HomeFlightEvent {
  final int index;
  final Map<String, dynamic> airport;

  SelectMultiDestDepartureAirport(this.index, this.airport);
}

class SelectMultiDestArrivalAirport extends HomeFlightEvent {
  final int index;
  final Map<String, dynamic> airport;

  SelectMultiDestArrivalAirport(this.index, this.airport);
}

class SetMultiDestDate extends HomeFlightEvent {
  final int index;
  final DateTime date;

  SetMultiDestDate(this.index, this.date);
}

class SearchFlights extends HomeFlightEvent {}

class ShowValidationErrors extends HomeFlightEvent {}

class SwapAirports extends HomeFlightEvent {}
