// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_destination.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiDestination _$AiDestinationFromJson(Map<String, dynamic> json) =>
    _AiDestination(
      city: json['city'] as String,
      country: json['country'] as String,
      iata: json['iata'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      matchReason: json['match_reason'] as String?,
      weatherSummary: json['weather_summary'] as String?,
      imageUrl: json['image_url'] as String?,
      topActivities:
          (json['top_activities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      estimatedBudgetRange: json['estimated_budget_range'] == null
          ? null
          : BudgetRange.fromJson(
              json['estimated_budget_range'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$AiDestinationToJson(_AiDestination instance) =>
    <String, dynamic>{
      'city': instance.city,
      'country': instance.country,
      'iata': instance.iata,
      'lat': instance.lat,
      'lon': instance.lon,
      'match_reason': instance.matchReason,
      'weather_summary': instance.weatherSummary,
      'image_url': instance.imageUrl,
      'top_activities': instance.topActivities,
      'estimated_budget_range': instance.estimatedBudgetRange?.toJson(),
    };
