// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accommodation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Accommodation _$AccommodationFromJson(Map<String, dynamic> json) =>
    _Accommodation(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      checkIn: json['check_in'] == null
          ? null
          : DateTime.parse(json['check_in'] as String),
      checkOut: json['check_out'] == null
          ? null
          : DateTime.parse(json['check_out'] as String),
      pricePerNight: (json['price_per_night'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      bookingReference: json['booking_reference'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$AccommodationToJson(_Accommodation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'name': instance.name,
      'address': instance.address,
      'check_in': instance.checkIn?.toIso8601String(),
      'check_out': instance.checkOut?.toIso8601String(),
      'price_per_night': instance.pricePerNight,
      'currency': instance.currency,
      'booking_reference': instance.bookingReference,
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
