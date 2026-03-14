// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'traveler.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Traveler _$TravelerFromJson(Map<String, dynamic> json) => _Traveler(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  amadeusTravelerRef: json['amadeusTravelerRef'] as String?,
  travelerType: json['travelerType'] as String? ?? 'ADULT',
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  dateOfBirth: json['dateOfBirth'] == null
      ? null
      : DateTime.parse(json['dateOfBirth'] as String),
  gender: json['gender'] as String?,
  documents: (json['documents'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  contacts: json['contacts'] as Map<String, dynamic>?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TravelerToJson(_Traveler instance) => <String, dynamic>{
  'id': instance.id,
  'tripId': instance.tripId,
  'amadeusTravelerRef': instance.amadeusTravelerRef,
  'travelerType': instance.travelerType,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
  'gender': instance.gender,
  'documents': instance.documents,
  'contacts': instance.contacts,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
