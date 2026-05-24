// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripRecommendation _$TripRecommendationFromJson(Map<String, dynamic> json) =>
    _TripRecommendation(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      location: json['location'] as String? ?? '',
    );

Map<String, dynamic> _$TripRecommendationToJson(_TripRecommendation instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'estimated_cost': instance.estimatedCost,
      'location': instance.location,
    };

_TripPlan _$TripPlanFromJson(Map<String, dynamic> json) => _TripPlan(
  destinationCity: json['destination_city'] as String? ?? '',
  destinationCountry: json['destination_country'] as String? ?? '',
  destinationIata: json['destination_iata'] as String?,
  durationDays: (json['duration_days'] as num?)?.toInt() ?? 7,
  budgetEur: (json['budget_eur'] as num?)?.toDouble() ?? 0.0,
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
  originIata: json['origin_iata'] as String? ?? '',
  flightAirline: json['flight_airline'] as String? ?? '',
  flightNumber: json['flight_number'] as String? ?? '',
  flightDeparture: json['flight_departure'] as String? ?? '',
  flightArrival: json['flight_arrival'] as String? ?? '',
  flightDuration: json['flight_duration'] as String? ?? '',
  returnDeparture: json['return_departure'] as String? ?? '',
  returnArrival: json['return_arrival'] as String? ?? '',
  returnDuration: json['return_duration'] as String? ?? '',
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
  mealRecommendations:
      (json['meal_recommendations'] as List<dynamic>?)
          ?.map((e) => TripRecommendation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  transportRecommendations:
      (json['transport_recommendations'] as List<dynamic>?)
          ?.map((e) => TripRecommendation.fromJson(e as Map<String, dynamic>))
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
  hotelRating: (json['hotel_rating'] as num?)?.toInt() ?? 0,
  budgetBreakdown: json['budget_breakdown'] == null
      ? const BudgetBreakdown()
      : BudgetBreakdown.fromJson(
          json['budget_breakdown'] as Map<String, dynamic>,
        ),
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
  'origin_iata': instance.originIata,
  'flight_airline': instance.flightAirline,
  'flight_number': instance.flightNumber,
  'flight_departure': instance.flightDeparture,
  'flight_arrival': instance.flightArrival,
  'flight_duration': instance.flightDuration,
  'return_departure': instance.returnDeparture,
  'return_arrival': instance.returnArrival,
  'return_duration': instance.returnDuration,
  'day_program': instance.dayProgram,
  'day_descriptions': instance.dayDescriptions,
  'day_categories': instance.dayCategories,
  'meal_recommendations': instance.mealRecommendations
      .map((e) => e.toJson())
      .toList(),
  'transport_recommendations': instance.transportRecommendations
      .map((e) => e.toJson())
      .toList(),
  'essential_items': instance.essentialItems,
  'essential_reasons': instance.essentialReasons,
  'hotel_rating': instance.hotelRating,
  'budget_breakdown': instance.budgetBreakdown.toJson(),
  'weather_data': instance.weatherData,
};
