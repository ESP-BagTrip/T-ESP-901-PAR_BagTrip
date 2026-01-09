import 'package:bagtrip/models/flight_search_response.dart';
import 'package:bagtrip/service/api_client.dart';

class FlightSearchService {
  final ApiClient _apiClient;

  FlightSearchService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Search flights for a trip (trip-based search)
  /// POST /v1/trips/{tripId}/flights/searches
  Future<FlightSearchResponse> searchFlights(
    String tripId, {
    required String originIata,
    required String destinationIata,
    required String departureDate,
    String? returnDate,
    required int adults,
    int children = 0,
    int infants = 0,
    String travelClass = 'ECONOMY',
    String currency = 'EUR',
    bool nonStop = false,
  }) async {
    try {
      final data = {
        'originIata': originIata,
        'destinationIata': destinationIata,
        'departureDate': departureDate,
        'adults': adults,
        'children': children,
        'infants': infants,
        'travelClass': travelClass,
        'currency': currency,
        'nonStop': nonStop,
      };

      if (returnDate != null) {
        data['returnDate'] = returnDate;
      }

      final response = await _apiClient.post(
        '/trips/$tripId/flights/searches',
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return FlightSearchResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to search flights: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching flights: $e');
    }
  }

  /// Get full flight offer details
  /// GET /v1/trips/{tripId}/flights/offers/{offerId}
  Future<Map<String, dynamic>> getFlightOffer(
    String tripId,
    String offerId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/trips/$tripId/flights/offers/$offerId',
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get flight offer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting flight offer: $e');
    }
  }
}
