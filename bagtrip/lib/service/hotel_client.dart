import 'package:bagtrip/hotelSearchResult/models/hotel.dart';
import 'package:bagtrip/service/api_client.dart';


class HotelService {
  final ApiClient _apiClient;

  HotelService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  //signature de la méthode
  Future<List<Hotel>> searchHotels({
    required String tripId,
    required String cityCode,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int roomQty,
    String? currency,
  }) async {
    try {
    final response = await _apiClient.post(
      '/v1/trips/$tripId/hotels/searches',
      data: {
        'checkIn': checkIn.toIso8601String().split('T')[0],
        'checkOut': checkOut.toIso8601String().split('T')[0],
        if (currency != null) 'currency': currency,
        'cityCode': cityCode,
        'adults': adults,
        'roomQty': roomQty,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is List) {
        return data.map((json) => Hotel.fromJson(json)).toList();
      } else if (data is Map && data['offers'] is List) {
        return (data['offers'] as List)
            .map((json) => Hotel.fromJson(json))
            .toList();
      }
      return [];
      } else {
        throw Exception('Failed to search hotels: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching hotels: $e');
    }
  }
}