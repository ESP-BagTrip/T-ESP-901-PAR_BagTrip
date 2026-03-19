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
  accommodationSubtitle: json['accommodationSubtitle'] as String? ?? '',
  accommodationPrice: (json['accommodationPrice'] as num?)?.toDouble() ?? 0.0,
  accommodationSource: json['accommodationSource'] as String? ?? 'estimated',
  flightRoute: json['flightRoute'] as String? ?? '',
  flightDetails: json['flightDetails'] as String? ?? '',
  flightPrice: (json['flightPrice'] as num?)?.toDouble() ?? 0.0,
  flightSource: json['flightSource'] as String? ?? 'estimated',
  dayByDayDescriptions:
      (json['dayByDayDescriptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  dayByDayCategories:
      (json['dayByDayCategories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  essentialReasons:
      (json['essentialReasons'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  budgetBreakdown: json['budgetBreakdown'] as Map<String, dynamic>? ?? const {},
  weatherData: json['weatherData'] as Map<String, dynamic>? ?? const {},
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
      'accommodationSubtitle': instance.accommodationSubtitle,
      'accommodationPrice': instance.accommodationPrice,
      'accommodationSource': instance.accommodationSource,
      'flightRoute': instance.flightRoute,
      'flightDetails': instance.flightDetails,
      'flightPrice': instance.flightPrice,
      'flightSource': instance.flightSource,
      'dayByDayDescriptions': instance.dayByDayDescriptions,
      'dayByDayCategories': instance.dayByDayCategories,
      'essentialReasons': instance.essentialReasons,
      'budgetBreakdown': instance.budgetBreakdown,
      'weatherData': instance.weatherData,
    };
