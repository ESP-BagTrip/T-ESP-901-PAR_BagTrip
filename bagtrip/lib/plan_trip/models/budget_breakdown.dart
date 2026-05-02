import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_breakdown.freezed.dart';
part 'budget_breakdown.g.dart';

/// Typed breakdown of an AI-estimated budget (topic 05 / B13).
///
/// Replaces the previous `Map<String, dynamic>` carried by [TripPlan],
/// which caused silent zeros whenever the SSE shape drifted (`{amount}`
/// vs flat number, plural vs singular keys, missing currency, etc.).
/// Keys are aligned with the backend SSE contract (singular,
/// `flight/accommodation/food/transport/activity` — topic 05 B12) and
/// with the Flutter `BudgetCategory` enum.
///
/// Parsing strategy ([fromSseMap]):
/// - Each category accepts either a flat number (`{"flight": 200}`) or
///   a `{amount: X}` object (`{"flight": {"amount": 200, "currency": "EUR"}}`).
/// - Anything else (missing, string, negative) lands as `0.0` — never
///   throws, so a malformed SSE event downgrades gracefully into a
///   visible `0` instead of a runtime crash.
/// - Unknown keys are dropped: the `total_min`, `total_max`, `currency`
///   metadata that the backend ships alongside the categories is
///   ignored here (the wizard reads them separately from `budget_min`
///   / `budget_max` SSE events).
@freezed
abstract class BudgetBreakdown with _$BudgetBreakdown {
  const factory BudgetBreakdown({
    @Default(0.0) double flight,
    @Default(0.0) double accommodation,
    @Default(0.0) double food,
    @Default(0.0) double transport,
    @Default(0.0) double activity,
    @Default(0.0) double other,
  }) = _BudgetBreakdown;

  const BudgetBreakdown._();

  factory BudgetBreakdown.fromJson(Map<String, dynamic> json) =>
      _$BudgetBreakdownFromJson(json);

  /// Parse a breakdown coming from a SSE `budget` event payload.
  ///
  /// Tolerant by design — see class doc for the schema. Always returns
  /// a populated instance (defaults to zeros), never throws.
  factory BudgetBreakdown.fromSseMap(Map<String, dynamic> map) {
    double readKey(String key) {
      final raw = map[key];
      if (raw is num) {
        return raw.toDouble().clamp(0.0, double.infinity).toDouble();
      }
      if (raw is Map) {
        final amount = raw['amount'];
        if (amount is num) {
          return amount.toDouble().clamp(0.0, double.infinity).toDouble();
        }
      }
      return 0.0;
    }

    // Catch any non-canonical key as "other" so the visualisation never
    // hides a category the agent slipped in (e.g. "souvenir").
    const known = {
      'flight',
      'accommodation',
      'food',
      'transport',
      'activity',
      'total_min',
      'total_max',
      'currency',
    };
    double otherTotal = 0.0;
    for (final entry in map.entries) {
      if (known.contains(entry.key)) continue;
      final raw = entry.value;
      if (raw is num) {
        otherTotal += raw.toDouble().clamp(0.0, double.infinity).toDouble();
      } else if (raw is Map) {
        final amount = raw['amount'];
        if (amount is num) {
          otherTotal += amount
              .toDouble()
              .clamp(0.0, double.infinity)
              .toDouble();
        }
      }
    }

    return BudgetBreakdown(
      flight: readKey('flight'),
      accommodation: readKey('accommodation'),
      food: readKey('food'),
      transport: readKey('transport'),
      activity: readKey('activity'),
      other: otherTotal,
    );
  }

  /// Sum of all category amounts. Useful when the wizard needs a total
  /// without reaching for `total_min` / `total_max` (which are LLM
  /// estimates that may not match the breakdown sum).
  double get total =>
      flight + accommodation + food + transport + activity + other;

  /// True when every category is zero — used by the chart widget to
  /// short-circuit rendering.
  bool get isEmpty => total == 0;
}
