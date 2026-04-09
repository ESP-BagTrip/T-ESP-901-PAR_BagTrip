import 'package:bagtrip/flight_search/models/flight_segment.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'flight_search_arguments.freezed.dart';

@freezed
abstract class FlightSearchArguments with _$FlightSearchArguments {
  const factory FlightSearchArguments({
    String? tripId,
    required String departureCode,
    required String arrivalCode,
    required DateTime departureDate,
    DateTime? returnDate,
    required int adults,
    required int children,
    required int infants,
    required String travelClass,
    List<FlightSegment>? multiDestSegments,
    double? maxPrice,
  }) = _FlightSearchArguments;
}
