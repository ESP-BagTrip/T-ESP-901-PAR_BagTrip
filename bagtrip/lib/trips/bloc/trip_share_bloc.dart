import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/trip_share_repository.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:bloc/bloc.dart';

part 'trip_share_event.dart';
part 'trip_share_state.dart';

class TripShareBloc extends Bloc<TripShareEvent, TripShareState> {
  TripShareBloc({TripShareRepository? tripShareRepository})
    : _tripShareRepository =
          tripShareRepository ?? getIt<TripShareRepository>(),
      super(TripShareInitial()) {
    on<LoadShares>(_onLoadShares);
    on<CreateShare>(_onCreateShare);
    on<DeleteShare>(_onDeleteShare);
  }

  final TripShareRepository _tripShareRepository;

  Future<void> _onLoadShares(
    LoadShares event,
    Emitter<TripShareState> emit,
  ) async {
    emit(TripShareLoading());
    final result = await _tripShareRepository.getSharesByTrip(event.tripId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(TripShareLoaded(shares: data));
      case Failure(:final error):
        emit(TripShareError(message: toUserFriendlyMessage(error)));
    }
  }

  Future<void> _onCreateShare(
    CreateShare event,
    Emitter<TripShareState> emit,
  ) async {
    emit(TripShareLoading());
    final result = await _tripShareRepository.createShare(
      event.tripId,
      email: event.email,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadShares(tripId: event.tripId));
      case Failure(:final error):
        if (error is QuotaExceededError) {
          emit(TripShareQuotaExceeded());
        } else {
          emit(TripShareError(message: toUserFriendlyMessage(error)));
        }
    }
  }

  Future<void> _onDeleteShare(
    DeleteShare event,
    Emitter<TripShareState> emit,
  ) async {
    emit(TripShareLoading());
    final result = await _tripShareRepository.deleteShare(
      event.tripId,
      event.shareId,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadShares(tripId: event.tripId));
      case Failure(:final error):
        emit(TripShareError(message: toUserFriendlyMessage(error)));
    }
  }
}
