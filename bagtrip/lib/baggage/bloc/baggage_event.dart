part of 'baggage_bloc.dart';

sealed class BaggageEvent {}

class LoadBaggage extends BaggageEvent {
  final String tripId;

  LoadBaggage({required this.tripId});
}

class TogglePacked extends BaggageEvent {
  final String tripId;
  final BaggageItem item;

  TogglePacked({required this.tripId, required this.item});
}

class DeleteBaggageItem extends BaggageEvent {
  final String tripId;
  final String itemId;

  DeleteBaggageItem({required this.tripId, required this.itemId});
}

class CreateBaggageItem extends BaggageEvent {
  final String tripId;
  final String name;
  final int quantity;
  final String category;

  CreateBaggageItem({
    required this.tripId,
    required this.name,
    required this.quantity,
    required this.category,
  });
}

class SuggestBaggage extends BaggageEvent {
  final String tripId;

  SuggestBaggage({required this.tripId});
}

class AcceptSuggestion extends BaggageEvent {
  final String tripId;
  final SuggestedBaggageItem suggestion;

  AcceptSuggestion({required this.tripId, required this.suggestion});
}

class DismissSuggestion extends BaggageEvent {
  final SuggestedBaggageItem suggestion;

  DismissSuggestion({required this.suggestion});
}

class UpdateBaggageItem extends BaggageEvent {
  final String tripId;
  final String itemId;
  final String name;
  final int quantity;
  final String category;

  UpdateBaggageItem({
    required this.tripId,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.category,
  });
}

class ReorderBaggageItem extends BaggageEvent {
  final int oldIndex;
  final int newIndex;

  ReorderBaggageItem({required this.oldIndex, required this.newIndex});
}
