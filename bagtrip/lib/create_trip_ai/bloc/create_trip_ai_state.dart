part of 'create_trip_ai_bloc.dart';

@immutable
sealed class CreateTripAiState {}

final class CreateTripAiInitial extends CreateTripAiState {}

final class CreateTripAiRecapLoading extends CreateTripAiState {}

final class CreateTripAiRecapLoaded extends CreateTripAiState {
  CreateTripAiRecapLoaded({
    required this.travelTypes,
    required this.travelStyle,
    required this.budget,
    required this.companions,
    this.constraints,
    this.departureDate,
    this.returnDate,
  });

  final String travelTypes;
  final String? travelStyle;
  final String? budget;
  final String? companions;
  final String? constraints;
  final DateTime? departureDate;
  final DateTime? returnDate;

  CreateTripAiRecapLoaded copyWith({
    String? travelTypes,
    String? travelStyle,
    String? budget,
    String? companions,
    String? constraints,
    DateTime? departureDate,
    DateTime? returnDate,
  }) {
    return CreateTripAiRecapLoaded(
      travelTypes: travelTypes ?? this.travelTypes,
      travelStyle: travelStyle ?? this.travelStyle,
      budget: budget ?? this.budget,
      companions: companions ?? this.companions,
      constraints: constraints ?? this.constraints,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
    );
  }
}

final class CreateTripAiResultsLoaded extends CreateTripAiState {
  CreateTripAiResultsLoaded(this.proposals);
  final List<AiTripProposal> proposals;
}

/// Progressive streaming state — accumulates data as SSE events arrive.
final class CreateTripAiStreaming extends CreateTripAiState {
  CreateTripAiStreaming({
    this.phase = 'starting',
    this.message = '',
    this.destinations,
    this.activities,
    this.accommodations,
    this.baggageItems,
    this.budgetEstimation,
  });

  final String phase;
  final String message;
  final List<Map<String, dynamic>>? destinations;
  final List<Map<String, dynamic>>? activities;
  final List<Map<String, dynamic>>? accommodations;
  final List<Map<String, dynamic>>? baggageItems;
  final Map<String, dynamic>? budgetEstimation;

  CreateTripAiStreaming copyWith({
    String? phase,
    String? message,
    List<Map<String, dynamic>>? destinations,
    List<Map<String, dynamic>>? activities,
    List<Map<String, dynamic>>? accommodations,
    List<Map<String, dynamic>>? baggageItems,
    Map<String, dynamic>? budgetEstimation,
  }) {
    return CreateTripAiStreaming(
      phase: phase ?? this.phase,
      message: message ?? this.message,
      destinations: destinations ?? this.destinations,
      activities: activities ?? this.activities,
      accommodations: accommodations ?? this.accommodations,
      baggageItems: baggageItems ?? this.baggageItems,
      budgetEstimation: budgetEstimation ?? this.budgetEstimation,
    );
  }
}

final class CreateTripAiSummaryLoaded extends CreateTripAiState {
  CreateTripAiSummaryLoaded(this.summary);
  final TripSummary summary;
}

final class CreateTripAiSearchLoading extends CreateTripAiState {}

final class CreateTripAiError extends CreateTripAiState {
  CreateTripAiError(this.error);
  final AppError error;
}

final class CreateTripAiTripCreated extends CreateTripAiState {
  CreateTripAiTripCreated(this.tripData);
  final Map<String, dynamic> tripData;
}

final class CreateTripAiQuotaExceeded extends CreateTripAiState {}
