import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/repositories/booking_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class BookingRepositoryImpl implements BookingRepository {
  final ApiClient _apiClient;

  BookingRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<List<BookingResponse>>> listBookings() async {
    try {
      final response = await _apiClient.get('/booking/list');
      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>? ?? [];
        return Success(
          list
              .map((e) => BookingResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      return Failure(
        UnknownError('list bookings failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }
}
