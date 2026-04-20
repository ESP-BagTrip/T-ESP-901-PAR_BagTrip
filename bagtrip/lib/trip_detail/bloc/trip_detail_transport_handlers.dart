part of 'trip_detail_bloc.dart';

/// Handlers for flights and accommodations (add / delete). Both share the
/// pattern of recomputing `completionResult` after the list mutation so the
/// progress bar stays consistent.
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
}
