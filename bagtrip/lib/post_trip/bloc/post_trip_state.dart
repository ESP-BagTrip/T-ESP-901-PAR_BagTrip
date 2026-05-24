part of 'post_trip_bloc.dart';

sealed class PostTripState {}

class PostTripInitial extends PostTripState {}

class PostTripLoading extends PostTripState {}

class PostTripLoaded extends PostTripState {
  final Trip trip;
  final int totalDays;
  final int activitiesCompleted;
  final int totalActivities;
  final double budgetSpent;
  final double budgetTotal;
  final String destinationName;
  final Set<ActivityCategory> categoriesExplored;
  final bool hasAiActivities;

  PostTripLoaded({
    required this.trip,
    required this.totalDays,
    required this.activitiesCompleted,
    required this.totalActivities,
    required this.budgetSpent,
    required this.budgetTotal,
    required this.destinationName,
    required this.categoriesExplored,
    required this.hasAiActivities,
  });
}

class PostTripError extends PostTripState {
  final AppError error;
  PostTripError({required this.error});
}
