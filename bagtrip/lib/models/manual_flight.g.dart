// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_flight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ManualFlight _$ManualFlightFromJson(Map<String, dynamic> json) =>
    _ManualFlight(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      flightNumber: json['flightNumber'] as String,
      airline: json['airline'] as String?,
      departureAirport: json['departureAirport'] as String?,
      arrivalAirport: json['arrivalAirport'] as String?,
      departureDate: json['departureDate'] == null
          ? null
          : DateTime.parse(json['departureDate'] as String),
      arrivalDate: json['arrivalDate'] == null
          ? null
          : DateTime.parse(json['arrivalDate'] as String),
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      notes: json['notes'] as String?,
      flightType: json['flightType'] as String? ?? 'MAIN',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ManualFlightToJson(_ManualFlight instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'flightNumber': instance.flightNumber,
      'airline': instance.airline,
      'departureAirport': instance.departureAirport,
      'arrivalAirport': instance.arrivalAirport,
      'departureDate': instance.departureDate?.toIso8601String(),
      'arrivalDate': instance.arrivalDate?.toIso8601String(),
      'price': instance.price,
      'currency': instance.currency,
      'notes': instance.notes,
      'flightType': instance.flightType,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
