part of 'trip_creation_bloc.dart';

enum TransportChoice { flight, other, skip }

@immutable
class TripCreationState {
  final int currentStep;

  // Step 1 — Destination
  final String? destinationName;
  final String? destinationIata;
  final String? destinationCountry;
  final List<Map<String, dynamic>>? locationResults;
  final List<AiTripProposal>? aiSuggestions;
  final AiTripProposal? selectedAiProposal;
  final bool isLoadingLocations;
  final bool isLoadingAi;

  // Step 2 — Dates
  final DateTime? startDate;
  final DateTime? endDate;

  // Step 3 — Travelers
  final int nbTravelers;

  // Step 4 — Transport
  final TransportChoice? transportChoice;

  // Status
  final bool isCreating;
  final String? error;
  final String? createdTripId;

  const TripCreationState({
    this.currentStep = 0,
    this.destinationName,
    this.destinationIata,
    this.destinationCountry,
    this.locationResults,
    this.aiSuggestions,
    this.selectedAiProposal,
    this.isLoadingLocations = false,
    this.isLoadingAi = false,
    this.startDate,
    this.endDate,
    this.nbTravelers = 2,
    this.transportChoice,
    this.isCreating = false,
    this.error,
    this.createdTripId,
  });

  TripCreationState copyWith({
    int? currentStep,
    String? destinationName,
    String? destinationIata,
    String? destinationCountry,
    List<Map<String, dynamic>>? locationResults,
    List<AiTripProposal>? aiSuggestions,
    AiTripProposal? selectedAiProposal,
    bool? isLoadingLocations,
    bool? isLoadingAi,
    DateTime? startDate,
    DateTime? endDate,
    int? nbTravelers,
    TransportChoice? transportChoice,
    bool? isCreating,
    String? error,
    String? createdTripId,
    bool clearError = false,
    bool clearLocationResults = false,
    bool clearAiSuggestions = false,
    bool clearSelectedAi = false,
    bool clearDestination = false,
  }) {
    return TripCreationState(
      currentStep: currentStep ?? this.currentStep,
      destinationName: clearDestination
          ? null
          : (destinationName ?? this.destinationName),
      destinationIata: clearDestination
          ? null
          : (destinationIata ?? this.destinationIata),
      destinationCountry: clearDestination
          ? null
          : (destinationCountry ?? this.destinationCountry),
      locationResults: clearLocationResults
          ? null
          : (locationResults ?? this.locationResults),
      aiSuggestions: clearAiSuggestions
          ? null
          : (aiSuggestions ?? this.aiSuggestions),
      selectedAiProposal: clearSelectedAi
          ? null
          : (selectedAiProposal ?? this.selectedAiProposal),
      isLoadingLocations: isLoadingLocations ?? this.isLoadingLocations,
      isLoadingAi: isLoadingAi ?? this.isLoadingAi,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nbTravelers: nbTravelers ?? this.nbTravelers,
      transportChoice: transportChoice ?? this.transportChoice,
      isCreating: isCreating ?? this.isCreating,
      error: clearError ? null : (error ?? this.error),
      createdTripId: createdTripId ?? this.createdTripId,
    );
  }

  bool get isDestinationValid =>
      destinationName != null && destinationName!.isNotEmpty;
  bool get areDatesValid =>
      startDate != null && endDate != null && !endDate!.isBefore(startDate!);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripCreationState &&
          currentStep == other.currentStep &&
          destinationName == other.destinationName &&
          destinationIata == other.destinationIata &&
          destinationCountry == other.destinationCountry &&
          locationResults == other.locationResults &&
          aiSuggestions == other.aiSuggestions &&
          selectedAiProposal == other.selectedAiProposal &&
          isLoadingLocations == other.isLoadingLocations &&
          isLoadingAi == other.isLoadingAi &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          nbTravelers == other.nbTravelers &&
          transportChoice == other.transportChoice &&
          isCreating == other.isCreating &&
          error == other.error &&
          createdTripId == other.createdTripId;

  @override
  int get hashCode => Object.hash(
    currentStep,
    destinationName,
    destinationIata,
    startDate,
    endDate,
    nbTravelers,
    transportChoice,
    isCreating,
    error,
    createdTripId,
  );
}
