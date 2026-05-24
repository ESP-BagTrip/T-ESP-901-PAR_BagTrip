part of 'baggage_bloc.dart';

sealed class BaggageState {}

class BaggageInitial extends BaggageState {}

class BaggageLoading extends BaggageState {}

class BaggageLoaded extends BaggageState {
  final List<BaggageItem> items;
  final int packedCount;
  final int totalCount;
  final List<SuggestedBaggageItem> suggestions;
  final bool celebrationTriggered;

  BaggageLoaded({
    required this.items,
    required this.packedCount,
    required this.totalCount,
    this.suggestions = const [],
    this.celebrationTriggered = false,
  });
}

class BaggageSuggestionsLoading extends BaggageState {
  final List<BaggageItem> items;
  final int packedCount;
  final int totalCount;

  BaggageSuggestionsLoading({
    required this.items,
    required this.packedCount,
    required this.totalCount,
  });
}

class BaggageQuotaExceeded extends BaggageState {}

class BaggageError extends BaggageState {
  final AppError error;

  BaggageError({required this.error});
}
