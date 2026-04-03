part of 'plan_trip_bloc.dart';

@freezed
sealed class PlanTripEvent with _$PlanTripEvent {
  // Navigation
  const factory PlanTripEvent.nextStep() = PlanTripNextStep;
  const factory PlanTripEvent.previousStep() = PlanTripPreviousStep;
  const factory PlanTripEvent.goToStep(int step) = PlanTripGoToStep;

  // Step 0 — Dates
  const factory PlanTripEvent.setDateMode(DateMode mode) = PlanTripSetDateMode;
  const factory PlanTripEvent.setExactDates(DateTime start, DateTime end) =
      PlanTripSetExactDates;
  const factory PlanTripEvent.setMonthPreference(int month, int year) =
      PlanTripSetMonthPreference;
  const factory PlanTripEvent.setFlexibleDuration(DurationPreset preset) =
      PlanTripSetFlexibleDuration;

  // Step 1 — Travelers + Budget
  const factory PlanTripEvent.setTravelerCounts({
    int? adults,
    int? children,
    int? babies,
  }) = PlanTripSetTravelerCounts;
  const factory PlanTripEvent.setBudgetPreset(BudgetPreset? preset) =
      PlanTripSetBudgetPreset;

  // Step 2 — Destination
  const factory PlanTripEvent.searchDestination(String query) =
      PlanTripSearchDestination;
  const factory PlanTripEvent.selectManualDestination(LocationResult location) =
      PlanTripSelectManualDestination;
  const factory PlanTripEvent.requestAiSuggestions() =
      PlanTripRequestAiSuggestions;
  const factory PlanTripEvent.selectAiDestination(AiDestination destination) =
      PlanTripSelectAiDestination;

  // Step 3 — Proposals (swipe)
  const factory PlanTripEvent.swipeProposal(int index) = PlanTripSwipeProposal;

  // Step 4 — Generation
  const factory PlanTripEvent.startGeneration() = PlanTripStartGeneration;
  const factory PlanTripEvent.retryGeneration() = PlanTripRetryGeneration;

  // Step 5 — Review
  const factory PlanTripEvent.createTrip() = PlanTripCreateTrip;
  const factory PlanTripEvent.backToProposals() = PlanTripBackToProposals;
}
