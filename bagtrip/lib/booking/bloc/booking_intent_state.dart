part of 'booking_intent_bloc.dart';

sealed class BookingIntentState extends Equatable {
  const BookingIntentState();

  @override
  List<Object?> get props => [];
}

final class BookingIntentInitial extends BookingIntentState {}

final class BookingIntentLoading extends BookingIntentState {}

final class BookingIntentCreated extends BookingIntentState {
  final BookingIntent bookingIntent;

  const BookingIntentCreated({required this.bookingIntent});

  @override
  List<Object?> get props => [bookingIntent];
}

final class BookingIntentError extends BookingIntentState {
  final String message;

  const BookingIntentError(this.message);

  @override
  List<Object?> get props => [message];
}
