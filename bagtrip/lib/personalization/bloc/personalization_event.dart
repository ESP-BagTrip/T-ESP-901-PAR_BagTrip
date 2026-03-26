part of 'personalization_bloc.dart';

@immutable
sealed class PersonalizationEvent {}

class LoadPersonalization extends PersonalizationEvent {}

class SetTravelTypes extends PersonalizationEvent {
  final Set<String> value;

  SetTravelTypes(this.value);
}

class SetTravelStyle extends PersonalizationEvent {
  final String? value;

  SetTravelStyle(this.value);
}

class SetBudget extends PersonalizationEvent {
  final String? value;

  SetBudget(this.value);
}

class SetCompanions extends PersonalizationEvent {
  final String? value;

  SetCompanions(this.value);
}

class PersonalizationNextStep extends PersonalizationEvent {}

class PersonalizationPreviousStep extends PersonalizationEvent {}

class SkipPersonalization extends PersonalizationEvent {}

class SetTravelFrequency extends PersonalizationEvent {
  final String? value;

  SetTravelFrequency(this.value);
}

class SetConstraints extends PersonalizationEvent {
  final String? value;

  SetConstraints(this.value);
}

class SaveAndFinishPersonalization extends PersonalizationEvent {}
