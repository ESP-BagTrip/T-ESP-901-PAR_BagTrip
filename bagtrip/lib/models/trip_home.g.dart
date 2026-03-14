// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_home.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripHomeStats _$TripHomeStatsFromJson(Map<String, dynamic> json) =>
    _TripHomeStats(
      baggageCount: (json['baggageCount'] as num?)?.toInt() ?? 0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      nbTravelers: (json['nbTravelers'] as num?)?.toInt() ?? 1,
      daysUntilTrip: (json['daysUntilTrip'] as num?)?.toInt(),
      tripDuration: (json['tripDuration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TripHomeStatsToJson(_TripHomeStats instance) =>
    <String, dynamic>{
      'baggageCount': instance.baggageCount,
      'totalExpenses': instance.totalExpenses,
      'nbTravelers': instance.nbTravelers,
      'daysUntilTrip': instance.daysUntilTrip,
      'tripDuration': instance.tripDuration,
    };

_TripFeatureTile _$TripFeatureTileFromJson(Map<String, dynamic> json) =>
    _TripFeatureTile(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String,
      route: json['route'] as String,
      enabled: json['enabled'] as bool? ?? false,
    );

Map<String, dynamic> _$TripFeatureTileToJson(_TripFeatureTile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'icon': instance.icon,
      'route': instance.route,
      'enabled': instance.enabled,
    };

_TripHome _$TripHomeFromJson(Map<String, dynamic> json) => _TripHome(
  trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
  stats: TripHomeStats.fromJson(json['stats'] as Map<String, dynamic>),
  features: (json['features'] as List<dynamic>)
      .map((e) => TripFeatureTile.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TripHomeToJson(_TripHome instance) => <String, dynamic>{
  'trip': instance.trip.toJson(),
  'stats': instance.stats.toJson(),
  'features': instance.features.map((e) => e.toJson()).toList(),
};
