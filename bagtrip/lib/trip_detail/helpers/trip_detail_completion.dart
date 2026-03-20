import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/trip.dart';

/// Calculates trip detail completion percentage (0-100) using Kanban formula.
///
/// 5 segments, 20% each:
/// - Dates set (both startDate AND endDate) → 20%
/// - At least 1 flight → 20%
/// - At least 1 accommodation → 20%
/// - 3+ activities → 20%
/// - 5+ baggage items → 20%
int tripDetailCompletion({
  required Trip trip,
  required List<ManualFlight> flights,
  required List<Accommodation> accommodations,
  required List<Activity> activities,
  required List<BaggageItem> baggageItems,
}) {
  int filled = 0;
  if (trip.startDate != null && trip.endDate != null) filled++;
  if (flights.isNotEmpty) filled++;
  if (accommodations.isNotEmpty) filled++;
  if (activities.length >= 3) filled++;
  if (baggageItems.length >= 5) filled++;

  return (filled / 5 * 100).round();
}
