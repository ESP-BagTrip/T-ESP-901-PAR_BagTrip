import 'package:bagtrip/models/trip.dart';

class TripGrouped {
  final List<Trip> ongoing;
  final List<Trip> planned;
  final List<Trip> completed;

  TripGrouped({
    required this.ongoing,
    required this.planned,
    required this.completed,
  });

  factory TripGrouped.fromJson(Map<String, dynamic> json) {
    return TripGrouped(
      ongoing:
          (json['ongoing'] as List<dynamic>?)
              ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      planned:
          (json['planned'] as List<dynamic>?)
              ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      completed:
          (json['completed'] as List<dynamic>?)
              ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
