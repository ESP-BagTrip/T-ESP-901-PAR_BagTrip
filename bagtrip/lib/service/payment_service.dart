import 'package:bagtrip/models/payment.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class PaymentService {
  final ApiClient _apiClient;

  PaymentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Authorize payment for a booking intent (creates Stripe PaymentIntent)
  /// POST /v1/booking-intents/{intentId}/payment/authorize
  Future<PaymentAuthorizeResponse> authorizePayment(
    String intentId, {
    String? returnUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (returnUrl != null) {
        data['returnUrl'] = returnUrl;
      }

      final response = await _apiClient.post(
        '/booking-intents/$intentId/payment/authorize',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentAuthorizeResponse.fromJson(response.data);
      } else {
        // Extract error message from response
        final errorMessage = _extractErrorMessage(response);
        throw Exception(
          'Failed to authorize payment (${response.statusCode}): $errorMessage',
        );
      }
    } on DioException catch (e) {
      // ApiClient already handles errors, but extract the detail if available
      final errorMessage = _extractErrorMessageFromDio(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error authorizing payment: $e');
    }
  }

  String _extractErrorMessage(dynamic response) {
    try {
      if (response is Response && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        return data['detail']?.toString() ??
            data['message']?.toString() ??
            'Unknown error';
      }
      return 'Unknown error';
    } catch (_) {
      return 'Unknown error';
    }
  }

  String _extractErrorMessageFromDio(DioException e) {
    // ApiClient._handleError already extracts the detail and puts it in e.error
    // But also check response.data directly as fallback
    if (e.response?.data is Map) {
      final data = e.response!.data as Map<String, dynamic>;
      final detail = data['detail']?.toString();
      if (detail != null) return detail;
    }
    // Use the error message from ApiClient (which extracts detail)
    return e.error?.toString() ?? e.message ?? 'Unknown error';
  }

  /// Confirm payment (test mode)
  /// POST /v1/booking-intents/{intentId}/payment/confirm-test
  Future<PaymentAuthorizeResponse> confirmPaymentTest(String intentId) async {
    try {
      final response = await _apiClient.post(
        '/booking-intents/$intentId/payment/confirm-test',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentAuthorizeResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to confirm payment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error confirming payment: $e');
    }
  }

  /// Capture payment for a booking intent
  /// POST /v1/booking-intents/{intentId}/payment/capture
  Future<PaymentCaptureResponse> capturePayment(String intentId) async {
    try {
      final response = await _apiClient.post(
        '/booking-intents/$intentId/payment/capture',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentCaptureResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to capture payment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error capturing payment: $e');
    }
  }
}
