part of 'plan_trip_bloc.dart';

@freezed
abstract class PlanTripState with _$PlanTripState {
  const PlanTripState._();

  const factory PlanTripState({
    // Navigation
    @Default(0) int currentStep,

    // Step 0 — Dates
    @Default(DateMode.exact) DateMode dateMode,
    DateTime? startDate,
    DateTime? endDate,
    int? preferredMonth,
    int? preferredYear,
    DurationPreset? flexibleDuration,

    // Step 1 — Travelers + Budget
    @Default(1) int nbTravelers,
    BudgetPreset? budgetPreset,

    // Step 2 — Destination
    @Default([]) List<LocationResult> searchResults,
    @Default(false) bool isSearching,
    LocationResult? selectedManualDestination,
    @Default([]) List<AiDestination> aiSuggestions,
    @Default(false) bool isLoadingAiSuggestions,
    AiDestination? selectedAiDestination,

    // Step 4 — Generation
    @Default({}) Map<String, StepStatus> generationSteps,
    @Default(0.0) double generationProgress,
    String? generationMessage,
    TripPlan? generatedPlan,
    String? generationError,

    // Step 5 — Review / Creation
    @Default(false) bool isCreating,
    String? createdTripId,

    // Meta
    @Default(false) bool isManualFlow,
    String? error,
  }) = _PlanTripState;

  /// Whether dates are valid based on the current [dateMode].
  bool get areDatesValid => switch (dateMode) {
    DateMode.exact =>
      startDate != null && endDate != null && !endDate!.isBefore(startDate!),
    DateMode.month => preferredMonth != null && preferredYear != null,
    DateMode.flexible => flexibleDuration != null,
  };

  /// Whether a destination has been selected (manual or AI).
  bool get isDestinationValid =>
      selectedManualDestination != null || selectedAiDestination != null;

  /// Computed trip duration in days, if determinable.
  int? get tripDurationDays {
    if (startDate != null && endDate != null) {
      return endDate!.difference(startDate!).inDays;
    }
    return switch (flexibleDuration) {
      DurationPreset.weekend => 3,
      DurationPreset.oneWeek => 7,
      DurationPreset.twoWeeks => 14,
      DurationPreset.threeWeeks => 21,
      null => null,
    };
  }

  /// Step to jump to after destination selection.
  int get nextStepAfterDestination => isManualFlow ? 4 : 3;

  /// Total number of steps (visual indicator).
  int get totalSteps => isManualFlow ? 5 : 6;
}
