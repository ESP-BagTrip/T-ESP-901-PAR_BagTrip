part of 'create_trip_ai_bloc.dart';

@immutable
sealed class CreateTripAiEvent {}

final class CreateTripAiLoadRecap extends CreateTripAiEvent {}

final class CreateTripAiSetDepartureDate extends CreateTripAiEvent {
  CreateTripAiSetDepartureDate(this.date);
  final DateTime date;
}

final class CreateTripAiSetReturnDate extends CreateTripAiEvent {
  CreateTripAiSetReturnDate(this.date);
  final DateTime date;
}

final class CreateTripAiLaunchSearch extends CreateTripAiEvent {}

final class CreateTripAiSelectProposal extends CreateTripAiEvent {
  CreateTripAiSelectProposal(this.proposal);
  final AiTripProposal proposal;
}

final class CreateTripAiRegenerate extends CreateTripAiEvent {}

final class CreateTripAiAcceptSuggestion extends CreateTripAiEvent {
  CreateTripAiAcceptSuggestion(this.suggestion);
  final AiTripProposal suggestion;
}
