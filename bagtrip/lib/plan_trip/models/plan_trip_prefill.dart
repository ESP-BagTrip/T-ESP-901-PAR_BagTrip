import 'package:bagtrip/plan_trip/models/location_result.dart';

/// Lightweight bundle of pre-fill values forwarded into the plan-trip wizard
/// (via GoRouter `$extra`) so an external entry point — e.g. the post-trip
/// "Create this trip" CTA — can seed the wizard with a destination, a trip
/// duration and a target budget while keeping every field editable.
class PlanTripPrefill {
  const PlanTripPrefill({
    required this.destination,
    this.durationDays,
    this.budgetEur,
  });

  /// Destination to select as the manual destination of the wizard.
  final LocationResult destination;

  /// Suggested trip length in days. Applied as a flexible-duration preset so
  /// the dates step starts pre-filled while remaining user-editable.
  final int? durationDays;

  /// Suggested total budget in EUR. Mapped to the closest [BudgetPreset] so
  /// the travelers/budget step starts pre-selected.
  final double? budgetEur;
}
