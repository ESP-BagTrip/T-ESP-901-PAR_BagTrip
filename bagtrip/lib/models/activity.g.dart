// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Activity _$ActivityFromJson(Map<String, dynamic> json) => _Activity(
  id: json['id'] as String,
  tripId: json['trip_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  date: DateTime.parse(json['date'] as String),
  startTime: json['start_time'] as String?,
  endTime: json['end_time'] as String?,
  location: json['location'] as String?,
  category:
      $enumDecodeNullable(
        _$ActivityCategoryEnumMap,
        json['category'],
        unknownValue: ActivityCategory.other,
      ) ??
      ActivityCategory.other,
  estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
  isBooked: json['is_booked'] as bool? ?? false,
  isDone: json['is_done'] as bool? ?? false,
  validationStatus:
      $enumDecodeNullable(
        _$ValidationStatusEnumMap,
        json['validation_status'],
      ) ??
      ValidationStatus.manual,
  suggestedDay: (json['suggested_day'] as num?)?.toInt(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ActivityToJson(_Activity instance) => <String, dynamic>{
  'id': instance.id,
  'trip_id': instance.tripId,
  'title': instance.title,
  'description': instance.description,
  'date': instance.date.toIso8601String(),
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'location': instance.location,
  'category': _$ActivityCategoryEnumMap[instance.category]!,
  'estimated_cost': instance.estimatedCost,
  'is_booked': instance.isBooked,
  'is_done': instance.isDone,
  'validation_status': _$ValidationStatusEnumMap[instance.validationStatus]!,
  'suggested_day': instance.suggestedDay,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$ActivityCategoryEnumMap = {
  ActivityCategory.culture: 'CULTURE',
  ActivityCategory.nature: 'NATURE',
  ActivityCategory.food: 'FOOD',
  ActivityCategory.sport: 'SPORT',
  ActivityCategory.shopping: 'SHOPPING',
  ActivityCategory.nightlife: 'NIGHTLIFE',
  ActivityCategory.relaxation: 'RELAXATION',
  ActivityCategory.other: 'OTHER',
};

const _$ValidationStatusEnumMap = {
  ValidationStatus.suggested: 'SUGGESTED',
  ValidationStatus.validated: 'VALIDATED',
  ValidationStatus.manual: 'MANUAL',
};
