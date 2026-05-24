import 'package:freezed_annotation/freezed_annotation.dart';

part 'flight_info.freezed.dart';
part 'flight_info.g.dart';

@freezed
abstract class FlightInfo with _$FlightInfo {
  const factory FlightInfo({
    @JsonKey(name: 'flightIata') String? flightIata,
    @JsonKey(name: 'airlineIata') String? airlineIata,
    @JsonKey(name: 'airlineName') String? airlineName,
    String? status,
    @JsonKey(name: 'departureIata') String? departureIata,
    @JsonKey(name: 'departureTerminal') String? departureTerminal,
    @JsonKey(name: 'departureGate') String? departureGate,
    @JsonKey(name: 'departureTime') String? departureTime,
    @JsonKey(name: 'departureActual') String? departureActual,
    @JsonKey(name: 'departureDelay') int? departureDelay,
    @JsonKey(name: 'arrivalIata') String? arrivalIata,
    @JsonKey(name: 'arrivalTerminal') String? arrivalTerminal,
    @JsonKey(name: 'arrivalGate') String? arrivalGate,
    @JsonKey(name: 'arrivalTime') String? arrivalTime,
    @JsonKey(name: 'arrivalActual') String? arrivalActual,
    @JsonKey(name: 'arrivalDelay') int? arrivalDelay,
  }) = _FlightInfo;

  factory FlightInfo.fromJson(Map<String, dynamic> json) =>
      _$FlightInfoFromJson(json);
}
