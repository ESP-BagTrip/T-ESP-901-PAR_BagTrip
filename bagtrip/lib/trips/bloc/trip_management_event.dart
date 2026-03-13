part of 'trip_management_bloc.dart';

sealed class TripManagementEvent {}

class LoadTrips extends TripManagementEvent {}

class CreateTrip extends TripManagementEvent {
  final String title;
  final String? description;
  final String? destinationName;
  final int? nbTravelers;
  final DateTime? startDate;
  final DateTime? endDate;

  CreateTrip({
    required this.title,
    this.description,
    this.destinationName,
    this.nbTravelers,
    this.startDate,
    this.endDate,
  });
}

class LoadTripHome extends TripManagementEvent {
  final String tripId;

  LoadTripHome({required this.tripId});
}

class UpdateTripStatus extends TripManagementEvent {
  final String tripId;
  final String status;

  UpdateTripStatus({required this.tripId, required this.status});
}
