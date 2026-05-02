part of 'trip_detail_bloc.dart';

/// Handlers for budget CRUD + summary refresh. `CreateBudgetItemFromDetail`
/// keeps its optimistic summary update so the UI reflects the new spend
/// immediately; the other mutations rely on the `RefreshBudgetSummary`
/// follow-up (fired on success) to reconcile the authoritative total.
extension _TripDetailBudgetHandlers on TripDetailBloc {
  Future<void> _onCreateBudgetItemFromDetail(
    CreateBudgetItemFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;
    // Topic 03 (B15) — keep an explicit snapshot of the *exact* summary the
    // user was seeing before the optimistic update so we restore it on
    // failure instead of falling back to a possibly-stale `loaded` copy.
    final preOptimisticSummary = loaded.budgetSummary;

    // Optimistic update — approximate new budget summary
    final amount = (event.data['amount'] as num?)?.toDouble() ?? 0;
    if (preOptimisticSummary != null) {
      final current = preOptimisticSummary;
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
        add(RefreshBudgetSummaryFromDetail());
      case Failure(:final error):
        // Rollback to the pre-optimistic summary, then surface the error.
        if (state is TripDetailLoaded) {
          final reverted = (state as TripDetailLoaded).copyWith(
            budgetSummary: preOptimisticSummary,
            clearBudgetSummary: preOptimisticSummary == null,
            operationError: error,
          );
          emit(reverted);
        }
    }
  }

  Future<void> _onUpdateBudgetItemFromDetail(
    UpdateBudgetItemFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final result = await _budgetRepository.updateBudgetItem(
      _tripId!,
      event.itemId,
      event.data,
    );

    if (isClosed) return;
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;

    switch (result) {
      case Success(:final data):
        final updatedItems = current.budgetItems
            .map((i) => i.id == event.itemId ? data : i)
            .toList();
        emit(current.copyWith(budgetItems: updatedItems));
        add(RefreshBudgetSummaryFromDetail());
      case Failure(:final error):
        emit(loaded.copyWith(operationError: error));
        emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onDeleteBudgetItemFromDetail(
    DeleteBudgetItemFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic removal
    final updatedItems = loaded.budgetItems
        .where((i) => i.id != event.itemId)
        .toList();
    emit(loaded.copyWith(budgetItems: updatedItems));

    final result = await _budgetRepository.deleteBudgetItem(
      _tripId!,
      event.itemId,
    );

    if (isClosed) return;

    switch (result) {
      case Success():
        add(RefreshBudgetSummaryFromDetail());
      case Failure(:final error):
        emit(loaded.copyWith(operationError: error));
        emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onRefreshBudgetSummaryFromDetail(
    RefreshBudgetSummaryFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;

    final results = await Future.wait([
      _budgetRepository.getBudgetSummary(_tripId!),
      _budgetRepository.getBudgetItems(_tripId!),
    ]);

    if (isClosed) return;
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;

    final summaryResult = results[0] as Result<BudgetSummary>;
    final itemsResult = results[1] as Result<List<BudgetItem>>;

    // B19 — surface refresh failures via sectionErrors so the budget
    // panel can render a retry CTA instead of staying silent.
    final updatedSectionErrors = Map<String, AppError>.from(
      current.sectionErrors,
    );
    switch (summaryResult) {
      case Success(:final data):
        updatedSectionErrors.remove('budget');
        emit(
          current.copyWith(
            budgetSummary: data,
            budgetItems: itemsResult.dataOrNull ?? current.budgetItems,
            sectionErrors: updatedSectionErrors,
          ),
        );
      case Failure(:final error):
        updatedSectionErrors['budget'] = error;
        emit(current.copyWith(sectionErrors: updatedSectionErrors));
    }
  }
}
