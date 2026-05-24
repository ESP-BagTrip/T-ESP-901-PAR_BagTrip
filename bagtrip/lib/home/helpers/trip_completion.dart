import 'package:bagtrip/models/trip.dart';

/// Returns the server-computed trip completion percentage (0-100).
///
/// The API computes this using 6 segments (~16.67% each):
/// - Dates set (both startDate AND endDate)
/// - At least 1 flight
/// - At least 1 accommodation
/// - 3+ activities
/// - 5+ baggage items
/// - Budget total > 0
int tripCompletion(Trip? trip) {
  if (trip == null) return 0;
  return trip.completionPercentage;
}
