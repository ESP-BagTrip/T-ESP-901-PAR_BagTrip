part of 'booking_bloc.dart';

sealed class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingLoaded extends BookingState {
  final List<RecentBooking> recentBookings;

  BookingLoaded({required this.recentBookings});
}

class BookingError extends BookingState {
  final AppError error;

  BookingError({required this.error});
}

class PaymentAuthorizing extends BookingState {}

class PaymentSheetReady extends BookingState {
  final String clientSecret;
  final String intentId;

  PaymentSheetReady({required this.clientSecret, required this.intentId});
}

class PaymentSuccess extends BookingState {
  final String intentId;

  PaymentSuccess({required this.intentId});
}

class PaymentCancelled extends BookingState {}

class PaymentFailed extends BookingState {
  final AppError error;

  PaymentFailed({required this.error});
}

/// Refund in flight — replaces the previous PaymentSuccess until completed.
class RefundInProgress extends BookingState {
  final String intentId;
  RefundInProgress({required this.intentId});
}

class RefundSucceeded extends BookingState {
  final String intentId;
  RefundSucceeded({required this.intentId});
}
