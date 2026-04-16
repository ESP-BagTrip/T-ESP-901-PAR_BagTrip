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
    @Default(1) int nbAdults,
    @Default(0) int nbChildren,
    @Default(0) int nbBabies,
    BudgetPreset? budgetPreset,
    String? originCity,
    @Default([]) List<LocationResult> originSearchResults,

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
    AppError? error,
  }) = _PlanTripState;

  /// Total travelers for API and budget (sum of breakdown).
  int get nbTravelers => nbAdults + nbChildren + nbBabies;

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
    return switch (dateMode) {
      DateMode.exact => null,
      DateMode.month => switch (flexibleDuration) {
        DurationPreset.weekend => 3,
        DurationPreset.oneWeek => 7,
        DurationPreset.twoWeeks => 14,
        DurationPreset.threeWeeks => 21,
        null => 7, // default 1 week for month mode
      },
      DateMode.flexible => switch (flexibleDuration) {
        DurationPreset.weekend => 3,
        DurationPreset.oneWeek => 7,
        DurationPreset.twoWeeks => 14,
        DurationPreset.threeWeeks => 21,
        null => null,
      },
    };
  }

  /// Duration that always resolves (never null). Used for API calls.
  int get effectiveDurationDays => tripDurationDays ?? 7;

  /// Representative dates for API calls.
  /// Exact → real dates. Month → 15th of month. Flexible → now + 30 days.
  (DateTime, DateTime) get representativeDates {
    switch (dateMode) {
      case DateMode.exact:
        if (startDate != null && endDate != null) {
          return (startDate!, endDate!);
        }
        final s = DateTime.now().add(const Duration(days: 30));
        return (s, s.add(Duration(days: effectiveDurationDays)));
      case DateMode.month:
        final year = preferredYear ?? DateTime.now().year;
        final month = preferredMonth ?? (DateTime.now().month + 1);
        final s = DateTime(year, month, 15);
        return (s, s.add(Duration(days: effectiveDurationDays)));
      case DateMode.flexible:
        final s = DateTime.now().add(const Duration(days: 30));
        return (s, s.add(Duration(days: effectiveDurationDays)));
    }
  }

  /// Whether dates are derived (not user-specified exact dates).
  bool get areDatesRepresentative => dateMode != DateMode.exact;

  /// Step to jump to after destination selection.
  int get nextStepAfterDestination => isManualFlow ? 4 : 3;

  /// Total number of steps (visual indicator).
  int get totalSteps => isManualFlow ? 5 : 6;
}
