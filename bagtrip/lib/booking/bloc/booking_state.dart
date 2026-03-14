part of 'booking_bloc.dart';

sealed class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingLoaded extends BookingState {
  final List<RecentBooking> recentBookings;

  BookingLoaded({required this.recentBookings});
}

class BookingError extends BookingState {
  final String message;

  BookingError({required this.message});
}
