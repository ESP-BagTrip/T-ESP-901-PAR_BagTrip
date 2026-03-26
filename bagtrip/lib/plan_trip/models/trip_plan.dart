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
    @Default(0) int budgetEur,
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
    // Day-by-day
    @Default([]) List<String> dayProgram,
    @Default([]) List<String> dayDescriptions,
    @Default([]) List<String> dayCategories,
    // Baggage
    @Default([]) List<String> essentialItems,
    @Default([]) List<String> essentialReasons,
    // Budget breakdown
    @Default({}) Map<String, dynamic> budgetBreakdown,
    // Weather
    @Default({}) Map<String, dynamic> weatherData,
  }) = _TripPlan;

  factory TripPlan.fromJson(Map<String, dynamic> json) =>
      _$TripPlanFromJson(json);
}
