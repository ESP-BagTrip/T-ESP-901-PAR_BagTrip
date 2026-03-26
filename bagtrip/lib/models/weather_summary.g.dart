// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeatherSummary _$WeatherSummaryFromJson(Map<String, dynamic> json) =>
    _WeatherSummary(
      avgTempC: (json['avg_temp_c'] as num).toDouble(),
      description: json['description'] as String,
      rainProbability: (json['rain_probability'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? 'unknown',
    );

Map<String, dynamic> _$WeatherSummaryToJson(_WeatherSummary instance) =>
    <String, dynamic>{
      'avg_temp_c': instance.avgTempC,
      'description': instance.description,
      'rain_probability': instance.rainProbability,
      'source': instance.source,
    };
