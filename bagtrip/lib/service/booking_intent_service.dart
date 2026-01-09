import 'package:bagtrip/models/booking_intent.dart';
import 'package:bagtrip/service/api_client.dart';

class BookingIntentService {
  final ApiClient _apiClient;

  BookingIntentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Create a booking intent for a selected offer
  /// POST /v1/trips/{tripId}/booking-intents
  Future<BookingIntent> createBookingIntent(
    String tripId, {
    required BookingIntentType type,
    String? flightOfferId,
    String? hotelOfferId,
  }) async {
    try {
      final data = <String, dynamic>{'type': type.value};

      if (type == BookingIntentType.flight && flightOfferId != null) {
        data['flightOfferId'] = flightOfferId;
      } else if (type == BookingIntentType.hotel && hotelOfferId != null) {
        data['hotelOfferId'] = hotelOfferId;
      }

      final response = await _apiClient.post(
        '/trips/$tripId/booking-intents',
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return BookingIntent.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to create booking intent: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error creating booking intent: $e');
    }
  }

  /// Get a booking intent by ID
  /// GET /v1/booking-intents/{intentId}
  Future<BookingIntent> getBookingIntent(String intentId) async {
    try {
      final response = await _apiClient.get('/booking-intents/$intentId');

      if (response.statusCode == 200) {
        return BookingIntent.fromJson(response.data);
      } else {
        throw Exception('Failed to get booking intent: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting booking intent: $e');
    }
  }

  /// Book a flight through Amadeus
  /// POST /v1/booking-intents/{intentId}/book
  Future<Map<String, dynamic>> bookFlight(
    String intentId, {
    required List<String> travelerIds,
    required List<Map<String, dynamic>> contacts,
  }) async {
    try {
      final data = {'travelerIds': travelerIds, 'contacts': contacts};

      final response = await _apiClient.post(
        '/booking-intents/$intentId/book',
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to book flight: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error booking flight: $e');
    }
  }
}
