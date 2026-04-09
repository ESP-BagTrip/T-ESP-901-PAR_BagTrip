part of 'booking_bloc.dart';

sealed class BookingEvent {}

class LoadBookings extends BookingEvent {}

class CreateBookingIntent extends BookingEvent {
  final String tripId;
  final String flightOfferId;
  CreateBookingIntent({required this.tripId, required this.flightOfferId});
}

class AuthorizePayment extends BookingEvent {
  final String intentId;
  AuthorizePayment({required this.intentId});
}

class PresentPaymentSheet extends BookingEvent {
  final String clientSecret;
  final String intentId;
  PresentPaymentSheet({required this.clientSecret, required this.intentId});
}

class CapturePayment extends BookingEvent {
  final String intentId;
  CapturePayment({required this.intentId});
}
