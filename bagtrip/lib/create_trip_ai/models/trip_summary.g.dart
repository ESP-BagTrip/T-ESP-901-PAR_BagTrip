// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripSummary _$TripSummaryFromJson(Map<String, dynamic> json) => _TripSummary(
  destination: json['destination'] as String? ?? '',
  destinationCountry: json['destinationCountry'] as String? ?? '',
  durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
  budgetEur: (json['budgetEur'] as num?)?.toInt() ?? 0,
  highlights:
      (json['highlights'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  accommodation: json['accommodation'] as String? ?? '',
  dayByDayProgram:
      (json['dayByDayProgram'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  essentialItems:
      (json['essentialItems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$TripSummaryToJson(_TripSummary instance) =>
    <String, dynamic>{
      'destination': instance.destination,
      'destinationCountry': instance.destinationCountry,
      'durationDays': instance.durationDays,
      'budgetEur': instance.budgetEur,
      'highlights': instance.highlights,
      'accommodation': instance.accommodation,
      'dayByDayProgram': instance.dayByDayProgram,
      'essentialItems': instance.essentialItems,
    };
