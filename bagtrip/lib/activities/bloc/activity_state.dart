part of 'activity_bloc.dart';

sealed class ActivityState {}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivitiesLoaded extends ActivityState {
  final List<Activity> activities;
  final Map<String, List<Activity>> groupedByDay;

  ActivitiesLoaded({required this.activities, required this.groupedByDay});
}

class ActivityError extends ActivityState {
  final String message;

  ActivityError({required this.message});
}
