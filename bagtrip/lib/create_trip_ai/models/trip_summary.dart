import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_summary.freezed.dart';
part 'trip_summary.g.dart';

/// Model for the final trip summary (last page).
/// Extended with real data from the multi-agent pipeline.
@freezed
abstract class TripSummary with _$TripSummary {
  const factory TripSummary({
    @Default('') String destination,
    @JsonKey(name: 'destinationCountry') @Default('') String destinationCountry,
    @JsonKey(name: 'durationDays') @Default(0) int durationDays,
    @JsonKey(name: 'budgetEur') @Default(0) int budgetEur,
    @Default([]) List<String> highlights,
    @Default('') String accommodation,
    @JsonKey(name: 'dayByDayProgram') @Default([]) List<String> dayByDayProgram,
    @JsonKey(name: 'essentialItems') @Default([]) List<String> essentialItems,
    // Accommodation details (real data from Amadeus)
    @JsonKey(name: 'accommodationSubtitle')
    @Default('')
    String accommodationSubtitle,
    @JsonKey(name: 'accommodationPrice')
    @Default(0.0)
    double accommodationPrice,
    @JsonKey(name: 'accommodationSource')
    @Default('estimated')
    String accommodationSource,
    // Flight details (real data from Amadeus)
    @JsonKey(name: 'flightRoute') @Default('') String flightRoute,
    @JsonKey(name: 'flightDetails') @Default('') String flightDetails,
    @JsonKey(name: 'flightPrice') @Default(0.0) double flightPrice,
    @JsonKey(name: 'flightSource') @Default('estimated') String flightSource,
    // Day-by-day descriptions and categories from activities
    @JsonKey(name: 'dayByDayDescriptions')
    @Default([])
    List<String> dayByDayDescriptions,
    @JsonKey(name: 'dayByDayCategories')
    @Default([])
    List<String> dayByDayCategories,
    // Baggage reasons
    @JsonKey(name: 'essentialReasons')
    @Default([])
    List<String> essentialReasons,
    // Budget breakdown
    @JsonKey(name: 'budgetBreakdown')
    @Default({})
    Map<String, dynamic> budgetBreakdown,
    // Weather data
    @JsonKey(name: 'weatherData') @Default({}) Map<String, dynamic> weatherData,
  }) = _TripSummary;

  factory TripSummary.fromJson(Map<String, dynamic> json) =>
      _$TripSummaryFromJson(json);
}
