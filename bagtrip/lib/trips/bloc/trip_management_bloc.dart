import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_grouped.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bloc/bloc.dart';

part 'trip_management_event.dart';
part 'trip_management_state.dart';

class TripManagementBloc
    extends Bloc<TripManagementEvent, TripManagementState> {
  TripManagementBloc({TripRepository? tripRepository})
    : _tripRepository = tripRepository ?? getIt<TripRepository>(),
      super(TripManagementInitial()) {
    on<LoadTrips>(_onLoadTrips);
    on<CreateTrip>(_onCreateTrip);
    on<LoadTripHome>(_onLoadTripHome);
    on<UpdateTripStatus>(_onUpdateTripStatus);
    on<DeleteTrip>(_onDeleteTrip);
  }

  final TripRepository _tripRepository;

  Future<void> _onLoadTrips(
    LoadTrips event,
    Emitter<TripManagementState> emit,
  ) async {
    emit(TripsLoading());
    final result = await _tripRepository.getGroupedTrips();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(TripsLoaded(groupedTrips: data));
      case Failure(:final error):
        emit(TripError(error: error));
    }
  }

  Future<void> _onCreateTrip(
    CreateTrip event,
    Emitter<TripManagementState> emit,
  ) async {
    emit(TripCreating());
    final result = await _tripRepository.createTrip(
      title: event.title,
      description: event.description,
      destinationName: event.destinationName,
      nbTravelers: event.nbTravelers,
      startDate: event.startDate,
      endDate: event.endDate,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(TripCreated(trip: data));
      case Failure(:final error):
        emit(TripError(error: error));
    }
  }

  Future<void> _onLoadTripHome(
    LoadTripHome event,
    Emitter<TripManagementState> emit,
  ) async {
    emit(TripHomeLoading());
    final result = await _tripRepository.getTripHome(event.tripId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(TripHomeLoaded(tripHome: data));
      case Failure(:final error):
        emit(TripError(error: error));
    }
  }

  Future<void> _onUpdateTripStatus(
    UpdateTripStatus event,
    Emitter<TripManagementState> emit,
  ) async {
    final result = await _tripRepository.updateTripStatus(
      event.tripId,
      event.status,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadTripHome(tripId: event.tripId));
      case Failure(:final error):
        emit(TripError(error: error));
    }
  }

  Future<void> _onDeleteTrip(
    DeleteTrip event,
    Emitter<TripManagementState> emit,
  ) async {
    emit(TripDeleting());
    final result = await _tripRepository.deleteTrip(event.tripId);
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(TripDeleted());
        add(LoadTrips());
      case Failure(:final error):
        emit(TripError(error: error));
    }
  }
}
