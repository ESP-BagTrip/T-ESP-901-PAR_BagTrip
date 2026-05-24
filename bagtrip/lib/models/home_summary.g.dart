// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeSummary _$HomeSummaryFromJson(Map<String, dynamic> json) => _HomeSummary(
  ongoingTrips:
      (json['ongoingTrips'] as List<dynamic>?)
          ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  plannedTrips:
      (json['plannedTrips'] as List<dynamic>?)
          ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  completedTrips:
      (json['completedTrips'] as List<dynamic>?)
          ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  user: User.fromJson(json['user'] as Map<String, dynamic>),
  activeTripActivities:
      (json['activeTripActivities'] as List<dynamic>?)
          ?.map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  activeTripWeather: json['activeTripWeather'] == null
      ? null
      : WeatherSummary.fromJson(
          json['activeTripWeather'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$HomeSummaryToJson(_HomeSummary instance) =>
    <String, dynamic>{
      'ongoingTrips': instance.ongoingTrips.map((e) => e.toJson()).toList(),
      'plannedTrips': instance.plannedTrips.map((e) => e.toJson()).toList(),
      'completedTrips': instance.completedTrips.map((e) => e.toJson()).toList(),
      'user': instance.user.toJson(),
      'activeTripActivities': instance.activeTripActivities
          .map((e) => e.toJson())
          .toList(),
      'activeTripWeather': instance.activeTripWeather?.toJson(),
    };
