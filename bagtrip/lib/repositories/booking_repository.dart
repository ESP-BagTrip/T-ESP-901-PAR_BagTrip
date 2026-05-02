import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/models/payment_authorize_response.dart';

/// Stripe-allowed refund reasons. Match the backend `RefundReason` literal.
enum RefundReason {
  duplicate,
  fraudulent,
  requestedByCustomer;

  String get apiValue => switch (this) {
    RefundReason.duplicate => 'duplicate',
    RefundReason.fraudulent => 'fraudulent',
    RefundReason.requestedByCustomer => 'requested_by_customer',
  };
}

abstract class BookingRepository {
  Future<Result<List<BookingResponse>>> listBookings();
  Future<Result<String>> createBookingIntent({
    required String tripId,
    required String flightOfferId,
  });
  Future<Result<PaymentAuthorizeResponse>> authorizePayment(String intentId);
  Future<Result<void>> capturePayment(String intentId);
  Future<Result<void>> cancelPayment(String intentId);

  /// Refund a captured payment.
  ///
  /// [amount] is in cents (smallest currency unit). When `null`, performs
  /// a full refund. The backend validates against
  /// `Charge.amount_captured - amount_refunded` and rejects over-refunds
  /// with `REFUND_AMOUNT_EXCEEDS_REMAINING`.
  Future<Result<void>> refundPayment(
    String intentId, {
    int? amount,
    RefundReason? reason,
  });
}
