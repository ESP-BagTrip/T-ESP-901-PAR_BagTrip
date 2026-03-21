part of 'home_bloc.dart';

sealed class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeError extends HomeState {
  final AppError error;
  HomeError({required this.error});
}

// ---------------------------------------------------------------------------
// 3 contextual loaded states
// ---------------------------------------------------------------------------

class HomeNewUser extends HomeState {
  final User user;

  HomeNewUser({required this.user});

  String get displayName {
    final full = user.fullName ?? '';
    if (full.isEmpty) return '';
    return full.split(' ').first;
  }
}

class HomeActiveTrip extends HomeState {
  final User user;
  final Trip activeTrip;
  final List<Activity> todayActivities;
  final String? weatherSummary;
  final List<Activity> allActivities;
  final Trip? pendingCompletionTrip;
  final String? completedTripId;

  HomeActiveTrip({
    required this.user,
    required this.activeTrip,
    this.todayActivities = const [],
    this.weatherSummary,
    this.allActivities = const [],
    this.pendingCompletionTrip,
    this.completedTripId,
  });

  String get displayName {
    final full = user.fullName ?? '';
    if (full.isEmpty) return '';
    return full.split(' ').first;
  }

  int get currentDay {
    final start = activeTrip.startDate;
    if (start == null) return 1;
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(start.year, start.month, start.day)).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  int get totalDays {
    final start = activeTrip.startDate;
    final end = activeTrip.endDate;
    if (start == null || end == null) return 1;
    final diff = DateTime(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime(start.year, start.month, start.day)).inDays;
    return diff < 1 ? 1 : diff + 1;
  }
}

class HomeTripManager extends HomeState {
  final User user;
  final Trip? nextTrip;
  final int nextTripCompletion;
  final List<Trip> upcomingTrips;
  final List<Trip> completedTrips;

  HomeTripManager({
    required this.user,
    this.nextTrip,
    this.nextTripCompletion = 0,
    this.upcomingTrips = const [],
    this.completedTrips = const [],
  });

  String get displayName {
    final full = user.fullName ?? '';
    if (full.isEmpty) return '';
    return full.split(' ').first;
  }

  bool get hasNextTrip => nextTrip != null;

  int? get daysUntilNextTrip {
    if (nextTrip?.startDate == null) return null;
    final days = nextTrip!.startDate!.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }
}
