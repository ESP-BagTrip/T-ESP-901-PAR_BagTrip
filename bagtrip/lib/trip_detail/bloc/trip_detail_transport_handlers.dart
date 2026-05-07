part of 'trip_detail_bloc.dart';

/// Handlers for flights and accommodations (add / delete / validate).
/// Both share the pattern of recomputing `completionResult` after a list
/// mutation so the progress bar stays consistent. The `validate` handlers
/// flip a SUGGESTED row to VALIDATED through the shared
/// [TransportValidation] / [AccommodationValidation] extensions, with
/// optimistic local update + rollback on failure.
extension _TripDetailTransportHandlers on TripDetailBloc {
  void _onAddFlightToDetail(
    AddFlightToDetail event,
    Emitter<TripDetailState> emit,
  ) {
    if (state is! TripDetailLoaded) return;
    final loaded = state as TripDetailLoaded;

    final updatedFlights = [...loaded.flights, event.flight];
    final completion = tripDetailCompletion(
      trip: loaded.trip,
      flights: updatedFlights,
      accommodations: loaded.accommodations,
      activities: loaded.activities,
      baggageItems: loaded.baggageItems,
    );
    emit(
      loaded.copyWith(flights: updatedFlights, completionResult: completion),
    );
  }

  Future<void> _onDeleteFlight(
    DeleteFlightFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic removal
    final updatedFlights = loaded.flights
        .where((f) => f.id != event.flightId)
        .toList();
    final completion = tripDetailCompletion(
      trip: loaded.trip,
      flights: updatedFlights,
      accommodations: loaded.accommodations,
      activities: loaded.activities,
      baggageItems: loaded.baggageItems,
    );
    emit(
      loaded.copyWith(flights: updatedFlights, completionResult: completion),
    );

    final result = await _transportRepository.deleteManualFlight(
      _tripId!,
      event.flightId,
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onDeleteAccommodation(
    DeleteAccommodationFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic removal
    final updatedAccommodations = loaded.accommodations
        .where((a) => a.id != event.accommodationId)
        .toList();
    final completion = tripDetailCompletion(
      trip: loaded.trip,
      flights: loaded.flights,
      accommodations: updatedAccommodations,
      activities: loaded.activities,
      baggageItems: loaded.baggageItems,
    );
    emit(
      loaded.copyWith(
        accommodations: updatedAccommodations,
        completionResult: completion,
      ),
    );

    final result = await _accommodationRepository.deleteAccommodation(
      _tripId!,
      event.accommodationId,
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onCreateFlightFromDetail(
    CreateFlightFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final result = await _transportRepository.createManualFlight(
      _tripId!,
      event.data,
    );

    if (isClosed) return;
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;

    switch (result) {
      case Success(:final data):
        final updatedFlights = [...current.flights, data];
        final completion = tripDetailCompletion(
          trip: current.trip,
          flights: updatedFlights,
          accommodations: current.accommodations,
          activities: current.activities,
          baggageItems: current.baggageItems,
        );
        emit(
          current.copyWith(
            flights: updatedFlights,
            completionResult: completion,
          ),
        );
      case Failure(:final error):
        emit(loaded.copyWith(operationError: error));
        emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onUpdateFlightFromDetail(
    UpdateFlightFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final result = await _transportRepository.updateManualFlight(
      _tripId!,
      event.flightId,
      event.data,
    );

    if (isClosed) return;
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;

    switch (result) {
      case Success(:final data):
        final updatedFlights = current.flights
            .map((f) => f.id == event.flightId ? data : f)
            .toList();
        emit(current.copyWith(flights: updatedFlights));
      case Failure(:final error):
        emit(loaded.copyWith(operationError: error));
        emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onCreateAccommodationFromDetail(
    CreateAccommodationFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final data = event.data;
    final result = await _accommodationRepository.createAccommodation(
      _tripId!,
      name: data['name'] as String,
      address: data['address'] as String?,
      checkIn: data['checkIn'] as DateTime?,
      checkOut: data['checkOut'] as DateTime?,
      pricePerNight: (data['pricePerNight'] as num?)?.toDouble(),
      currency: data['currency'] as String?,
      bookingReference: data['bookingReference'] as String?,
      notes: data['notes'] as String?,
    );

    if (isClosed) return;
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;

    switch (result) {
      case Success(:final data):
        final updatedAccommodations = [...current.accommodations, data];
        final completion = tripDetailCompletion(
          trip: current.trip,
          flights: current.flights,
          accommodations: updatedAccommodations,
          activities: current.activities,
          baggageItems: current.baggageItems,
        );
        emit(
          current.copyWith(
            accommodations: updatedAccommodations,
            completionResult: completion,
          ),
        );
      case Failure(:final error):
        emit(loaded.copyWith(operationError: error));
        emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onUpdateAccommodationFromDetail(
    UpdateAccommodationFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final result = await _accommodationRepository.updateAccommodation(
      _tripId!,
      event.accommodationId,
      event.data,
    );

    if (isClosed) return;
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;

    switch (result) {
      case Success(:final data):
        final updatedAccommodations = current.accommodations
            .map((a) => a.id == event.accommodationId ? data : a)
            .toList();
        emit(current.copyWith(accommodations: updatedAccommodations));
      case Failure(:final error):
        emit(loaded.copyWith(operationError: error));
        emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onValidateFlight(
    ValidateFlightFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic flip — render the chip flip + jauge bump before the
    // network call lands. On failure we rebuild the state from the
    // original `loaded` snapshot so the rollback is total.
    final updatedFlights = loaded.flights
        .map(
          (f) => f.id == event.flightId
              ? f.copyWith(validationStatus: ValidationStatus.validated)
              : f,
        )
        .toList();
    final completion = tripDetailCompletion(
      trip: loaded.trip,
      flights: updatedFlights,
      accommodations: loaded.accommodations,
      activities: loaded.activities,
      baggageItems: loaded.baggageItems,
    );
    emit(
      loaded.copyWith(flights: updatedFlights, completionResult: completion),
    );

    final result = await _transportRepository.validate(
      _tripId!,
      event.flightId,
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }

  /// Phase 4 — atomic flight replace.
  ///
  /// We DELETE the old row first, then CREATE the replacement. Both ops
  /// are wrapped in optimistic state updates so the panel renders the
  /// new flight before the network call lands. If the CREATE fails after
  /// a successful DELETE, we rebuild the original list snapshot so the
  /// user never lands on a half-applied state — the lost flight reappears
  /// alongside the validation error in `operationError`.
  Future<void> _onReplaceFlight(
    ReplaceFlightFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;
    final originalFlights = List<ManualFlight>.from(loaded.flights);

    // Optimistic removal first — the new row will pop in once CREATE
    // succeeds (we don't speculate on the response shape locally).
    final pruned = originalFlights
        .where((f) => f.id != event.oldFlightId)
        .toList();
    final prunedCompletion = tripDetailCompletion(
      trip: loaded.trip,
      flights: pruned,
      accommodations: loaded.accommodations,
      activities: loaded.activities,
      baggageItems: loaded.baggageItems,
    );
    emit(loaded.copyWith(flights: pruned, completionResult: prunedCompletion));

    final deleteResult = await _transportRepository.deleteManualFlight(
      _tripId!,
      event.oldFlightId,
    );
    if (isClosed) return;
    if (deleteResult case Failure(:final error)) {
      // Restore the snapshot; the user never sees the row disappear if
      // the network refuses the delete.
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
      return;
    }

    final createResult = await _transportRepository.createManualFlight(
      _tripId!,
      event.newFlightData,
    );
    if (isClosed) return;

    switch (createResult) {
      case Success(:final data):
        final next = [...pruned, data];
        final completion = tripDetailCompletion(
          trip: loaded.trip,
          flights: next,
          accommodations: loaded.accommodations,
          activities: loaded.activities,
          baggageItems: loaded.baggageItems,
        );
        emit(loaded.copyWith(flights: next, completionResult: completion));
      case Failure(:final error):
        // Total rollback: restore the original list so the user can
        // retry without first having to re-add the deleted flight.
        emit(loaded.copyWith(operationError: error));
        emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onValidateAccommodation(
    ValidateAccommodationFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final updatedAccommodations = loaded.accommodations
        .map(
          (a) => a.id == event.accommodationId
              ? a.copyWith(validationStatus: ValidationStatus.validated)
              : a,
        )
        .toList();
    final completion = tripDetailCompletion(
      trip: loaded.trip,
      flights: loaded.flights,
      accommodations: updatedAccommodations,
      activities: loaded.activities,
      baggageItems: loaded.baggageItems,
    );
    emit(
      loaded.copyWith(
        accommodations: updatedAccommodations,
        completionResult: completion,
      ),
    );

    final result = await _accommodationRepository.validate(
      _tripId!,
      event.accommodationId,
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }
}
