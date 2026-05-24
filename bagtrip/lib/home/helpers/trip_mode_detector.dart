import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/repositories/trip_repository.dart';

class TripModeDetectionResult {
  final List<Trip> transitionedTrips;
  final List<Trip> failedTrips;

  const TripModeDetectionResult({
    this.transitionedTrips = const [],
    this.failedTrips = const [],
  });

  bool get hasTransitions => transitionedTrips.isNotEmpty;
}

Future<TripModeDetectionResult> detectAndTransitionTrips({
  required List<Trip> plannedTrips,
  required TripRepository tripRepository,
  required bool isOnline,
  DateTime? now,
}) async {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);

  final candidates = plannedTrips.where((trip) {
    final start = trip.startDate;
    if (start == null) return false;
    final startDay = DateTime(start.year, start.month, start.day);
    if (startDay.isAfter(today)) return false;

    final end = trip.endDate;
    if (end != null) {
      final endDay = DateTime(end.year, end.month, end.day);
      if (endDay.isBefore(today)) return false;
    }
    return true;
  }).toList();

  if (candidates.isEmpty) {
    return const TripModeDetectionResult();
  }

  // Offline → optimistic local transition
  if (!isOnline) {
    return TripModeDetectionResult(transitionedTrips: candidates);
  }

  // Online → call API in parallel
  final futures = candidates.map(
    (trip) => tripRepository.updateTripStatus(trip.id, 'ongoing'),
  );
  final results = await Future.wait(futures);

  final transitioned = <Trip>[];
  final failed = <Trip>[];

  for (var i = 0; i < candidates.length; i++) {
    final result = results[i];
    if (result is Success<Trip>) {
      transitioned.add(candidates[i]);
    } else {
      failed.add(candidates[i]);
    }
  }

  return TripModeDetectionResult(
    transitionedTrips: transitioned,
    failedTrips: failed,
  );
}
