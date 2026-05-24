import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/baggage_item_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';

void main() {
  late MockApiClient mockApiClient;
  late BaggageRepositoryImpl repo;

  setUp(() {
    mockApiClient = MockApiClient();
    repo = BaggageRepositoryImpl(apiClient: mockApiClient);
  });

  final baggageItemJson = {
    'id': 'bag-1',
    'trip_id': 'trip-1',
    'name': 'Passport',
    'quantity': 1,
    'is_packed': false,
    'category': 'Documents',
  };

  group('getByTrip', () {
    test('returns Success(List<BaggageItem>) on 200', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [baggageItemJson],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage'),
        ),
      );

      final result = await repo.getByTrip('trip-1');

      expect(result, isA<Success>());
      final items = (result as Success).data;
      expect(items, hasLength(1));
      expect(items.first.id, 'bag-1');
      expect(items.first.name, 'Passport');
      expect(items.first.category, 'Documents');
    });
  });

  group('createBaggageItem', () {
    test('returns Success(BaggageItem) on 201', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: baggageItemJson,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage'),
        ),
      );

      final result = await repo.createBaggageItem(
        'trip-1',
        name: 'Passport',
        quantity: 1,
        category: 'Documents',
      );

      expect(result, isA<Success>());
      final item = (result as Success).data;
      expect(item.id, 'bag-1');
      expect(item.name, 'Passport');
    });
  });

  group('updateBaggageItem', () {
    test('returns Success(BaggageItem) on 200', () async {
      final updatedJson = {...baggageItemJson, 'is_packed': true};

      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: updatedJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage/bag-1'),
        ),
      );

      final result = await repo.updateBaggageItem('trip-1', 'bag-1', {
        'is_packed': true,
      });

      expect(result, isA<Success>());
      final item = (result as Success).data;
      expect(item.isPacked, true);
    });
  });

  group('deleteBaggageItem', () {
    test('returns Success(null) on 204', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage/bag-1'),
        ),
      );

      final result = await repo.deleteBaggageItem('trip-1', 'bag-1');

      expect(result, isA<Success>());
    });
  });

  group('suggestBaggage', () {
    test('returns Success(List<SuggestedBaggageItem>) on 200', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'items': [
              {
                'name': 'Sunscreen',
                'quantity': 1,
                'category': 'Toiletries',
                'reason': 'Sunny destination',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage/suggest'),
        ),
      );

      final result = await repo.suggestBaggage('trip-1');

      expect(result, isA<Success>());
      final suggestions = (result as Success).data;
      expect(suggestions, hasLength(1));
      expect(suggestions.first.name, 'Sunscreen');
      expect(suggestions.first.category, 'Toiletries');
      expect(suggestions.first.reason, 'Sunny destination');
    });

    test('DioException 402 returns Failure(QuotaExceededError)', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage/suggest'),
          response: Response(
            statusCode: 402,
            data: {'detail': 'quota exceeded'},
            requestOptions: RequestOptions(
              path: '/trips/trip-1/baggage/suggest',
            ),
          ),
        ),
      );

      final result = await repo.suggestBaggage('trip-1');

      expect(result, isA<Failure>());
      final error = (result as Failure).error;
      expect(error, isA<QuotaExceededError>());
      expect(error.statusCode, 402);
      expect(error.message, 'quota exceeded');
    });
  });

  group('getByTrip error handling', () {
    test('DioException connectionTimeout returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage'),
        ),
      );

      final result = await repo.getByTrip('trip-1');

      expect(result, isA<Failure>());
    });
  });

  // ── Phase B reinforcement ─────────────────────────────────────────────

  group('getByTrip — reinforcement', () {
    test('items envelope accepted', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'items': [baggageItemJson],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage'),
        ),
      );
      expect(await repo.getByTrip('trip-1'), isA<Success>());
    });

    test('invalid shape returns Failure(ServerError)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage'),
        ),
      );
      final result = await repo.getByTrip('trip-1');
      expect((result as Failure).error, isA<ServerError>());
    });

    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage'),
        ),
      );
      expect(await repo.getByTrip('trip-1'), isA<Failure>());
    });
  });

  group('createBaggageItem — reinforcement', () {
    test('non-2xx returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage'),
        ),
      );
      expect(await repo.createBaggageItem('trip-1', name: 'x'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.createBaggageItem('trip-1', name: 'x'), isA<Failure>());
    });
  });

  group('updateBaggageItem — reinforcement', () {
    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage/bag-1'),
        ),
      );
      expect(
        await repo.updateBaggageItem('trip-1', 'bag-1', {}),
        isA<Failure>(),
      );
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage/bag-1'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(
        await repo.updateBaggageItem('trip-1', 'bag-1', {}),
        isA<Failure>(),
      );
    });
  });

  group('deleteBaggageItem — reinforcement', () {
    test('non-2xx returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage/bag-1'),
        ),
      );
      expect(await repo.deleteBaggageItem('trip-1', 'bag-1'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage/bag-1'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.deleteBaggageItem('trip-1', 'bag-1'), isA<Failure>());
    });
  });

  group('suggestBaggage — reinforcement', () {
    test('invalid shape returns Failure(ServerError)', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage/suggest'),
        ),
      );
      final result = await repo.suggestBaggage('trip-1');
      expect((result as Failure).error, isA<ServerError>());
    });

    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1/baggage/suggest'),
        ),
      );
      expect(await repo.suggestBaggage('trip-1'), isA<Failure>());
    });
  });
}
