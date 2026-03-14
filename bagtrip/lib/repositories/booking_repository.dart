import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/booking_response.dart';

abstract class BookingRepository {
  Future<Result<List<BookingResponse>>> listBookings();
}
