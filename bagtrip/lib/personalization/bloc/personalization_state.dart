part of 'personalization_bloc.dart';

@immutable
sealed class PersonalizationState {}

final class PersonalizationInitial extends PersonalizationState {}

final class PersonalizationLoading extends PersonalizationState {}

final class PersonalizationLoaded extends PersonalizationState {
  final int step;
  final String userId;
  final Set<String> selectedTravelTypes;
  final String? travelStyle;
  final String? budget;
  final String? companions;

  PersonalizationLoaded({
    required this.step,
    required this.userId,
    required this.selectedTravelTypes,
    this.travelStyle,
    this.budget,
    this.companions,
  });

  PersonalizationLoaded copyWith({
    int? step,
    String? userId,
    Set<String>? selectedTravelTypes,
    String? travelStyle,
    String? budget,
    String? companions,
  }) {
    return PersonalizationLoaded(
      step: step ?? this.step,
      userId: userId ?? this.userId,
      selectedTravelTypes: selectedTravelTypes ?? this.selectedTravelTypes,
      travelStyle: travelStyle ?? this.travelStyle,
      budget: budget ?? this.budget,
      companions: companions ?? this.companions,
    );
  }
}

/// Emitted when the user skipped or finished; view should navigate away.
final class PersonalizationCompleted extends PersonalizationState {}

final class PersonalizationSkipped extends PersonalizationState {}
