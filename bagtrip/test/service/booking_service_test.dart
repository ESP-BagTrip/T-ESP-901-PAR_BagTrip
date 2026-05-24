// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/booking_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

Response _response({
  required String path,
  required int statusCode,
  Object? data,
}) => Response(
  requestOptions: RequestOptions(path: path),
  statusCode: statusCode,
  data: data,
);

Map<String, dynamic> _bookingJson({String id = 'b-1'}) => <String, dynamic>{
  'id': id,
  'amadeusOrderId': 'amadeus-1',
  'status': 'CONFIRMED',
  'priceTotal': 129.5,
  'currency': 'EUR',
  'createdAt': '2025-01-01T10:00:00.000Z',
};

void main() {
  late _MockApiClient mockApiClient;
  late BookingRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApiClient = _MockApiClient();
    repository = BookingRepositoryImpl(apiClient: mockApiClient);
  });

  group('BookingRepositoryImpl', () {
    // ── listBookings ────────────────────────────────────────────────────

    test('listBookings returns parsed list on 200', () async {
      when(() => mockApiClient.get('/booking/list')).thenAnswer(
        (_) async => _response(
          path: '/booking/list',
          statusCode: 200,
          data: [
            _bookingJson(id: 'b-1'),
            _bookingJson(id: 'b-2'),
          ],
        ),
      );

      final result = await repository.listBookings();

      expect(result, isA<Success>());
      final list = (result as Success).data as List;
      expect(list.length, 2);
      expect(list.first.id, 'b-1');
    });

    test('listBookings returns empty Success when data is null', () async {
      when(() => mockApiClient.get('/booking/list')).thenAnswer(
        (_) async =>
            _response(path: '/booking/list', statusCode: 200, data: null),
      );

      final result = await repository.listBookings();

      expect(result, isA<Success>());
      expect(((result as Success).data as List).isEmpty, isTrue);
    });

    test('listBookings returns Failure on non-200', () async {
      when(() => mockApiClient.get('/booking/list')).thenAnswer(
        (_) async => _response(
          path: '/booking/list',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );

      final result = await repository.listBookings();

      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<UnknownError>());
    });

    test('listBookings maps DioException to Failure', () async {
      when(() => mockApiClient.get('/booking/list')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/booking/list'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(await repository.listBookings(), isA<Failure>());
    });

    // ── createBookingIntent ─────────────────────────────────────────────

    test('createBookingIntent returns the new intent id on 201', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/trips/t-1/booking-intents',
          statusCode: 201,
          data: <String, dynamic>{'id': 'intent-42'},
        ),
      );

      final result = await repository.createBookingIntent(
        tripId: 't-1',
        flightOfferId: 'offer-9',
      );

      expect(result, isA<Success>());
      expect((result as Success).data, 'intent-42');

      final captured = verify(
        () => mockApiClient.post(
          '/trips/t-1/booking-intents',
          data: captureAny(named: 'data'),
        ),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      expect(payload['type'], 'FLIGHT');
      expect(payload['flightOfferId'], 'offer-9');
    });

    test('createBookingIntent accepts 200 too', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/trips/t-1/booking-intents',
          statusCode: 200,
          data: <String, dynamic>{'id': 'intent-1'},
        ),
      );

      final result = await repository.createBookingIntent(
        tripId: 't-1',
        flightOfferId: 'offer-1',
      );

      expect(result, isA<Success>());
    });

    test('createBookingIntent returns Failure on non-2xx', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/trips/t-1/booking-intents',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );

      expect(
        await repository.createBookingIntent(tripId: 't-1', flightOfferId: 'o'),
        isA<Failure>(),
      );
    });

    test('createBookingIntent maps DioException to Failure', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/t-1/booking-intents'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        await repository.createBookingIntent(tripId: 't-1', flightOfferId: 'o'),
        isA<Failure>(),
      );
    });

    // ── authorizePayment ────────────────────────────────────────────────

    test('authorizePayment returns parsed response on 200', () async {
      when(() => mockApiClient.post(any())).thenAnswer(
        (_) async => _response(
          path: '/booking-intents/i-1/payment/authorize',
          statusCode: 200,
          data: <String, dynamic>{
            'stripePaymentIntentId': 'pi_123',
            'clientSecret': 'secret',
            'status': 'requires_capture',
          },
        ),
      );

      final result = await repository.authorizePayment('i-1');

      expect(result, isA<Success>());
      final resp = (result as Success).data;
      expect(resp.stripePaymentIntentId, 'pi_123');
      expect(resp.clientSecret, 'secret');
    });

    test('authorizePayment returns Failure on non-200', () async {
      when(() => mockApiClient.post(any())).thenAnswer(
        (_) async => _response(
          path: '/booking-intents/i-1/payment/authorize',
          statusCode: 402,
          data: <String, dynamic>{},
        ),
      );

      expect(await repository.authorizePayment('i-1'), isA<Failure>());
    });

    test('authorizePayment maps DioException to Failure', () async {
      when(() => mockApiClient.post(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/booking-intents/i-1/payment/authorize',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repository.authorizePayment('i-1'), isA<Failure>());
    });

    // ── capturePayment / cancelPayment ──────────────────────────────────

    test('capturePayment returns Success(void) on 200', () async {
      when(() => mockApiClient.post(any())).thenAnswer(
        (_) async => _response(
          path: '/booking-intents/i-1/payment/capture',
          statusCode: 200,
          data: null,
        ),
      );

      expect(await repository.capturePayment('i-1'), isA<Success>());
    });

    test('capturePayment returns Failure on non-200', () async {
      when(() => mockApiClient.post(any())).thenAnswer(
        (_) async => _response(
          path: '/booking-intents/i-1/payment/capture',
          statusCode: 409,
          data: <String, dynamic>{},
        ),
      );

      expect(await repository.capturePayment('i-1'), isA<Failure>());
    });

    test('capturePayment maps DioException to Failure', () async {
      when(() => mockApiClient.post(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/booking-intents/i-1/payment/capture',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(await repository.capturePayment('i-1'), isA<Failure>());
    });

    test('cancelPayment returns Success on 200', () async {
      when(() => mockApiClient.post(any())).thenAnswer(
        (_) async => _response(
          path: '/booking-intents/i-1/payment/cancel',
          statusCode: 200,
          data: null,
        ),
      );

      expect(await repository.cancelPayment('i-1'), isA<Success>());
    });

    test('cancelPayment returns Failure on non-200', () async {
      when(() => mockApiClient.post(any())).thenAnswer(
        (_) async => _response(
          path: '/booking-intents/i-1/payment/cancel',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );

      expect(await repository.cancelPayment('i-1'), isA<Failure>());
    });

    test('cancelPayment maps DioException to Failure', () async {
      when(() => mockApiClient.post(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/booking-intents/i-1/payment/cancel',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repository.cancelPayment('i-1'), isA<Failure>());
    });
  });
}
