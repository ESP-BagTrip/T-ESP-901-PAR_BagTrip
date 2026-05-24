part of 'post_trip_bloc.dart';

sealed class PostTripEvent {}

class LoadPostTripStats extends PostTripEvent {
  final String tripId;
  LoadPostTripStats({required this.tripId});
}
