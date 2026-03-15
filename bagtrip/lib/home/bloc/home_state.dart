part of 'home_bloc.dart';

sealed class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final User? user;
  final Trip? nextTrip;
  final int? daysUntilNextTrip;
  final int totalTrips;

  HomeLoaded({
    this.user,
    this.nextTrip,
    this.daysUntilNextTrip,
    this.totalTrips = 0,
  });

  bool get isNewUser => totalTrips == 0;
  bool get hasNextTrip => nextTrip != null;

  String get displayName {
    final full = user?.fullName ?? '';
    if (full.isEmpty) return '';
    return full.split(' ').first;
  }
}
