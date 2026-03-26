// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_flight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ManualFlight _$ManualFlightFromJson(Map<String, dynamic> json) =>
    _ManualFlight(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      flightNumber: json['flight_number'] as String,
      airline: json['airline'] as String?,
      departureAirport: json['departure_airport'] as String?,
      arrivalAirport: json['arrival_airport'] as String?,
      departureDate: json['departure_date'] == null
          ? null
          : DateTime.parse(json['departure_date'] as String),
      arrivalDate: json['arrival_date'] == null
          ? null
          : DateTime.parse(json['arrival_date'] as String),
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      notes: json['notes'] as String?,
      flightType: json['flight_type'] as String? ?? 'MAIN',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ManualFlightToJson(_ManualFlight instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'flight_number': instance.flightNumber,
      'airline': instance.airline,
      'departure_airport': instance.departureAirport,
      'arrival_airport': instance.arrivalAirport,
      'departure_date': instance.departureDate?.toIso8601String(),
      'arrival_date': instance.arrivalDate?.toIso8601String(),
      'price': instance.price,
      'currency': instance.currency,
      'notes': instance.notes,
      'flight_type': instance.flightType,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
