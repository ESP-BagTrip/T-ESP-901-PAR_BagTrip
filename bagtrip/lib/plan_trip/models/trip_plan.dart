import 'package:bagtrip/plan_trip/models/budget_breakdown.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_plan.freezed.dart';
part 'trip_plan.g.dart';

/// One AI recommendation that does not belong to a calendar slot.
///
/// SMP-324 — the activity_planner emits two flavours of undated rows
/// alongside the dated itinerary:
///
/// - ``meals``: 2-4 standout restaurants worth trying during the stay.
/// - ``transports``: 1-3 useful transport items (multi-day pass,
///   airport transfer, ...).
///
/// They render in dedicated sections of the review screen and in
/// dedicated tabs of the trip detail. ``estimatedCost`` is in EUR.
@freezed
abstract class TripRecommendation with _$TripRecommendation {
  const factory TripRecommendation({
    @Default('') String title,
    @Default('') String description,
    @Default(0.0) double estimatedCost,
    @Default('') String location,
  }) = _TripRecommendation;

  factory TripRecommendation.fromJson(Map<String, dynamic> json) =>
      _$TripRecommendationFromJson(json);
}

/// Complete trip plan — evolves from [TripSummary] with richer typed data.
@freezed
abstract class TripPlan with _$TripPlan {
  const factory TripPlan({
    // Destination
    @Default('') String destinationCity,
    @Default('') String destinationCountry,
    String? destinationIata,
    // Trip info
    @Default(7) int durationDays,
    // Topic 03 (B5) — kept as `double` so the SSE breakdown stays
    // precise. The wizard used to cast each category `.toInt()` before
    // summing, losing up to ~2.50 € on a 5-category plan.
    @Default(0.0) double budgetEur,
    @Default([]) List<String> highlights,
    // Accommodation
    @Default('') String accommodationName,
    @Default('') String accommodationSubtitle,
    @Default(0.0) double accommodationPrice,
    @Default('estimated') String accommodationSource,
    // Flight
    @Default('') String flightRoute,
    @Default('') String flightDetails,
    @Default(0.0) double flightPrice,
    @Default('estimated') String flightSource,
    // Flight offer details (from Amadeus)
    @Default('') String originIata,
    @Default('') String flightAirline,
    @Default('') String flightNumber,
    @Default('') String flightDeparture,
    @Default('') String flightArrival,
    @Default('') String flightDuration,
    @Default('') String returnDeparture,
    @Default('') String returnArrival,
    @Default('') String returnDuration,
    // Day-by-day (only dated activities — CULTURE / NATURE / SPORT / ...).
    @Default([]) List<String> dayProgram,
    @Default([]) List<String> dayDescriptions,
    @Default([]) List<String> dayCategories,
    // SMP-324 — undated AI recommendations rendered as dedicated review
    // sections and trip-detail tabs ("Restos à essayer" / "Transports
    // utiles"). Empty when the agent did not surface any.
    @Default([]) List<TripRecommendation> mealRecommendations,
    @Default([]) List<TripRecommendation> transportRecommendations,
    // Baggage
    @Default([]) List<String> essentialItems,
    @Default([]) List<String> essentialReasons,
    // Hotel rating
    @Default(0) int hotelRating,
    // Budget breakdown — typed Freezed view (B13). Replaces the old
    // `Map<String, dynamic>` that produced silent zeros on SSE shape drift.
    @Default(BudgetBreakdown()) BudgetBreakdown budgetBreakdown,
    // Weather
    @Default({}) Map<String, dynamic> weatherData,
  }) = _TripPlan;

  factory TripPlan.fromJson(Map<String, dynamic> json) =>
      _$TripPlanFromJson(json);
}
