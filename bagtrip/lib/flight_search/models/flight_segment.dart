import 'package:freezed_annotation/freezed_annotation.dart';

part 'flight_segment.freezed.dart';

@freezed
abstract class FlightSegment with _$FlightSegment {
  const factory FlightSegment({
    Map<String, dynamic>? departureAirport,
    Map<String, dynamic>? arrivalAirport,
    DateTime? departureDate,
  }) = _FlightSegment;
}
