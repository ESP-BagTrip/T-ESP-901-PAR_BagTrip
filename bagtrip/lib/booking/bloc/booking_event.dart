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

/// Refund a captured booking payment.
///
/// [amount] is in cents — `null` means full refund.
class RefundPayment extends BookingEvent {
  final String intentId;
  final int? amount;
  final RefundReason? reason;
  RefundPayment({required this.intentId, this.amount, this.reason});
}

/// Confirm payment from a 3DS deep-link return.
///
/// Validates that [intentId] matches the in-flight payment so a stale
/// `bagtrip://payment/result?intentId=…` URL can't drive an unrelated
/// booking through capture.
class ConfirmPaymentFromDeepLink extends BookingEvent {
  final String intentId;
  ConfirmPaymentFromDeepLink({required this.intentId});
}
