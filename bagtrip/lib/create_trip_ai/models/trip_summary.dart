import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_summary.freezed.dart';
part 'trip_summary.g.dart';

/// Model for the final trip summary (last page).
/// Extended with real data from the multi-agent pipeline.
@freezed
abstract class TripSummary with _$TripSummary {
  const factory TripSummary({
    @Default('') String destination,
    @Default('') String destinationCountry,
    @Default(0) int durationDays,
    @Default(0) int budgetEur,
    @Default([]) List<String> highlights,
    @Default('') String accommodation,
    @Default([]) List<String> dayByDayProgram,
    @Default([]) List<String> essentialItems,
    // Accommodation details (real data from Amadeus)
    @Default('') String accommodationSubtitle,
    @Default(0.0) double accommodationPrice,
    @Default('estimated') String accommodationSource,
    // Flight details (real data from Amadeus)
    @Default('') String flightRoute,
    @Default('') String flightDetails,
    @Default(0.0) double flightPrice,
    @Default('estimated') String flightSource,
    // Day-by-day descriptions and categories from activities
    @Default([]) List<String> dayByDayDescriptions,
    @Default([]) List<String> dayByDayCategories,
    // Baggage reasons
    @Default([]) List<String> essentialReasons,
    // Budget breakdown
    @Default({}) Map<String, dynamic> budgetBreakdown,
    // Weather data
    @Default({}) Map<String, dynamic> weatherData,
  }) = _TripSummary;

  factory TripSummary.fromJson(Map<String, dynamic> json) =>
      _$TripSummaryFromJson(json);
}
