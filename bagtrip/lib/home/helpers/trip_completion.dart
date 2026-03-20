import 'package:bagtrip/models/trip.dart';

/// Calculates a trip completion percentage (0-100) based on filled fields.
///
/// Each field contributes 20%:
/// - [startDate] is non-null
/// - [endDate] is non-null
/// - [destinationName] is non-null and non-empty
/// - [nbTravelers] > 0
/// - [budgetTotal] > 0
int tripCompletion(Trip? trip) {
  if (trip == null) return 0;

  int filled = 0;
  if (trip.startDate != null) filled++;
  if (trip.endDate != null) filled++;
  if (trip.destinationName != null && trip.destinationName!.isNotEmpty) {
    filled++;
  }
  if (trip.nbTravelers != null && trip.nbTravelers! > 0) filled++;
  if (trip.budgetTotal != null && trip.budgetTotal! > 0) filled++;

  return (filled / 5 * 100).round();
}
