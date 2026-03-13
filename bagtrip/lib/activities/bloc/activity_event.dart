part of 'activity_bloc.dart';

sealed class ActivityEvent {}

class LoadActivities extends ActivityEvent {
  final String tripId;

  LoadActivities({required this.tripId});
}

class CreateActivity extends ActivityEvent {
  final String tripId;
  final Map<String, dynamic> data;

  CreateActivity({required this.tripId, required this.data});
}

class UpdateActivity extends ActivityEvent {
  final String tripId;
  final String activityId;
  final Map<String, dynamic> data;

  UpdateActivity({
    required this.tripId,
    required this.activityId,
    required this.data,
  });
}

class DeleteActivity extends ActivityEvent {
  final String tripId;
  final String activityId;

  DeleteActivity({required this.tripId, required this.activityId});
}
