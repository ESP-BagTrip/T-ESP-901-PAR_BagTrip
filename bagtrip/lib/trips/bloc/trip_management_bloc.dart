import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_grouped.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:bagtrip/service/trip_service.dart';
import 'package:bloc/bloc.dart';

part 'trip_management_event.dart';
part 'trip_management_state.dart';

class TripManagementBloc
    extends Bloc<TripManagementEvent, TripManagementState> {
  TripManagementBloc({TripService? tripService})
    : _tripService = tripService ?? TripService(),
      super(TripManagementInitial()) {
    on<LoadTrips>(_onLoadTrips);
    on<CreateTrip>(_onCreateTrip);
    on<LoadTripHome>(_onLoadTripHome);
    on<UpdateTripStatus>(_onUpdateTripStatus);
  }

  final TripService _tripService;

  Future<void> _onLoadTrips(
    LoadTrips event,
    Emitter<TripManagementState> emit,
  ) async {
    emit(TripManagementLoading());
    try {
      final grouped = await _tripService.getGroupedTrips();
      emit(TripManagementLoaded(groupedTrips: grouped));
    } catch (e) {
      emit(TripManagementError(message: e.toString()));
    }
  }

  Future<void> _onCreateTrip(
    CreateTrip event,
    Emitter<TripManagementState> emit,
  ) async {
    emit(TripManagementLoading());
    try {
      final trip = await _tripService.createTrip(
        title: event.title,
        description: event.description,
        destinationName: event.destinationName,
        nbTravelers: event.nbTravelers,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(TripCreated(trip: trip));
    } catch (e) {
      emit(TripManagementError(message: e.toString()));
    }
  }

  Future<void> _onLoadTripHome(
    LoadTripHome event,
    Emitter<TripManagementState> emit,
  ) async {
    emit(TripHomeLoading());
    try {
      final tripHome = await _tripService.getTripHome(event.tripId);
      emit(TripHomeLoaded(tripHome: tripHome));
    } catch (e) {
      emit(TripManagementError(message: e.toString()));
    }
  }

  Future<void> _onUpdateTripStatus(
    UpdateTripStatus event,
    Emitter<TripManagementState> emit,
  ) async {
    try {
      await _tripService.updateTripStatus(event.tripId, event.status);
      add(LoadTrips());
    } catch (e) {
      emit(TripManagementError(message: e.toString()));
    }
  }
}
