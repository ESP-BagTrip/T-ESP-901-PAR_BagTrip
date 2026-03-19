// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_segment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FlightSegment _$FlightSegmentFromJson(Map<String, dynamic> json) =>
    _FlightSegment(
      departureAirport: json['departureAirport'] as Map<String, dynamic>?,
      arrivalAirport: json['arrivalAirport'] as Map<String, dynamic>?,
      departureDate: json['departureDate'] == null
          ? null
          : DateTime.parse(json['departureDate'] as String),
    );

Map<String, dynamic> _$FlightSegmentToJson(_FlightSegment instance) =>
    <String, dynamic>{
      'departureAirport': instance.departureAirport,
      'arrivalAirport': instance.arrivalAirport,
      'departureDate': instance.departureDate?.toIso8601String(),
    };
