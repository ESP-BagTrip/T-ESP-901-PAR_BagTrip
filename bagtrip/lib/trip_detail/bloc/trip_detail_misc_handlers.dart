part of 'trip_detail_bloc.dart';

/// Handlers for share invites (create + delete). Kept in a dedicated file so
/// the baggage and budget concerns live next to their siblings rather than
/// lumped together in a catch-all bucket.
extension _TripDetailMiscHandlers on TripDetailBloc {
  Future<void> _onCreateShareFromDetail(
    CreateShareFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    final result = await _tripShareRepository.createShare(
      _tripId!,
      email: event.email,
      role: event.role,
      message: event.message,
    );

    if (isClosed) return;
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;

    switch (result) {
      case Success(:final data):
        emit(current.copyWith(shares: [...current.shares, data]));
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
