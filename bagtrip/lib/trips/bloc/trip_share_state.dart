part of 'trip_share_bloc.dart';

abstract class TripShareState {}

class TripShareInitial extends TripShareState {}

class TripShareLoading extends TripShareState {}

class TripShareLoaded extends TripShareState {
  final List<TripShare> shares;
  TripShareLoaded({required this.shares});
}

class TripShareError extends TripShareState {
  final String message;
  TripShareError({required this.message});
}
