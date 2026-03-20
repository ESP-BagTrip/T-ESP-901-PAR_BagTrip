part of 'trip_detail_bloc.dart';

sealed class TripDetailEvent {}

final class LoadTripDetail extends TripDetailEvent {
  final String tripId;
  LoadTripDetail({required this.tripId});
}

final class RefreshTripDetail extends TripDetailEvent {}

final class SelectDay extends TripDetailEvent {
  final int dayIndex;
  SelectDay({required this.dayIndex});
}

final class ToggleSection extends TripDetailEvent {
  final String sectionId;
  ToggleSection({required this.sectionId});
}

final class ValidateActivity extends TripDetailEvent {
  final String activityId;
  ValidateActivity({required this.activityId});
}

final class RejectActivity extends TripDetailEvent {
  final String activityId;
  RejectActivity({required this.activityId});
}

final class UpdateTripStatus extends TripDetailEvent {
  final String status;
  UpdateTripStatus({required this.status});
}

final class DeleteTripDetail extends TripDetailEvent {}
