// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Trip _$TripFromJson(Map<String, dynamic> json) => _Trip(
  id: json['id'] as String,
  userId: json['userId'] as String?,
  title: json['title'] as String?,
  originIata: json['originIata'] as String?,
  destinationIata: json['destinationIata'] as String?,
  startDate: json['startDate'] == null
      ? null
      : DateTime.parse(json['startDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  status: json['status'] == null
      ? TripStatus.draft
      : const TripStatusConverter().fromJson(json['status'] as String),
  description: json['description'] as String?,
  destinationName: json['destinationName'] as String?,
  nbTravelers: (json['nbTravelers'] as num?)?.toInt(),
  coverImageUrl: json['coverImageUrl'] as String?,
  budgetTotal: (json['budgetTotal'] as num?)?.toDouble(),
  origin: json['origin'] as String?,
  role: json['role'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TripToJson(_Trip instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'title': instance.title,
  'originIata': instance.originIata,
  'destinationIata': instance.destinationIata,
  'startDate': instance.startDate?.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'status': const TripStatusConverter().toJson(instance.status),
  'description': instance.description,
  'destinationName': instance.destinationName,
  'nbTravelers': instance.nbTravelers,
  'coverImageUrl': instance.coverImageUrl,
  'budgetTotal': instance.budgetTotal,
  'origin': instance.origin,
  'role': instance.role,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
