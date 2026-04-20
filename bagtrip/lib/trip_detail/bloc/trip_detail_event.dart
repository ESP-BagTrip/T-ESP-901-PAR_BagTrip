part of 'trip_detail_bloc.dart';

sealed class TripDetailEvent {}

final class LoadTripDetail extends TripDetailEvent {
  final String tripId;
  LoadTripDetail({required this.tripId});
}

final class RefreshTripDetail extends TripDetailEvent {}

final class LoadDeferredSections extends TripDetailEvent {}

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

final class CreateBudgetItemFromDetail extends TripDetailEvent {
  final Map<String, dynamic> data;
  CreateBudgetItemFromDetail({required this.data});
}

final class UpdateBudgetItemFromDetail extends TripDetailEvent {
  final String itemId;
  final Map<String, dynamic> data;
  UpdateBudgetItemFromDetail({required this.itemId, required this.data});
}

final class DeleteBudgetItemFromDetail extends TripDetailEvent {
  final String itemId;
  DeleteBudgetItemFromDetail({required this.itemId});
}

final class RefreshBudgetSummaryFromDetail extends TripDetailEvent {}

final class CreateFlightFromDetail extends TripDetailEvent {
  final Map<String, dynamic> data;
  CreateFlightFromDetail({required this.data});
}

final class UpdateFlightFromDetail extends TripDetailEvent {
  final String flightId;
  final Map<String, dynamic> data;
  UpdateFlightFromDetail({required this.flightId, required this.data});
}

final class CreateAccommodationFromDetail extends TripDetailEvent {
  final Map<String, dynamic> data;
  CreateAccommodationFromDetail({required this.data});
}

final class UpdateAccommodationFromDetail extends TripDetailEvent {
  final String accommodationId;
  final Map<String, dynamic> data;
  UpdateAccommodationFromDetail({
    required this.accommodationId,
    required this.data,
  });
}

final class CreateBaggageItemFromDetail extends TripDetailEvent {
  final Map<String, dynamic> data;
  CreateBaggageItemFromDetail({required this.data});
}

final class UpdateBaggageItemFromDetail extends TripDetailEvent {
  final String baggageItemId;
  final Map<String, dynamic> data;
  UpdateBaggageItemFromDetail({
    required this.baggageItemId,
    required this.data,
  });
}

final class CreateShareFromDetail extends TripDetailEvent {
  final String email;
  final String role;
  final String? message;
  CreateShareFromDetail({
    required this.email,
    required this.role,
    this.message,
  });
}

final class RetryDeferredSection extends TripDetailEvent {
  final String section;
  RetryDeferredSection({required this.section});
}
