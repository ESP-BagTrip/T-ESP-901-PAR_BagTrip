import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/suggested_baggage_item.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/baggage_repository.dart';
import 'package:bloc/bloc.dart';

part 'baggage_event.dart';
part 'baggage_state.dart';

class BaggageBloc extends Bloc<BaggageEvent, BaggageState> {
  final BaggageRepository _baggageRepository;

  BaggageBloc({BaggageRepository? baggageRepository})
    : _baggageRepository = baggageRepository ?? getIt<BaggageRepository>(),
      super(BaggageInitial()) {
    on<LoadBaggage>(_onLoadBaggage);
    on<TogglePacked>(_onTogglePacked);
    on<DeleteBaggageItem>(_onDeleteBaggageItem);
    on<CreateBaggageItem>(_onCreateBaggageItem);
    on<SuggestBaggage>(_onSuggestBaggage);
    on<AcceptSuggestion>(_onAcceptSuggestion);
    on<DismissSuggestion>(_onDismissSuggestion);
    on<ReorderBaggageItem>(_onReorderBaggageItem);
  }

  Future<void> _onLoadBaggage(
    LoadBaggage event,
    Emitter<BaggageState> emit,
  ) async {
    emit(BaggageLoading());
    final result = await _baggageRepository.getByTrip(event.tripId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        final packed = data.where((item) => item.isPacked).length;
        emit(
          BaggageLoaded(
            items: data,
            packedCount: packed,
            totalCount: data.length,
          ),
        );
      case Failure(:final error):
        emit(BaggageError(error: error));
    }
  }

  BaggageLoaded _rebuildLoaded(
    List<BaggageItem> items, {
    List<SuggestedBaggageItem> suggestions = const [],
    bool celebrationTriggered = false,
  }) {
    final packed = items.where((item) => item.isPacked).length;
    return BaggageLoaded(
      items: items,
      packedCount: packed,
      totalCount: items.length,
      suggestions: suggestions,
      celebrationTriggered: celebrationTriggered,
    );
  }

  Future<void> _onTogglePacked(
    TogglePacked event,
    Emitter<BaggageState> emit,
  ) async {
    final result = await _baggageRepository.updateBaggageItem(
      event.tripId,
      event.item.id,
      {'isPacked': !event.item.isPacked},
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        final current = state;
        if (current is BaggageLoaded) {
          final updated = current.items
              .map((i) => i.id == data.id ? data : i)
              .toList();

          // Celebration detection: transition to 100% packed
          final wasPreviouslyAllPacked =
              current.packedCount == current.totalCount;
          final packed = updated.where((i) => i.isPacked).length;
          final isNowAllPacked = packed == updated.length && updated.isNotEmpty;
          final shouldCelebrate = isNowAllPacked && !wasPreviouslyAllPacked;

          emit(
            _rebuildLoaded(
              updated,
              suggestions: current.suggestions,
              celebrationTriggered: shouldCelebrate,
            ),
          );
        } else {
          add(LoadBaggage(tripId: event.tripId));
        }
      case Failure(:final error):
        emit(BaggageError(error: error));
    }
  }

  Future<void> _onDeleteBaggageItem(
    DeleteBaggageItem event,
    Emitter<BaggageState> emit,
  ) async {
    final result = await _baggageRepository.deleteBaggageItem(
      event.tripId,
      event.itemId,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        final current = state;
        if (current is BaggageLoaded) {
          final updated = current.items
              .where((i) => i.id != event.itemId)
              .toList();
          emit(_rebuildLoaded(updated, suggestions: current.suggestions));
        } else {
          add(LoadBaggage(tripId: event.tripId));
        }
      case Failure(:final error):
        emit(BaggageError(error: error));
    }
  }

