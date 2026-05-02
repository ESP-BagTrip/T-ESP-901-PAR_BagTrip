import 'package:bagtrip/models/trip.dart';

/// Centralises the nullable-`budgetTotal` fallback so callers don't reinvent
/// it (B22). Reading `trip.budgetTotal ?? 0` directly is fragile — a 0
/// total feeds 0 % consumed which reads as "all good" instead of
/// "no budget defined". Use [hasBudget] to gate UI percent / progress
/// rendering and [safeBudgetTotal] for arithmetic that must not throw.
extension TripBudgetExt on Trip {
  /// True when the trip has an explicit, non-zero budget target.
  bool get hasBudget {
    final value = budgetTotal;
    return value != null && value > 0;
  }

  /// Numeric fallback for places that need a number unconditionally.
  /// Returns 0.0 when the budget is missing or non-positive — callers
  /// must check [hasBudget] before computing ratios to avoid feeding
  /// "0 % consumed" as the no-budget signal.
  double get safeBudgetTotal => budgetTotal ?? 0.0;
}
