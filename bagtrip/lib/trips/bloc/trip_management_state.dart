part of 'trip_management_bloc.dart';

sealed class TripManagementState {}

class TripManagementInitial extends TripManagementState {}

class TripsLoading extends TripManagementState {}

class TripCreating extends TripManagementState {}

class TripDeleting extends TripManagementState {}

class TripsLoaded extends TripManagementState {
  final TripGrouped groupedTrips;

  TripsLoaded({required this.groupedTrips});
}

class TripError extends TripManagementState {
  final AppError error;

  TripError({required this.error});
}

class TripHomeLoading extends TripManagementState {}

class TripHomeLoaded extends TripManagementState {
  final TripHome tripHome;

  TripHomeLoaded({required this.tripHome});
}

class TripCreated extends TripManagementState {
  final Trip trip;

  TripCreated({required this.trip});
}

class TripDeleted extends TripManagementState {}
