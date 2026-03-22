part of 'flight_search_bloc.dart';

@immutable
sealed class FlightSearchEvent {}

class SearchDepartureAirport extends FlightSearchEvent {
  final String keyword;

  SearchDepartureAirport(this.keyword);
}

class SearchArrivalAirport extends FlightSearchEvent {
  final String keyword;

  SearchArrivalAirport(this.keyword);
}

class SetTripType extends FlightSearchEvent {
  final int index;

  SetTripType(this.index);
}

class SetAdults extends FlightSearchEvent {
  final int count;

  SetAdults(this.count);
}

class SetChildren extends FlightSearchEvent {
  final int count;

  SetChildren(this.count);
}

class SetInfants extends FlightSearchEvent {
  final int count;

  SetInfants(this.count);
}

class SetTravelClass extends FlightSearchEvent {
  final int index;

  SetTravelClass(this.index);
}

class SelectDepartureAirport extends FlightSearchEvent {
  final Map<String, dynamic> airport;

  SelectDepartureAirport(this.airport);
}

class SelectArrivalAirport extends FlightSearchEvent {
  final Map<String, dynamic> airport;

  SelectArrivalAirport(this.airport);
}

class SetDepartureDate extends FlightSearchEvent {
  final DateTime date;

  SetDepartureDate(this.date);
}

class SetReturnDate extends FlightSearchEvent {
  final DateTime date;

  SetReturnDate(this.date);
}

class SetMaxPrice extends FlightSearchEvent {
  final double? price;

  SetMaxPrice(this.price);
}

class AddFlightSegment extends FlightSearchEvent {}

class RemoveFlightSegment extends FlightSearchEvent {
  final int index;

  RemoveFlightSegment(this.index);
}

class SelectMultiDestDepartureAirport extends FlightSearchEvent {
  final int index;
  final Map<String, dynamic> airport;

  SelectMultiDestDepartureAirport(this.index, this.airport);
}

class SelectMultiDestArrivalAirport extends FlightSearchEvent {
  final int index;
  final Map<String, dynamic> airport;

  SelectMultiDestArrivalAirport(this.index, this.airport);
}

class SetMultiDestDate extends FlightSearchEvent {
  final int index;
  final DateTime date;

  SetMultiDestDate(this.index, this.date);
}

class SearchFlights extends FlightSearchEvent {}

class ShowValidationErrors extends FlightSearchEvent {}

class SwapAirports extends FlightSearchEvent {}

class InitWithPrefilledData extends FlightSearchEvent {
  final Map<String, dynamic>? departureAirport;
  final Map<String, dynamic>? arrivalAirport;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final int? adults;

  InitWithPrefilledData({
    this.departureAirport,
    this.arrivalAirport,
    this.departureDate,
    this.returnDate,
    this.adults,
  });
}
