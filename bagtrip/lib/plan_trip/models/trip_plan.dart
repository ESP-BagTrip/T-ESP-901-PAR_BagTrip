import 'package:bagtrip/plan_trip/models/budget_breakdown.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_plan.freezed.dart';
part 'trip_plan.g.dart';

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
    // Day-by-day
    @Default([]) List<String> dayProgram,
    @Default([]) List<String> dayDescriptions,
    @Default([]) List<String> dayCategories,
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
