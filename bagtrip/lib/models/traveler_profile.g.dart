// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'traveler_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TravelerProfile _$TravelerProfileFromJson(Map<String, dynamic> json) =>
    _TravelerProfile(
      id: json['id'] as String,
      travelTypes:
          (json['travelTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      travelStyle: json['travelStyle'] as String?,
      budget: json['budget'] as String?,
      companions: json['companions'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TravelerProfileToJson(_TravelerProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'travelTypes': instance.travelTypes,
      'travelStyle': instance.travelStyle,
      'budget': instance.budget,
      'companions': instance.companions,
      'isCompleted': instance.isCompleted,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_ProfileCompletion _$ProfileCompletionFromJson(Map<String, dynamic> json) =>
    _ProfileCompletion(
      isCompleted: json['isCompleted'] as bool? ?? false,
      missingFields:
          (json['missingFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ProfileCompletionToJson(_ProfileCompletion instance) =>
    <String, dynamic>{
      'isCompleted': instance.isCompleted,
      'missingFields': instance.missingFields,
    };
