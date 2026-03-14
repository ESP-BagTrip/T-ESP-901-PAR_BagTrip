import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_summary.freezed.dart';
part 'trip_summary.g.dart';

/// Model for the final trip summary (last page).
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
  }) = _TripSummary;

  factory TripSummary.fromJson(Map<String, dynamic> json) =>
      _$TripSummaryFromJson(json);
}
