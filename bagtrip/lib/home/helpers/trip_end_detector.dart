import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/service/post_trip_dismissal_storage.dart';

class TripEndDetectionResult {
  final List<Trip> endedTrips;
  final List<Trip> dismissedTrips;

  const TripEndDetectionResult({
    this.endedTrips = const [],
    this.dismissedTrips = const [],
  });
}

/// Detects ongoing trips whose endDate has passed (endDate < today).
/// Filters out trips that were dismissed less than 24h ago.
Future<TripEndDetectionResult> detectEndedTrips({
  required List<Trip> ongoingTrips,
  required PostTripDismissalStorage dismissalStorage,
  DateTime? now,
}) async {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);

  final ended = <Trip>[];
  final dismissed = <Trip>[];

  for (final trip in ongoingTrips) {
    final endDate = trip.endDate;
    if (endDate == null) continue;

    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    if (!endDay.isBefore(today)) continue;

    // Trip has ended — check if recently dismissed
    if (await dismissalStorage.wasDismissedRecently(trip.id)) {
      dismissed.add(trip);
    } else {
      ended.add(trip);
    }
  }

  return TripEndDetectionResult(endedTrips: ended, dismissedTrips: dismissed);
}
