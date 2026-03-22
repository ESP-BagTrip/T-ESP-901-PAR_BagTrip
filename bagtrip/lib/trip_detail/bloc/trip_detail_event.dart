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

final class DeleteFlightFromDetail extends TripDetailEvent {
  final String flightId;
  DeleteFlightFromDetail({required this.flightId});
}

final class DeleteAccommodationFromDetail extends TripDetailEvent {
  final String accommodationId;
  DeleteAccommodationFromDetail({required this.accommodationId});
}

final class ToggleBaggagePackedFromDetail extends TripDetailEvent {
  final String baggageItemId;
  ToggleBaggagePackedFromDetail({required this.baggageItemId});
}

final class DeleteBaggageItemFromDetail extends TripDetailEvent {
  final String baggageItemId;
  DeleteBaggageItemFromDetail({required this.baggageItemId});
}

final class DeleteShareFromDetail extends TripDetailEvent {
  final String shareId;
  DeleteShareFromDetail({required this.shareId});
}

final class UpdateTripTitle extends TripDetailEvent {
  final String title;
  UpdateTripTitle({required this.title});
}

final class UpdateTripDates extends TripDetailEvent {
  final DateTime startDate;
  final DateTime endDate;
  UpdateTripDates({required this.startDate, required this.endDate});
}

final class UpdateTripTravelers extends TripDetailEvent {
  final int nbTravelers;
  UpdateTripTravelers({required this.nbTravelers});
}

final class AddFlightToDetail extends TripDetailEvent {
  final ManualFlight flight;
  AddFlightToDetail({required this.flight});
}

final class BatchValidateActivitiesFromDetail extends TripDetailEvent {
  final List<String> activityIds;
  BatchValidateActivitiesFromDetail({required this.activityIds});
}

final class UpdateActivityFromDetail extends TripDetailEvent {
  final String activityId;
  final Map<String, dynamic> data;
  UpdateActivityFromDetail({required this.activityId, required this.data});
}

final class MoveActivityToDay extends TripDetailEvent {
  final String activityId;
  final int targetDayIndex; // 0-based
  MoveActivityToDay({required this.activityId, required this.targetDayIndex});
}

final class SuggestActivitiesForDay extends TripDetailEvent {
  final int dayNumber; // 1-based
  SuggestActivitiesForDay({required this.dayNumber});
}

final class ClearDaySuggestions extends TripDetailEvent {}

final class CreateActivityFromDetail extends TripDetailEvent {
  final Map<String, dynamic> data;
  CreateActivityFromDetail({required this.data});
}
