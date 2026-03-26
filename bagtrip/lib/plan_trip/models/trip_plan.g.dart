// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripPlan _$TripPlanFromJson(Map<String, dynamic> json) => _TripPlan(
  destinationCity: json['destination_city'] as String? ?? '',
  destinationCountry: json['destination_country'] as String? ?? '',
  destinationIata: json['destination_iata'] as String?,
  durationDays: (json['duration_days'] as num?)?.toInt() ?? 7,
  budgetEur: (json['budget_eur'] as num?)?.toInt() ?? 0,
  highlights:
      (json['highlights'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  accommodationName: json['accommodation_name'] as String? ?? '',
  accommodationSubtitle: json['accommodation_subtitle'] as String? ?? '',
  accommodationPrice: (json['accommodation_price'] as num?)?.toDouble() ?? 0.0,
  accommodationSource: json['accommodation_source'] as String? ?? 'estimated',
  flightRoute: json['flight_route'] as String? ?? '',
  flightDetails: json['flight_details'] as String? ?? '',
  flightPrice: (json['flight_price'] as num?)?.toDouble() ?? 0.0,
  flightSource: json['flight_source'] as String? ?? 'estimated',
  dayProgram:
      (json['day_program'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  dayDescriptions:
      (json['day_descriptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  dayCategories:
      (json['day_categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  essentialItems:
      (json['essential_items'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  essentialReasons:
      (json['essential_reasons'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  budgetBreakdown:
      json['budget_breakdown'] as Map<String, dynamic>? ?? const {},
  weatherData: json['weather_data'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$TripPlanToJson(_TripPlan instance) => <String, dynamic>{
  'destination_city': instance.destinationCity,
  'destination_country': instance.destinationCountry,
  'destination_iata': instance.destinationIata,
  'duration_days': instance.durationDays,
  'budget_eur': instance.budgetEur,
  'highlights': instance.highlights,
  'accommodation_name': instance.accommodationName,
  'accommodation_subtitle': instance.accommodationSubtitle,
  'accommodation_price': instance.accommodationPrice,
  'accommodation_source': instance.accommodationSource,
  'flight_route': instance.flightRoute,
  'flight_details': instance.flightDetails,
  'flight_price': instance.flightPrice,
  'flight_source': instance.flightSource,
  'day_program': instance.dayProgram,
  'day_descriptions': instance.dayDescriptions,
  'day_categories': instance.dayCategories,
  'essential_items': instance.essentialItems,
  'essential_reasons': instance.essentialReasons,
  'budget_breakdown': instance.budgetBreakdown,
  'weather_data': instance.weatherData,
};
