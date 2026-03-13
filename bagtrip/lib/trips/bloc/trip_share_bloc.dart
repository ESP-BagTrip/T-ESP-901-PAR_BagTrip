import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/service/trip_share_service.dart';
import 'package:bloc/bloc.dart';

part 'trip_share_event.dart';
part 'trip_share_state.dart';

class TripShareBloc extends Bloc<TripShareEvent, TripShareState> {
  TripShareBloc({TripShareService? tripShareService})
    : _tripShareService = tripShareService ?? TripShareService(),
      super(TripShareInitial()) {
    on<LoadShares>(_onLoadShares);
    on<CreateShare>(_onCreateShare);
    on<DeleteShare>(_onDeleteShare);
  }

  final TripShareService _tripShareService;

  Future<void> _onLoadShares(
    LoadShares event,
    Emitter<TripShareState> emit,
  ) async {
    emit(TripShareLoading());
    try {
      final shares = await _tripShareService.getSharesByTrip(event.tripId);
      emit(TripShareLoaded(shares: shares));
    } catch (e) {
      emit(TripShareError(message: e.toString()));
    }
  }

  Future<void> _onCreateShare(
    CreateShare event,
    Emitter<TripShareState> emit,
  ) async {
    emit(TripShareLoading());
    try {
      await _tripShareService.createShare(event.tripId, email: event.email);
      add(LoadShares(tripId: event.tripId));
    } catch (e) {
      if (e.toString().contains('SHARE_QUOTA_EXCEEDED')) {
        emit(TripShareQuotaExceeded());
      } else {
        emit(TripShareError(message: e.toString()));
      }
    }
  }

  Future<void> _onDeleteShare(
    DeleteShare event,
    Emitter<TripShareState> emit,
  ) async {
    emit(TripShareLoading());
    try {
      await _tripShareService.deleteShare(event.tripId, event.shareId);
      add(LoadShares(tripId: event.tripId));
    } catch (e) {
      emit(TripShareError(message: e.toString()));
    }
  }
}
