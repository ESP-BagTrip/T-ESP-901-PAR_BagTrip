part of 'home_bloc.dart';

sealed class HomeEvent {}

class LoadHome extends HomeEvent {}

class RefreshHome extends HomeEvent {}

/// Reloads activities for the current [HomeActiveTrip] (e.g. after editing
/// schedule from trip detail while programme is still on the nav stack).
class RefreshActiveTripActivities extends HomeEvent {}

/// Pushes the in-memory activity list from [TripDetailBloc] into home state
/// before popping back to programme (avoids stale /home aggregate).
class SyncActiveTripActivities extends HomeEvent {
  final List<Activity> activities;
  SyncActiveTripActivities(this.activities);
}

class ResetHome extends HomeEvent {}

class ConfirmTripCompletion extends HomeEvent {
  final String tripId;
  ConfirmTripCompletion({required this.tripId});
}

class DismissTripCompletion extends HomeEvent {
  final String tripId;
  DismissTripCompletion({required this.tripId});
}

class PreferIdleHomeOverview extends HomeEvent {}

class ResumeActiveTripHome extends HomeEvent {}

class CompleteActiveTrip extends HomeEvent {}

/// Optimistically removes a planned trip from home lists after swipe-to-delete.
class RemoveUpcomingTrip extends HomeEvent {
  final String tripId;
  RemoveUpcomingTrip({required this.tripId});
}
