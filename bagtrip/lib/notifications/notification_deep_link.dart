import 'package:bagtrip/navigation/route_definitions.dart';

/// Resolves a notification `data` payload to an in-app route path.
///
/// Single source of truth for notification deep links — consumed by every
/// entry point: a foreground FCM relay, a tap on a backgrounded push, a cold
/// start from a terminated push, and the in-app notification list. Returns
/// `null` when the payload carries no routable trip, so callers no-op instead
/// of navigating somewhere wrong.
///
/// The `screen` vocabulary is owned by the backend (see the API's
/// `notification_service.py` / `notification_job.py`): `tripHome`,
/// `activities`, `budget`, `feedback`. Unknown screens fall back to the trip
/// home so a new backend value never strands the user.
String? resolveNotificationRoute(Map<String, dynamic>? data) {
  if (data == null) return null;

  final tripId = data['tripId'];
  if (tripId is! String || tripId.isEmpty) return null;

  return switch (data['screen']) {
    'feedback' => FeedbackRoute(tripId: tripId).location,
    'post-trip' => PostTripRoute(tripId: tripId).location,
    'baggage' => BaggageRoute(tripId: tripId).location,
    'accommodations' => AccommodationsRoute(tripId: tripId).location,
    'map' => MapRoute(tripId: tripId).location,
    // activities / budget / transports / shares — and any unknown screen —
    // all live inside the trip detail surface.
    _ => TripHomeRoute(tripId: tripId).location,
  };
}
