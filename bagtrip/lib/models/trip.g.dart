// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Trip _$TripFromJson(Map<String, dynamic> json) => _Trip(
  id: json['id'] as String,
  userId: json['user_id'] as String?,
  title: json['title'] as String?,
  originIata: json['origin_iata'] as String?,
  destinationIata: json['destination_iata'] as String?,
  startDate: json['start_date'] == null
      ? null
      : DateTime.parse(json['start_date'] as String),
  endDate: json['end_date'] == null
      ? null
      : DateTime.parse(json['end_date'] as String),
  status: json['status'] == null
      ? TripStatus.draft
      : const TripStatusConverter().fromJson(json['status'] as String),
  description: json['description'] as String?,
  destinationName: json['destination_name'] as String?,
  destinationTimezone: json['destination_timezone'] as String?,
  nbTravelers: (json['nb_travelers'] as num?)?.toInt(),
  coverImageUrl: json['cover_image_url'] as String?,
  budgetTarget: (json['budget_target'] as num?)?.toDouble(),
  budgetEstimated: (json['budget_estimated'] as num?)?.toDouble(),
  budgetActual: (json['budget_actual'] as num?)?.toDouble(),
  origin: json['origin'] as String?,
  role: json['role'] as String?,
  completionPercentage: (json['completion_percentage'] as num?)?.toInt() ?? 0,
  flightsTracking: json['flights_tracking'] as String? ?? 'TRACKED',
  accommodationsTracking:
      json['accommodations_tracking'] as String? ?? 'TRACKED',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$TripToJson(_Trip instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'title': instance.title,
  'origin_iata': instance.originIata,
  'destination_iata': instance.destinationIata,
  'start_date': instance.startDate?.toIso8601String(),
  'end_date': instance.endDate?.toIso8601String(),
  'status': const TripStatusConverter().toJson(instance.status),
  'description': instance.description,
  'destination_name': instance.destinationName,
  'destination_timezone': instance.destinationTimezone,
  'nb_travelers': instance.nbTravelers,
  'cover_image_url': instance.coverImageUrl,
  'budget_target': instance.budgetTarget,
  'budget_estimated': instance.budgetEstimated,
  'budget_actual': instance.budgetActual,
  'origin': instance.origin,
  'role': instance.role,
  'completion_percentage': instance.completionPercentage,
  'flights_tracking': instance.flightsTracking,
  'accommodations_tracking': instance.accommodationsTracking,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
