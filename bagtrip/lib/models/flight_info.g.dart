// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FlightInfo _$FlightInfoFromJson(Map<String, dynamic> json) => _FlightInfo(
  flightIata: json['flightIata'] as String?,
  airlineIata: json['airlineIata'] as String?,
  airlineName: json['airlineName'] as String?,
  status: json['status'] as String?,
  departureIata: json['departureIata'] as String?,
  departureTerminal: json['departureTerminal'] as String?,
  departureGate: json['departureGate'] as String?,
  departureTime: json['departureTime'] as String?,
  departureActual: json['departureActual'] as String?,
  departureDelay: (json['departureDelay'] as num?)?.toInt(),
  arrivalIata: json['arrivalIata'] as String?,
  arrivalTerminal: json['arrivalTerminal'] as String?,
  arrivalGate: json['arrivalGate'] as String?,
  arrivalTime: json['arrivalTime'] as String?,
  arrivalActual: json['arrivalActual'] as String?,
  arrivalDelay: (json['arrivalDelay'] as num?)?.toInt(),
);

Map<String, dynamic> _$FlightInfoToJson(_FlightInfo instance) =>
    <String, dynamic>{
      'flightIata': instance.flightIata,
      'airlineIata': instance.airlineIata,
      'airlineName': instance.airlineName,
      'status': instance.status,
      'departureIata': instance.departureIata,
      'departureTerminal': instance.departureTerminal,
      'departureGate': instance.departureGate,
      'departureTime': instance.departureTime,
      'departureActual': instance.departureActual,
      'departureDelay': instance.departureDelay,
      'arrivalIata': instance.arrivalIata,
      'arrivalTerminal': instance.arrivalTerminal,
      'arrivalGate': instance.arrivalGate,
      'arrivalTime': instance.arrivalTime,
      'arrivalActual': instance.arrivalActual,
      'arrivalDelay': instance.arrivalDelay,
    };