  Future<void> _onCreateBaggageItem(
    CreateBaggageItem event,
    Emitter<BaggageState> emit,
  ) async {
    final result = await _baggageRepository.createBaggageItem(
      event.tripId,
      name: event.name,
      quantity: event.quantity,
      category: event.category,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        final current = state;
        if (current is BaggageLoaded) {
          final updated = [...current.items, data];
          emit(_rebuildLoaded(updated, suggestions: current.suggestions));
        } else {
          add(LoadBaggage(tripId: event.tripId));
        }
      case Failure(:final error):
        emit(BaggageError(error: error));
    }
  }

  Future<void> _onSuggestBaggage(
    SuggestBaggage event,
    Emitter<BaggageState> emit,
  ) async {
    // Preserve current items while loading suggestions
    final currentState = state;
    if (currentState is BaggageLoaded) {
      emit(
        BaggageSuggestionsLoading(
          items: currentState.items,
          packedCount: currentState.packedCount,
          totalCount: currentState.totalCount,
        ),
      );
    } else {
      emit(BaggageLoading());
    }

    final result = await _baggageRepository.suggestBaggage(event.tripId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        // Restore items from preserved state or reload
        if (currentState is BaggageLoaded) {
          emit(
            BaggageLoaded(
              items: currentState.items,
              packedCount: currentState.packedCount,
              totalCount: currentState.totalCount,
              suggestions: data,
            ),
          );
        } else {
          emit(
            BaggageLoaded(
              items: const [],
              packedCount: 0,
              totalCount: 0,
              suggestions: data,
            ),
          );
        }
      case Failure(:final error):
        if (error is QuotaExceededError) {
          emit(BaggageQuotaExceeded());
        } else {
          emit(BaggageError(error: error));
        }
    }
  }

  Future<void> _onAcceptSuggestion(
    AcceptSuggestion event,
    Emitter<BaggageState> emit,
  ) async {
    final suggestion = event.suggestion;
    final result = await _baggageRepository.createBaggageItem(
      event.tripId,
      name: suggestion.name,
      quantity: suggestion.quantity,
      category: suggestion.category,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        // Remove accepted suggestion from the list, then reload items
        final currentState = state;
        List<SuggestedBaggageItem> remainingSuggestions = [];
        if (currentState is BaggageLoaded) {
          remainingSuggestions = currentState.suggestions
              .where((s) => s != suggestion)
              .toList();
        }
        // Reload items and carry over remaining suggestions
        final itemsResult = await _baggageRepository.getByTrip(event.tripId);
        if (isClosed) return;
        switch (itemsResult) {
          case Success(:final data):
            final packed = data.where((item) => item.isPacked).length;
            emit(
              BaggageLoaded(
                items: data,
                packedCount: packed,
                totalCount: data.length,
                suggestions: remainingSuggestions,
              ),
            );
          case Failure(:final error):
            emit(BaggageError(error: error));
        }
      case Failure(:final error):
        emit(BaggageError(error: error));
    }
  }

  Future<void> _onDismissSuggestion(
    DismissSuggestion event,
    Emitter<BaggageState> emit,
  ) async {
    final currentState = state;
    if (currentState is BaggageLoaded) {
      final remaining = currentState.suggestions
          .where((s) => s != event.suggestion)
          .toList();
      emit(
        BaggageLoaded(
          items: currentState.items,
          packedCount: currentState.packedCount,
          totalCount: currentState.totalCount,
          suggestions: remaining,
        ),
      );
    }
  }

  void _onReorderBaggageItem(
    ReorderBaggageItem event,
    Emitter<BaggageState> emit,
  ) {
    final current = state;
    if (current is! BaggageLoaded) return;

    final unpackedItems = current.items.where((i) => !i.isPacked).toList();
    final packedItems = current.items.where((i) => i.isPacked).toList();

    var newIndex = event.newIndex;
    if (newIndex > event.oldIndex) newIndex--;
    final item = unpackedItems.removeAt(event.oldIndex);
    unpackedItems.insert(newIndex, item);

    final reordered = [...unpackedItems, ...packedItems];
    emit(_rebuildLoaded(reordered, suggestions: current.suggestions));
  }
}
