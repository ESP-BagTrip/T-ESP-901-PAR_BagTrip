part of 'trip_management_bloc.dart';

sealed class TripManagementState {}

class TripManagementInitial extends TripManagementState {}

class TripManagementLoading extends TripManagementState {}

class TripManagementLoaded extends TripManagementState {
  final TripGrouped groupedTrips;

  TripManagementLoaded({required this.groupedTrips});
}

class TripManagementError extends TripManagementState {
  final String message;

  TripManagementError({required this.message});
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
