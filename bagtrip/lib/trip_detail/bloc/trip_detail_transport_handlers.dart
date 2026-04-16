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
}
