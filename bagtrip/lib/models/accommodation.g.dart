// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accommodation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Accommodation _$AccommodationFromJson(Map<String, dynamic> json) =>
    _Accommodation(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      checkIn: json['checkIn'] == null
          ? null
          : DateTime.parse(json['checkIn'] as String),
      checkOut: json['checkOut'] == null
          ? null
          : DateTime.parse(json['checkOut'] as String),
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      bookingReference: json['bookingReference'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AccommodationToJson(_Accommodation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'name': instance.name,
      'address': instance.address,
      'checkIn': instance.checkIn?.toIso8601String(),
      'checkOut': instance.checkOut?.toIso8601String(),
      'pricePerNight': instance.pricePerNight,
      'currency': instance.currency,
      'bookingReference': instance.bookingReference,
      'notes': instance.notes,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
