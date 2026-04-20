part of 'trip_detail_bloc.dart';

/// Handlers for trip-level metadata mutations (status, title, dates,
/// travelers, delete). Extracted from the main bloc file for navigability;
/// they stay in the same library so they can access the bloc's private
/// fields and keep a single source of truth for the shared state.
extension _TripDetailTripHandlers on TripDetailBloc {
  Future<void> _onUpdateTripStatus(
    UpdateTripStatus event,
    Emitter<TripDetailState> emit,
  ) async {
    if (_tripId == null) return;

    // Validate DRAFT → PLANNED transition
    if (event.status == 'PLANNED' && state is TripDetailLoaded) {
      final loaded = state as TripDetailLoaded;
      final trip = loaded.trip;
      final hasDestination =
          trip.destinationName != null && trip.destinationName!.isNotEmpty;
      final hasDates = trip.startDate != null && trip.endDate != null;

      if (!hasDestination || !hasDates) {
        emit(loaded.copyWith(validationError: 'finalize_conditions_not_met'));
        emit(loaded.copyWith(clearValidationError: true));
        return;
      }
    }

    final result = await _tripRepository.updateTripStatus(
      _tripId!,
      event.status,
    );

    if (isClosed) return;

    if (result is Success) {
      add(RefreshTripDetail());
    }
  }

  Future<void> _onUpdateTripTitle(
    UpdateTripTitle event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic update
    final updatedTrip = loaded.trip.copyWith(title: event.title);
    emit(loaded.copyWith(trip: updatedTrip));

    final result = await _tripRepository.updateTrip(_tripId!, {
      'title': event.title,
    });

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onUpdateTripDates(
    UpdateTripDates event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic update
    final updatedTrip = loaded.trip.copyWith(
      startDate: event.startDate,
      endDate: event.endDate,
    );
    final completion = tripDetailCompletion(
      trip: updatedTrip,
      flights: loaded.flights,
      accommodations: loaded.accommodations,
      activities: loaded.activities,
      baggageItems: loaded.baggageItems,
    );
    emit(loaded.copyWith(trip: updatedTrip, completionResult: completion));

    final result = await _tripRepository.updateTrip(_tripId!, {
      'startDate': event.startDate.toIso8601String(),
      'endDate': event.endDate.toIso8601String(),
    });

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }

  Future<void> _onUpdateTripTravelers(
    UpdateTripTravelers event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic update
    final updatedTrip = loaded.trip.copyWith(nbTravelers: event.nbTravelers);
    emit(loaded.copyWith(trip: updatedTrip));

    final result = await _tripRepository.updateTrip(_tripId!, {
      'nbTravelers': event.nbTravelers,
    });

    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    } else {
      add(RefreshTripDetail());
    }
  }

  Future<void> _onDeleteTrip(
    DeleteTripDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (_tripId == null) return;

    final result = await _tripRepository.deleteTrip(_tripId!);

    if (isClosed) return;

    if (result is Success) {
      emit(TripDetailDeleted());
    }
  }

  Future<void> _onUpdateTripTracking(
    UpdateTripTrackingFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final updatedTrip = loaded.trip.copyWith(
      flightsTracking: event.flightsTracking ?? loaded.trip.flightsTracking,
      accommodationsTracking:
          event.accommodationsTracking ?? loaded.trip.accommodationsTracking,
    );
    final completion = tripDetailCompletion(
      trip: updatedTrip,
      flights: loaded.flights,
      accommodations: loaded.accommodations,
      activities: loaded.activities,
      baggageItems: loaded.baggageItems,
    );
    emit(loaded.copyWith(trip: updatedTrip, completionResult: completion));

    final result = await _tripRepository.updateTripTracking(
      _tripId!,
      flightsTracking: event.flightsTracking,
      accommodationsTracking: event.accommodationsTracking,
    );

    if (isClosed) return;

    if (result case Failure(:final error)) {
      // Rollback to the previous trip + completion on failure.
      emit(loaded.copyWith(operationError: error));
      emit(loaded.copyWith(clearOperationError: true));
    }
  }
}
