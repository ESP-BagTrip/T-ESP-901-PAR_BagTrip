part of 'trip_share_bloc.dart';

abstract class TripShareEvent {}

class LoadShares extends TripShareEvent {
  final String tripId;
  LoadShares({required this.tripId});
}

class CreateShare extends TripShareEvent {
  final String tripId;
  final String email;
  final String? message;
  final String role;
  CreateShare({
    required this.tripId,
    required this.email,
    this.message,
    this.role = 'VIEWER',
  });
}

class DeleteShare extends TripShareEvent {
  final String tripId;
  final String shareId;
  DeleteShare({required this.tripId, required this.shareId});
}
