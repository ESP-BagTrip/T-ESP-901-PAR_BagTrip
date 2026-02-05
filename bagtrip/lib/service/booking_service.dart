import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class BookingService {
  final ApiClient _apiClient;

  BookingService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// List bookings for the authenticated user (GET /v1/booking/list).
  /// Uses the same JWT as ApiClient (Bearer token from StorageService).
  Future<List<BookingResponse>> listBookings() async {
    try {
      final response = await _apiClient.get('/booking/list');

      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>? ?? [];
        return list
            .map((e) => BookingResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to list bookings: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.error?.toString() ?? 'Error listing bookings');
    } catch (e) {
      throw Exception('Error listing bookings: $e');
    }
  }
}
