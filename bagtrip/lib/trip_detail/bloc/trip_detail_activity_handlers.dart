part of 'trip_detail_bloc.dart';

/// Handlers for activity mutations (validate / reject / move / create /
/// batch / suggest). All work on the shared `activities` list held by
/// `TripDetailLoaded` via optimistic updates.
extension _TripDetailActivityHandlers on TripDetailBloc {
  Future<void> _onValidateActivity(
    ValidateActivity event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic update
    final updatedActivities = loaded.activities
        .map(
          (a) => a.id == event.activityId
              ? a.copyWith(validationStatus: ValidationStatus.validated)
              : a,
        )
        .toList();
    emit(loaded.copyWith(activities: updatedActivities));

    final result = await _activityRepository.updateActivity(
      _tripId!,
      event.activityId,
      {'validation_status': 'VALIDATED'},
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onRejectActivity(
    RejectActivity event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic update — remove rejected activity
    final updatedActivities = loaded.activities
        .where((a) => a.id != event.activityId)
        .toList();
    emit(loaded.copyWith(activities: updatedActivities));

    final result = await _activityRepository.deleteActivity(
      _tripId!,
      event.activityId,
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onBatchValidateActivities(
    BatchValidateActivitiesFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;
    final ids = event.activityIds;

    // Optimistic update
    final updatedActivities = loaded.activities
        .map(
          (a) => ids.contains(a.id)
              ? a.copyWith(validationStatus: ValidationStatus.validated)
              : a,
        )
        .toList();
    emit(loaded.copyWith(activities: updatedActivities));

    final result = await _activityRepository.batchUpdateActivities(
      _tripId!,
      ids,
      {'validationStatus': 'VALIDATED'},
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onUpdateActivityFromDetail(
    UpdateActivityFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final result = await _activityRepository.updateActivity(
      _tripId!,
      event.activityId,
      event.data,
    );

    if (isClosed) return;

    if (result case Success(:final data)) {
      final updatedActivities = loaded.activities
          .map((a) => a.id == event.activityId ? data : a)
          .toList();
      emit(loaded.copyWith(activities: updatedActivities));
    }
  }

  Future<void> _onMoveActivityToDay(
    MoveActivityToDay event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;
    if (loaded.trip.startDate == null) return;

    final newDate = loaded.trip.startDate!.add(
      Duration(days: event.targetDayIndex),
    );
    final dateStr =
        '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';

    // Optimistic update
    final updatedActivities = loaded.activities
        .map((a) => a.id == event.activityId ? a.copyWith(date: newDate) : a)
        .toList();
    emit(loaded.copyWith(activities: updatedActivities));

    final result = await _activityRepository.updateActivity(
      _tripId!,
      event.activityId,
      {'date': dateStr},
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onSuggestActivitiesForDay(
    SuggestActivitiesForDay event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    emit(
      loaded.copyWith(
        suggestingForDay: event.dayNumber,
        clearDaySuggestions: true,
        clearSuggestionsForDay: true,
      ),
    );

    final result = await _activityRepository.suggestActivities(
      _tripId!,
      day: event.dayNumber,
    );

    if (isClosed) return;

    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;

    if (result case Success(:final data)) {
      emit(
        current.copyWith(
          clearSuggestingForDay: true,
          daySuggestions: data,
          suggestionsForDay: event.dayNumber,
        ),
      );
    } else {
      emit(current.copyWith(clearSuggestingForDay: true));
    }
  }

  void _onClearDaySuggestions(
    ClearDaySuggestions event,
    Emitter<TripDetailState> emit,
  ) {
    if (state is! TripDetailLoaded) return;
    final loaded = state as TripDetailLoaded;
    emit(
      loaded.copyWith(clearDaySuggestions: true, clearSuggestionsForDay: true),
    );
  }

  Future<void> _onCreateActivityFromDetail(
    CreateActivityFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final result = await _activityRepository.createActivity(
      _tripId!,
      event.data,
    );

    if (isClosed) return;

    if (result case Success(:final data)) {
      final updatedActivities = [...loaded.activities, data];
      emit(loaded.copyWith(activities: updatedActivities));
    }
  }
}
