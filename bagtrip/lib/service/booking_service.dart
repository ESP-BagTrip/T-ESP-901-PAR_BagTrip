import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/models/payment_authorize_response.dart';
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
      return loggedFailure(
        UnknownError('list bookings failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<String>> createBookingIntent({
    required String tripId,
    required String flightOfferId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/booking-intents',
        data: {'type': 'FLIGHT', 'flightOfferId': flightOfferId},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final id = response.data['id'] as String;
        return Success(id);
      }
      return loggedFailure(
        UnknownError('create booking intent failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<PaymentAuthorizeResponse>> authorizePayment(
    String intentId,
  ) async {
    try {
      final response = await _apiClient.post(
        '/booking-intents/$intentId/payment/authorize',
      );
      if (response.statusCode == 200) {
        return Success(
          PaymentAuthorizeResponse.fromJson(
            response.data as Map<String, dynamic>,
          ),
        );
      }
      return loggedFailure(
        UnknownError('authorize payment failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> capturePayment(String intentId) async {
    try {
      final response = await _apiClient.post(
        '/booking-intents/$intentId/payment/capture',
      );
      if (response.statusCode == 200) {
        return const Success(null);
      }
      return loggedFailure(
        UnknownError('capture payment failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> cancelPayment(String intentId) async {
    try {
      final response = await _apiClient.post(
        '/booking-intents/$intentId/payment/cancel',
      );
      if (response.statusCode == 200) {
        return const Success(null);
      }
      return loggedFailure(
        UnknownError('cancel payment failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
