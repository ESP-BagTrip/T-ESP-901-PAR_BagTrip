import 'package:dio/dio.dart';

class FlightOfferPriceService {
  final Dio _dio = Dio();
  // Using localhost for now as per other services.
  // In production this should be the actual backend URL.
  final String baseUrl = 'http://localhost:3000/v1';

  /// Confirms the flight price using the backend proxy which calls
  /// https://test.api.amadeus.com/v1/shopping/flight-offers/pricing
  Future<Map<String, dynamic>> confirmPrice(
    Map<String, dynamic> flightOfferJson,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/shopping/flight-offers/pricing',
        data: {
          'data': {
            'type': 'flight-offers-pricing',
            'flightOffers': [flightOfferJson],
          },
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to confirm price: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error confirming price: $e');
    }
  }
}
