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
    this.departureDate,
    this.returnDate,
  });

  final String travelTypes;
  final String? travelStyle;
  final String? budget;
  final String? companions;
  final DateTime? departureDate;
  final DateTime? returnDate;

  CreateTripAiRecapLoaded copyWith({
    String? travelTypes,
    String? travelStyle,
    String? budget,
    String? companions,
    DateTime? departureDate,
    DateTime? returnDate,
  }) {
    return CreateTripAiRecapLoaded(
      travelTypes: travelTypes ?? this.travelTypes,
      travelStyle: travelStyle ?? this.travelStyle,
      budget: budget ?? this.budget,
      companions: companions ?? this.companions,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
    );
  }
}

final class CreateTripAiResultsLoaded extends CreateTripAiState {
  CreateTripAiResultsLoaded(this.proposals);
  final List<AiTripProposal> proposals;
}

final class CreateTripAiSummaryLoaded extends CreateTripAiState {
  CreateTripAiSummaryLoaded(this.summary);
  final TripSummary summary;
}

final class CreateTripAiSearchLoading extends CreateTripAiState {}

final class CreateTripAiError extends CreateTripAiState {
  CreateTripAiError(this.message);
  final String message;
}

final class CreateTripAiTripCreated extends CreateTripAiState {
  CreateTripAiTripCreated(this.tripData);
  final Map<String, dynamic> tripData;
}

final class CreateTripAiQuotaExceeded extends CreateTripAiState {}
