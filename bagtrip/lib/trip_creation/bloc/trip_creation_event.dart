part of 'trip_creation_bloc.dart';

@immutable
sealed class TripCreationEvent {}

// Step navigation
class GoToStep extends TripCreationEvent {
  final int step;
  GoToStep(this.step);
}

class NextStep extends TripCreationEvent {}

class PreviousStep extends TripCreationEvent {}

// Step 1 — Destination
class SearchDestination extends TripCreationEvent {
  final String keyword;
  SearchDestination(this.keyword);
}

class SelectDestination extends TripCreationEvent {
  final String name;
  final String iata;
  final String country;
  SelectDestination({
    required this.name,
    required this.iata,
    required this.country,
  });
}

class ClearDestination extends TripCreationEvent {}

class LaunchInspireMe extends TripCreationEvent {}

class SelectAiSuggestion extends TripCreationEvent {
  final AiTripProposal proposal;
  SelectAiSuggestion(this.proposal);
}

// Step 2 — Dates
class SetDates extends TripCreationEvent {
  final DateTime start;
  final DateTime end;
  SetDates({required this.start, required this.end});
}

// Step 3 — Travelers
class SetTravelers extends TripCreationEvent {
  final int count;
  SetTravelers(this.count);
}

// Step 4 — Transport
class SetTransport extends TripCreationEvent {
  final TransportChoice choice;
  SetTransport(this.choice);
}

// Step 5 — Create
class CreateTripFromFlow extends TripCreationEvent {}
