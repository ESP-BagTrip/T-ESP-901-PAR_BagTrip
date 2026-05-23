import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_summary.freezed.dart';
part 'home_summary.g.dart';

/// Aggregated payload returned by `GET /home` (SMP327-021).
///
/// Replaces the home fan-out (3 paginated trip reads + `/auth/me` +
/// active-trip activities + active-trip weather) with a single round trip.
/// The server caps each trip list at 5 entries and pre-sorts
/// [activeTripActivities] for the first ongoing trip.
@freezed
abstract class HomeSummary with _$HomeSummary {
  const factory HomeSummary({
    @JsonKey(name: 'ongoingTrips') @Default([]) List<Trip> ongoingTrips,
    @JsonKey(name: 'plannedTrips') @Default([]) List<Trip> plannedTrips,
    @JsonKey(name: 'completedTrips') @Default([]) List<Trip> completedTrips,
    required User user,
    @JsonKey(name: 'activeTripActivities')
    @Default([])
    List<Activity> activeTripActivities,
    @JsonKey(name: 'activeTripWeather') WeatherSummary? activeTripWeather,
  }) = _HomeSummary;

  factory HomeSummary.fromJson(Map<String, dynamic> json) =>
      _$HomeSummaryFromJson(json);
}
