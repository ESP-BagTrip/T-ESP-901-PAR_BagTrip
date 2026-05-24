import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/accommodation_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';

void main() {
  late MockApiClient mockApiClient;
  late AccommodationRepositoryImpl repo;

  setUp(() {
    mockApiClient = MockApiClient();
    repo = AccommodationRepositoryImpl(apiClient: mockApiClient);
  });

  final accommodationJson = {
    'id': 'acc-1',
    'trip_id': 'trip-1',
    'name': 'Grand Hotel',
    'address': '123 Main St',
    'price_per_night': 99.0,
    'currency': 'EUR',
  };

  group('getByTrip', () {
    test('returns Success(List<Accommodation>) on 200', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [accommodationJson],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/accommodations'),
        ),
      );

      final result = await repo.getByTrip('trip-1');

      expect(result, isA<Success>());
      final items = (result as Success).data;
      expect(items, hasLength(1));
      expect(items.first.id, 'acc-1');
      expect(items.first.name, 'Grand Hotel');
    });
  });

  group('createAccommodation', () {
    test('returns Success(Accommodation) on 201', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: accommodationJson,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/trips/trip-1/accommodations'),
        ),
      );

      final result = await repo.createAccommodation(
        'trip-1',
        name: 'Grand Hotel',
        address: '123 Main St',
        pricePerNight: 99.0,
        currency: 'EUR',
      );

      expect(result, isA<Success>());
      final item = (result as Success).data;
      expect(item.id, 'acc-1');
      expect(item.name, 'Grand Hotel');
      expect(item.pricePerNight, 99.0);
    });
  });

  group('updateAccommodation', () {
    test('returns Success(Accommodation) on 200', () async {
      final updatedJson = {...accommodationJson, 'name': 'Luxury Hotel'};

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
          requestOptions: RequestOptions(
            path: '/trips/trip-1/accommodations/acc-1',
          ),
        ),
      );

      final result = await repo.updateAccommodation('trip-1', 'acc-1', {
        'name': 'Luxury Hotel',
      });

      expect(result, isA<Success>());
      final item = (result as Success).data;
      expect(item.name, 'Luxury Hotel');
    });
  });

  group('deleteAccommodation', () {
    test('returns Success(null) on 204', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/accommodations/acc-1',
          ),
        ),
      );

      final result = await repo.deleteAccommodation('trip-1', 'acc-1');

      expect(result, isA<Success>());
    });
  });

  group('suggestAccommodations', () {
    test('returns Success(List<Map>) on 200', () async {
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
            'accommodations': [
              {'name': 'Suggested Hotel', 'pricePerNight': 75.0},
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/accommodations/suggest',
          ),
        ),
      );

      final result = await repo.suggestAccommodations('trip-1');

      expect(result, isA<Success>());
      final suggestions = (result as Success).data;
      expect(suggestions, hasLength(1));
      expect(suggestions.first['name'], 'Suggested Hotel');
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
          requestOptions: RequestOptions(
            path: '/trips/trip-1/accommodations/suggest',
          ),
          response: Response(
            statusCode: 402,
            data: {'detail': 'quota exceeded'},
            requestOptions: RequestOptions(
              path: '/trips/trip-1/accommodations/suggest',
            ),
          ),
        ),
      );

      final result = await repo.suggestAccommodations('trip-1');

      expect(result, isA<Failure>());
      final error = (result as Failure).error;
      expect(error, isA<QuotaExceededError>());
      expect(error.statusCode, 402);
      expect(error.message, 'quota exceeded');
    });
  });

  group('searchHotelsByCity', () {
    test('returns Success(List<Map>) on 200', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': [
              {'hotelId': 'h1', 'name': 'City Hotel'},
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/travel/hotels/by-city'),
        ),
      );

      final result = await repo.searchHotelsByCity('PAR');

      expect(result, isA<Success>());
      final hotels = (result as Success).data;
      expect(hotels, hasLength(1));
      expect(hotels.first['name'], 'City Hotel');
    });
  });

  group('searchHotelOffers', () {
    test('returns Success(List<Map>) on 200', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': [
              {'offerId': 'o1', 'price': 120.0},
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/travel/hotels/offers'),
        ),
      );

      final result = await repo.searchHotelOffers('h1');

      expect(result, isA<Success>());
      final offers = (result as Success).data;
      expect(offers, hasLength(1));
      expect(offers.first['offerId'], 'o1');
    });
  });

  // ── Phase B reinforcement: failure paths on every method ──────────────

  group('createAccommodation — error paths', () {
    test('serializes checkIn/checkOut as date-only ISO strings', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: accommodationJson,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/trips/trip-1/accommodations'),
        ),
      );

      await repo.createAccommodation(
        'trip-1',
        name: 'Grand',
        checkIn: DateTime(2025, 6, 5, 14),
        checkOut: DateTime(2025, 6, 10, 11),
        bookingReference: 'REF-1',
        notes: 'n/a',
      );

      final captured = verify(
        () => mockApiClient.post(
          '/trips/trip-1/accommodations',
          data: captureAny(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      expect(payload['checkIn'], '2025-06-05');
      expect(payload['checkOut'], '2025-06-10');
      expect(payload['bookingReference'], 'REF-1');
    });

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
          requestOptions: RequestOptions(path: '/trips/trip-1/accommodations'),
        ),
      );
      expect(
        await repo.createAccommodation('trip-1', name: 'x'),
        isA<Failure>(),
      );
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
          requestOptions: RequestOptions(path: '/trips/trip-1/accommodations'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(
        await repo.createAccommodation('trip-1', name: 'x'),
        isA<Failure>(),
      );
    });
  });

  group('getByTrip — reinforcement', () {
    test('accepts `items` envelope shape', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'items': [accommodationJson],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/accommodations'),
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
          requestOptions: RequestOptions(path: '/trips/trip-1/accommodations'),
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
          requestOptions: RequestOptions(path: '/trips/trip-1/accommodations'),
        ),
      );
      expect(await repo.getByTrip('trip-1'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/accommodations'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.getByTrip('trip-1'), isA<Failure>());
    });
  });

  group('updateAccommodation — reinforcement', () {
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
          requestOptions: RequestOptions(
            path: '/trips/trip-1/accommodations/acc-1',
          ),
        ),
      );
      expect(
        await repo.updateAccommodation('trip-1', 'acc-1', {}),
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
          requestOptions: RequestOptions(
            path: '/trips/trip-1/accommodations/acc-1',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(
        await repo.updateAccommodation('trip-1', 'acc-1', {}),
        isA<Failure>(),
      );
    });
  });

  group('deleteAccommodation — reinforcement', () {
    test('non-2xx returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(
            path: '/trips/trip-1/accommodations/acc-1',
          ),
        ),
      );
      expect(await repo.deleteAccommodation('trip-1', 'acc-1'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/trips/trip-1/accommodations/acc-1',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.deleteAccommodation('trip-1', 'acc-1'), isA<Failure>());
    });
  });

  group('suggestAccommodations — reinforcement', () {
    test('empty list when no accommodations field', () async {
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
          requestOptions: RequestOptions(
            path: '/trips/trip-1/accommodations/suggest',
          ),
        ),
      );
      final result = await repo.suggestAccommodations('trip-1');
      expect(result, isA<Success>());
      expect((result as Success).data, isEmpty);
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
          requestOptions: RequestOptions(
            path: '/trips/trip-1/accommodations/suggest',
          ),
        ),
      );
      expect(await repo.suggestAccommodations('trip-1'), isA<Failure>());
    });
  });

  group('searchHotelsByCity + searchHotelOffers — error paths', () {
    test('searchHotelsByCity non-200 returns Failure', () async {
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
          requestOptions: RequestOptions(path: '/travel/hotels/by-city'),
        ),
      );
      expect(await repo.searchHotelsByCity('PAR'), isA<Failure>());
    });

    test('searchHotelsByCity DioException returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/travel/hotels/by-city'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.searchHotelsByCity('PAR'), isA<Failure>());
    });

    test('searchHotelOffers non-200 returns Failure', () async {
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
          requestOptions: RequestOptions(path: '/travel/hotels/offers'),
        ),
      );
      expect(await repo.searchHotelOffers('h1'), isA<Failure>());
    });

    test('searchHotelOffers DioException returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/travel/hotels/offers'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.searchHotelOffers('h1'), isA<Failure>());
    });
  });
}
