part of 'home_bloc.dart';

sealed class HomeEvent {}

class LoadHome extends HomeEvent {}

class RefreshHome extends HomeEvent {}

class ResetHome extends HomeEvent {}

class ConfirmTripCompletion extends HomeEvent {
  final String tripId;
  ConfirmTripCompletion({required this.tripId});
}

class DismissTripCompletion extends HomeEvent {
  final String tripId;
  DismissTripCompletion({required this.tripId});
}

class _ConnectivityRestored extends HomeEvent {}
