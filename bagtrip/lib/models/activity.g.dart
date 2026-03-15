// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Activity _$ActivityFromJson(Map<String, dynamic> json) => _Activity(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  date: DateTime.parse(json['date'] as String),
  startTime: json['startTime'] as String?,
  endTime: json['endTime'] as String?,
  location: json['location'] as String?,
  category:
      $enumDecodeNullable(_$ActivityCategoryEnumMap, json['category']) ??
      ActivityCategory.other,
  estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
  isBooked: json['isBooked'] as bool? ?? false,
  validationStatus:
      $enumDecodeNullable(
        _$ValidationStatusEnumMap,
        json['validationStatus'],
      ) ??
      ValidationStatus.manual,
  suggestedDay: (json['suggestedDay'] as num?)?.toInt(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ActivityToJson(_Activity instance) => <String, dynamic>{
  'id': instance.id,
  'tripId': instance.tripId,
  'title': instance.title,
  'description': instance.description,
  'date': instance.date.toIso8601String(),
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'location': instance.location,
  'category': _$ActivityCategoryEnumMap[instance.category]!,
  'estimatedCost': instance.estimatedCost,
  'isBooked': instance.isBooked,
  'validationStatus': _$ValidationStatusEnumMap[instance.validationStatus]!,
  'suggestedDay': instance.suggestedDay,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$ActivityCategoryEnumMap = {
  ActivityCategory.visit: 'VISIT',
  ActivityCategory.restaurant: 'RESTAURANT',
  ActivityCategory.transport: 'TRANSPORT',
  ActivityCategory.leisure: 'LEISURE',
  ActivityCategory.other: 'OTHER',
};

const _$ValidationStatusEnumMap = {
  ValidationStatus.suggested: 'SUGGESTED',
  ValidationStatus.validated: 'VALIDATED',
  ValidationStatus.manual: 'MANUAL',
};
