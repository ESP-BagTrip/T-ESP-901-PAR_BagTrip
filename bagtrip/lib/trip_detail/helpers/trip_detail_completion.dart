import 'package:bagtrip/core/trip_enums.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/models/trip.dart';

/// The four domains the user validates on trip_detail. Budget and dates are
/// not tracked here: dates live in the wizard, and budget is a read-only view
/// of the other domains' expenses.
enum CompletionSegmentType { flights, accommodation, activities, baggage }

/// A segment's progress towards "done".
///
/// - [done]: how many items the user has already validated (or packed).
/// - [total]: how many items need a decision. 0 means the segment has no
///   work yet (before the plan is generated) or was skipped globally.
/// - [isSkipped]: the user said "I don't want BagTrip to track this domain".
///   When skipped, the segment contributes 100% to the completion score.
class CompletionSegment {
  const CompletionSegment({
    required this.done,
    required this.total,
    required this.isSkipped,
  });

  final int done;
  final int total;
  final bool isSkipped;

  /// Percentage of this segment (0–100).
  int get percentage {
    if (isSkipped) return 100;
    if (total == 0) return 0;
    return (done / total * 100).round();
  }

  /// Whether the segment is fully resolved (all items validated OR skipped).
  bool get isComplete => isSkipped || (total > 0 && done == total);
}

/// Overall completion result — one segment per domain + the averaged
/// percentage used by progress bars.
class CompletionResult {
  const CompletionResult({required this.percentage, required this.segments});

  final int percentage;
  final Map<CompletionSegmentType, CompletionSegment> segments;

  CompletionSegment segment(CompletionSegmentType type) =>
      segments[type] ??
      const CompletionSegment(done: 0, total: 0, isSkipped: false);
}

/// Validation-aware completion score. A freshly-generated trip where the user
/// hasn't validated anything scores 0% — the plan items sit at
/// [ValidationStatus.suggested] and don't count yet.
///
/// Formula: average of four segments, each 0–100.
CompletionResult tripDetailCompletion({
  required Trip trip,
  required List<ManualFlight> flights,
  required List<Accommodation> accommodations,
  required List<Activity> activities,
  required List<BaggageItem> baggageItems,
}) {
  final flightsSkipped = trip.flightsTracking == TrackingStatus.skipped;
  final accSkipped = trip.accommodationsTracking == TrackingStatus.skipped;

  final segments = <CompletionSegmentType, CompletionSegment>{
    CompletionSegmentType.flights: CompletionSegment(
      done: flights.where((f) => f.validationStatus.isDone).length,
      total: flights.length,
      isSkipped: flightsSkipped,
    ),
    CompletionSegmentType.accommodation: CompletionSegment(
      done: accommodations.where((a) => a.validationStatus.isDone).length,
      total: accommodations.length,
      isSkipped: accSkipped,
    ),
    CompletionSegmentType.activities: CompletionSegment(
      done: activities.where((a) => a.validationStatus.isDone).length,
      total: activities.length,
      isSkipped: false,
    ),
    CompletionSegmentType.baggage: CompletionSegment(
      done: baggageItems.where((b) => b.isPacked).length,
      total: baggageItems.length,
      isSkipped: false,
    ),
  };

  final total = segments.values
      .map((s) => s.percentage)
      .fold<int>(0, (sum, value) => sum + value);

  return CompletionResult(
    percentage: (total / segments.length).round(),
    segments: segments,
  );
}
