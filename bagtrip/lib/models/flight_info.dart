import 'package:freezed_annotation/freezed_annotation.dart';

part 'flight_info.freezed.dart';
part 'flight_info.g.dart';

@freezed
abstract class FlightInfo with _$FlightInfo {
  const factory FlightInfo({
    String? flightIata,
    String? airlineIata,
    String? airlineName,
    String? status,
    String? departureIata,
    String? departureTerminal,
    String? departureGate,
    String? departureTime,
    String? departureActual,
    int? departureDelay,
    String? arrivalIata,
    String? arrivalTerminal,
    String? arrivalGate,
    String? arrivalTime,
    String? arrivalActual,
    int? arrivalDelay,
  }) = _FlightInfo;

  factory FlightInfo.fromJson(Map<String, dynamic> json) =>
      _$FlightInfoFromJson(json);
}
