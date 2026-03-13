import 'package:bagtrip/models/trip.dart';

class TripGrouped {
  final List<Trip> active;
  final List<Trip> planning;
  final List<Trip> completed;
  final List<Trip> archived;

  TripGrouped({
    required this.active,
    required this.planning,
    required this.completed,
    required this.archived,
  });

  factory TripGrouped.fromJson(Map<String, dynamic> json) {
    return TripGrouped(
      active:
          (json['active'] as List<dynamic>?)
              ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      planning:
          (json['planning'] as List<dynamic>?)
              ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      completed:
          (json['completed'] as List<dynamic>?)
              ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      archived:
          (json['archived'] as List<dynamic>?)
              ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
