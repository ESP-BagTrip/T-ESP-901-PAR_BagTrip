part of 'trip_detail_bloc.dart';

/// Handlers for baggage, budget and share mutations. Grouped together
/// because each domain only has 1–2 events here; splitting them into
/// dedicated files would just add import noise.
extension _TripDetailMiscHandlers on TripDetailBloc {
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

  Future<void> _onCreateBudgetItemFromDetail(
    CreateBudgetItemFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic update — approximate new budget summary
    final amount = (event.data['amount'] as num?)?.toDouble() ?? 0;
    if (loaded.budgetSummary != null) {
      final current = loaded.budgetSummary!;
      final newSpent = current.totalSpent + amount;
      final newRemaining = current.totalBudget - newSpent;
      final newPercent = current.totalBudget > 0
          ? (newSpent / current.totalBudget) * 100
          : 0.0;
      String? newAlertLevel;
      if (newPercent >= 100) {
        newAlertLevel = 'DANGER';
      } else if (newPercent >= 80) {
        newAlertLevel = 'WARNING';
      }
      final optimistic = current.copyWith(
        totalSpent: newSpent,
        remaining: newRemaining,
        percentConsumed: newPercent,
        alertLevel: newAlertLevel,
      );
      emit(loaded.copyWith(budgetSummary: optimistic));
    }

    final result = await _budgetRepository.createBudgetItem(
      _tripId!,
      event.data,
    );

    if (isClosed) return;

    switch (result) {
      case Success():
        add(RefreshTripDetail());
      case Failure(:final error):
        emit(loaded.copyWith(operationError: error));
        emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onDeleteShare(
    DeleteShareFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic removal
    final updatedShares = loaded.shares
        .where((s) => s.id != event.shareId)
        .toList();
    emit(loaded.copyWith(shares: updatedShares));

    final result = await _tripShareRepository.deleteShare(
      _tripId!,
      event.shareId,
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }
}
