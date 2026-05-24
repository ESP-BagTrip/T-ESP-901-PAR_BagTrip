import 'package:bagtrip/plan_trip/models/budget_preset.dart';
import 'package:bagtrip/plan_trip/models/budget_range.dart';

/// Estimates a total budget range based on preset, travelers, and duration.
///
/// Pure function — no side effects, trivially testable.
BudgetRange estimateBudget({
  required BudgetPreset preset,
  required int nbTravelers,
  required int days,
}) {
  final (minPerDay, maxPerDay) = switch (preset) {
    BudgetPreset.backpacker => (30.0, 60.0),
    BudgetPreset.comfortable => (80.0, 150.0),
    BudgetPreset.premium => (200.0, 400.0),
    BudgetPreset.noLimit => (400.0, 1000.0),
  };
  return BudgetRange(
    min: nbTravelers * minPerDay * days,
    max: nbTravelers * maxPerDay * days,
  );
}
