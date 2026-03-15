part of 'activity_bloc.dart';

sealed class ActivityState {}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivitiesLoaded extends ActivityState {
  final List<Activity> activities;
  final Map<String, List<Activity>> groupedByDay;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  bool get hasMore => currentPage < totalPages;

  ActivitiesLoaded({
    required this.activities,
    required this.groupedByDay,
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
  });
}

class ActivityError extends ActivityState {
  final AppError error;

  ActivityError({required this.error});
}

class ActivitySuggestionsLoading extends ActivityState {}

class ActivityQuotaExceeded extends ActivityState {}

class ActivitySuggestionsLoaded extends ActivityState {
  final List<Map<String, dynamic>> suggestions;
  final List<Activity> activities;
  final Map<String, List<Activity>> groupedByDay;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  bool get hasMore => currentPage < totalPages;

  ActivitySuggestionsLoaded({
    required this.suggestions,
    required this.activities,
    required this.groupedByDay,
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
  });
}
