import 'package:bagtrip/home/models/flight_segment.dart';

class FlightSearchArguments {
  final String tripId;
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

  FlightSearchArguments({
    required this.tripId,
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
