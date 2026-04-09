import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/models/payment_authorize_response.dart';

abstract class BookingRepository {
  Future<Result<List<BookingResponse>>> listBookings();
  Future<Result<String>> createBookingIntent({
    required String tripId,
    required String flightOfferId,
  });
  Future<Result<PaymentAuthorizeResponse>> authorizePayment(String intentId);
  Future<Result<void>> capturePayment(String intentId);
  Future<Result<void>> cancelPayment(String intentId);
}
