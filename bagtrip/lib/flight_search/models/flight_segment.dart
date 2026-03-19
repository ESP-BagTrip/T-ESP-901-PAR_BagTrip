import 'package:freezed_annotation/freezed_annotation.dart';

part 'flight_segment.freezed.dart';
part 'flight_segment.g.dart';

@freezed
abstract class FlightSegment with _$FlightSegment {
  const factory FlightSegment({
    @JsonKey(name: 'departureAirport') Map<String, dynamic>? departureAirport,
    @JsonKey(name: 'arrivalAirport') Map<String, dynamic>? arrivalAirport,
    @JsonKey(name: 'departureDate') DateTime? departureDate,
  }) = _FlightSegment;

  factory FlightSegment.fromJson(Map<String, dynamic> json) =>
      _$FlightSegmentFromJson(json);
}
