// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_grouped.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripGrouped _$TripGroupedFromJson(Map<String, dynamic> json) => _TripGrouped(
  ongoing:
      (json['ongoing'] as List<dynamic>?)
          ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  planned:
      (json['planned'] as List<dynamic>?)
          ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  completed:
      (json['completed'] as List<dynamic>?)
          ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$TripGroupedToJson(_TripGrouped instance) =>
    <String, dynamic>{
      'ongoing': instance.ongoing.map((e) => e.toJson()).toList(),
      'planned': instance.planned.map((e) => e.toJson()).toList(),
      'completed': instance.completed.map((e) => e.toJson()).toList(),
    };
