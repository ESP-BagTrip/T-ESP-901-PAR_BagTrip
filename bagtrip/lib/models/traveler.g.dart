// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'traveler.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Traveler _$TravelerFromJson(Map<String, dynamic> json) => _Traveler(
  id: json['id'] as String,
  tripId: json['trip_id'] as String,
  amadeusTravelerRef: json['amadeus_traveler_ref'] as String?,
  travelerType: json['traveler_type'] as String? ?? 'ADULT',
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  dateOfBirth: json['date_of_birth'] == null
      ? null
      : DateTime.parse(json['date_of_birth'] as String),
  gender: json['gender'] as String?,
  documents: (json['documents'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  contacts: json['contacts'] as Map<String, dynamic>?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$TravelerToJson(_Traveler instance) => <String, dynamic>{
  'id': instance.id,
  'trip_id': instance.tripId,
  'amadeus_traveler_ref': instance.amadeusTravelerRef,
  'traveler_type': instance.travelerType,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'date_of_birth': instance.dateOfBirth?.toIso8601String(),
  'gender': instance.gender,
  'documents': instance.documents,
  'contacts': instance.contacts,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
