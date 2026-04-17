part of 'trip_detail_bloc.dart';

/// Handlers for baggage CRUD + packed toggle. Each mutation recomputes
/// `completionResult` because baggage contributes to the trip's completion
/// score (the essentials segment is complete when every item is packed).
extension _TripDetailBaggageHandlers on TripDetailBloc {
  Future<void> _onToggleBaggagePacked(
    ToggleBaggagePackedFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final item = loaded.baggageItems
        .where((b) => b.id == event.baggageItemId)
        .firstOrNull;
    if (item == null) return;

    // Optimistic toggle
    final updatedItems = loaded.baggageItems.map((b) {
      if (b.id == event.baggageItemId) {
        return b.copyWith(isPacked: !b.isPacked);
      }
      return b;
    }).toList();
    final completion = tripDetailCompletion(
      trip: loaded.trip,
      flights: loaded.flights,
      accommodations: loaded.accommodations,
      activities: loaded.activities,
      baggageItems: updatedItems,
    );
    emit(
      loaded.copyWith(baggageItems: updatedItems, completionResult: completion),
    );

    final result = await _baggageRepository.updateBaggageItem(
      _tripId!,
      event.baggageItemId,
      {'isPacked': !item.isPacked},
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onCreateBaggageItemFromDetail(
    CreateBaggageItemFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final data = event.data;
    final result = await _baggageRepository.createBaggageItem(
      _tripId!,
      name: data['name'] as String,
      quantity: data['quantity'] as int?,
      isPacked: data['isPacked'] as bool?,
      category: data['category'] as String?,
      notes: data['notes'] as String?,
    );

    if (isClosed) return;
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;

    switch (result) {
      case Success(:final data):
        final updatedItems = [...current.baggageItems, data];
        final completion = tripDetailCompletion(
          trip: current.trip,
          flights: current.flights,
          accommodations: current.accommodations,
          activities: current.activities,
          baggageItems: updatedItems,
        );
        emit(
          current.copyWith(
            baggageItems: updatedItems,
            completionResult: completion,
          ),
        );
      case Failure(:final error):
        emit(loaded.copyWith(operationError: error));
        emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onUpdateBaggageItemFromDetail(
    UpdateBaggageItemFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final result = await _baggageRepository.updateBaggageItem(
      _tripId!,
      event.baggageItemId,
      event.data,
    );

    if (isClosed) return;
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;

    switch (result) {
      case Success(:final data):
        final updatedItems = current.baggageItems
            .map((b) => b.id == event.baggageItemId ? data : b)
            .toList();
        final completion = tripDetailCompletion(
          trip: current.trip,
          flights: current.flights,
          accommodations: current.accommodations,
          activities: current.activities,
          baggageItems: updatedItems,
        );
        emit(
          current.copyWith(
            baggageItems: updatedItems,
            completionResult: completion,
          ),
        );
      case Failure(:final error):
        emit(loaded.copyWith(operationError: error));
        emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onDeleteBaggageItem(
    DeleteBaggageItemFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic removal
    final updatedItems = loaded.baggageItems
        .where((b) => b.id != event.baggageItemId)
        .toList();
    final completion = tripDetailCompletion(
      trip: loaded.trip,
      flights: loaded.flights,
      accommodations: loaded.accommodations,
      activities: loaded.activities,
      baggageItems: updatedItems,
    );
    emit(
      loaded.copyWith(baggageItems: updatedItems, completionResult: completion),
    );

    final result = await _baggageRepository.deleteBaggageItem(
      _tripId!,
      event.baggageItemId,
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }
}
