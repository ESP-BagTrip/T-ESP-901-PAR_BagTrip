import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:bagtrip/models/trip.dart';

part 'trip_grouped.freezed.dart';
part 'trip_grouped.g.dart';

@freezed
abstract class TripGrouped with _$TripGrouped {
  const factory TripGrouped({
    @Default([]) List<Trip> ongoing,
    @Default([]) List<Trip> planned,
    @Default([]) List<Trip> completed,
  }) = _TripGrouped;

  factory TripGrouped.fromJson(Map<String, dynamic> json) =>
      _$TripGroupedFromJson(json);
}
