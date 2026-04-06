import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/trip.dart';

/// The 6 completion segments displayed in the trip completion bar.
enum CompletionSegmentType {
  dates,
  flights,
  accommodation,
  activities,
  baggage,
  budget,
}

/// Structured result from [tripDetailCompletion].
class CompletionResult {
  final int percentage;
  final Map<CompletionSegmentType, bool> segments;

  const CompletionResult({required this.percentage, required this.segments});
}

/// Calculates trip detail completion percentage (0-100) using Kanban formula.
///
/// 6 segments, ~16.67% each:
/// - Dates set (both startDate AND endDate)
/// - At least 1 flight
/// - At least 1 accommodation
/// - 3+ activities
/// - 5+ baggage items
/// - Budget summary exists
CompletionResult tripDetailCompletion({
  required Trip trip,
  required List<ManualFlight> flights,
  required List<Accommodation> accommodations,
  required List<Activity> activities,
  required List<BaggageItem> baggageItems,
}) {
  final segments = <CompletionSegmentType, bool>{
    CompletionSegmentType.dates: trip.startDate != null && trip.endDate != null,
    CompletionSegmentType.flights: flights.isNotEmpty,
    CompletionSegmentType.accommodation: accommodations.isNotEmpty,
    CompletionSegmentType.activities: activities.length >= 3,
    CompletionSegmentType.baggage: baggageItems.length >= 5,
    CompletionSegmentType.budget:
        trip.budgetTotal != null && trip.budgetTotal! > 0,
  };

  final filled = segments.values.where((v) => v).length;

  return CompletionResult(
    percentage: (filled / 6 * 100).round(),
    segments: segments,
  );
}
