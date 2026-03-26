part of 'trip_management_bloc.dart';

sealed class TripManagementEvent {}

class LoadTrips extends TripManagementEvent {}

class LoadTripsByStatus extends TripManagementEvent {
  final String status;
  final int page;
  LoadTripsByStatus({required this.status, this.page = 1});
}

class LoadMoreTripsByStatus extends TripManagementEvent {
  final String status;
  LoadMoreTripsByStatus({required this.status});
}

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

class DeleteTrip extends TripManagementEvent {
  final String tripId;

  DeleteTrip({required this.tripId});
}
