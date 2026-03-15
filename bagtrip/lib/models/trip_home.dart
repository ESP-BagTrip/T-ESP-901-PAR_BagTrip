import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:bagtrip/models/trip.dart';

part 'trip_home.freezed.dart';
part 'trip_home.g.dart';

@freezed
abstract class TripHomeStats with _$TripHomeStats {
  const factory TripHomeStats({
    @Default(0) int baggageCount,
    @Default(0.0) double totalExpenses,
    @Default(1) int nbTravelers,
    int? daysUntilTrip,
    int? tripDuration,
  }) = _TripHomeStats;

  factory TripHomeStats.fromJson(Map<String, dynamic> json) =>
      _$TripHomeStatsFromJson(json);
}

@freezed
abstract class TripFeatureTile with _$TripFeatureTile {
  const factory TripFeatureTile({
    required String id,
    required String label,
    required String icon,
    required String route,
    @Default(false) bool enabled,
  }) = _TripFeatureTile;

  factory TripFeatureTile.fromJson(Map<String, dynamic> json) =>
      _$TripFeatureTileFromJson(json);
}

@freezed
abstract class TripSectionSummary with _$TripSectionSummary {
  const factory TripSectionSummary({
    required String sectionId,
    @Default(0) int count,
    @Default([]) List<String> previewItems,
  }) = _TripSectionSummary;

  factory TripSectionSummary.fromJson(Map<String, dynamic> json) =>
      _$TripSectionSummaryFromJson(json);
}

@freezed
abstract class TripHome with _$TripHome {
  const factory TripHome({
    required Trip trip,
    required TripHomeStats stats,
    required List<TripFeatureTile> features,
    @Default([]) List<TripSectionSummary> sections,
  }) = _TripHome;

  factory TripHome.fromJson(Map<String, dynamic> json) =>
      _$TripHomeFromJson(json);
}
