// Keys must match the snake_case names produced by _$TravelerFromJson.
// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/traveler_service.dart';
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

Map<String, dynamic> _travelerJson({String id = 't-1'}) => <String, dynamic>{
  'id': id,
  'trip_id': 'trip-1',
  'amadeus_traveler_ref': 'ref-1',
  'traveler_type': 'ADULT',
  'first_name': 'Jane',
  'last_name': 'Doe',
  'date_of_birth': '1990-05-10T00:00:00.000Z',
  'gender': 'FEMALE',
  'documents': [],
  'contacts': <String, dynamic>{},
  'created_at': '2025-01-01T00:00:00.000Z',
  'updated_at': '2025-01-02T00:00:00.000Z',
};

void main() {
  late _MockApiClient mockApiClient;
  late TravelerRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApiClient = _MockApiClient();
    repository = TravelerRepositoryImpl(apiClient: mockApiClient);
  });

  group('TravelerRepositoryImpl', () {
    // ── createTraveler ──────────────────────────────────────────────────

    test('createTraveler posts only the provided fields', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/travelers',
          statusCode: 201,
          data: _travelerJson(),
        ),
      );

      final result = await repository.createTraveler(
        'trip-1',
        travelerType: 'ADULT',
        firstName: 'Jane',
        lastName: 'Doe',
        dateOfBirth: DateTime.utc(1990, 5, 10),
      );

      expect(result, isA<Success>());
      final captured = verify(
        () => mockApiClient.post(
          '/trips/trip-1/travelers',
          data: captureAny(named: 'data'),
        ),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      expect(payload['travelerType'], 'ADULT');
      expect(payload['firstName'], 'Jane');
      expect(payload['lastName'], 'Doe');
      expect(payload['dateOfBirth'], isNotNull);
      expect(payload.containsKey('amadeusTravelerRef'), isFalse);
      expect(payload.containsKey('gender'), isFalse);
      expect(payload.containsKey('documents'), isFalse);
      expect(payload.containsKey('contacts'), isFalse);
    });

    test('createTraveler returns Failure on non-2xx', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/travelers',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );

      final result = await repository.createTraveler(
        'trip-1',
        travelerType: 'ADULT',
        firstName: 'Jane',
        lastName: 'Doe',
      );

      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<UnknownError>());
    });

    test('createTraveler maps DioException to Failure', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/travelers'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await repository.createTraveler(
        'trip-1',
        travelerType: 'ADULT',
        firstName: 'Jane',
        lastName: 'Doe',
      );

      expect(result, isA<Failure>());
    });

    // ── getTravelersByTrip ──────────────────────────────────────────────

    test('getTravelersByTrip parses a raw list response', () async {
      when(() => mockApiClient.get('/trips/trip-1/travelers')).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/travelers',
          statusCode: 200,
          data: [
            _travelerJson(id: 't-1'),
            _travelerJson(id: 't-2'),
          ],
        ),
      );

      final result = await repository.getTravelersByTrip('trip-1');
      expect(result, isA<Success>());
      expect(((result as Success).data as List).length, 2);
    });

    test('getTravelersByTrip parses an `items` envelope', () async {
      when(() => mockApiClient.get('/trips/trip-1/travelers')).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/travelers',
          statusCode: 200,
          data: <String, dynamic>{
            'items': [_travelerJson()],
          },
        ),
      );

      final result = await repository.getTravelersByTrip('trip-1');
      expect(result, isA<Success>());
      expect(((result as Success).data as List).length, 1);
    });

    test(
      'getTravelersByTrip returns empty Success on unknown payload shape',
      () async {
        when(() => mockApiClient.get('/trips/trip-1/travelers')).thenAnswer(
          (_) async => _response(
            path: '/trips/trip-1/travelers',
            statusCode: 200,
            data: <String, dynamic>{},
          ),
        );

        final result = await repository.getTravelersByTrip('trip-1');
        expect(result, isA<Success>());
        expect(((result as Success).data as List).isEmpty, isTrue);
      },
    );

    test('getTravelersByTrip returns Failure on non-200', () async {
      when(() => mockApiClient.get('/trips/trip-1/travelers')).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/travelers',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );

      expect(await repository.getTravelersByTrip('trip-1'), isA<Failure>());
    });

    test('getTravelersByTrip maps DioException to Failure', () async {
      when(() => mockApiClient.get('/trips/trip-1/travelers')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/travelers'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repository.getTravelersByTrip('trip-1'), isA<Failure>());
    });

    // ── updateTraveler ──────────────────────────────────────────────────

    test('updateTraveler returns Success on 200', () async {
      when(
        () => mockApiClient.patch(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/travelers/t-1',
          statusCode: 200,
          data: _travelerJson(),
        ),
      );

      final result = await repository.updateTraveler('trip-1', 't-1', {
        'firstName': 'Jane2',
      });
      expect(result, isA<Success>());
    });

    test('updateTraveler returns Failure on non-200', () async {
      when(
        () => mockApiClient.patch(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/travelers/t-1',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );

      expect(
        await repository.updateTraveler('trip-1', 't-1', {'firstName': 'x'}),
        isA<Failure>(),
      );
    });

    test('updateTraveler maps DioException to Failure', () async {
      when(
        () => mockApiClient.patch(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/travelers/t-1'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        await repository.updateTraveler('trip-1', 't-1', {'firstName': 'x'}),
        isA<Failure>(),
      );
    });

    // ── deleteTraveler ──────────────────────────────────────────────────

    test('deleteTraveler returns Success on 204', () async {
      when(() => mockApiClient.delete(any())).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/travelers/t-1',
          statusCode: 204,
          data: null,
        ),
      );

      expect(await repository.deleteTraveler('trip-1', 't-1'), isA<Success>());
    });

    test('deleteTraveler returns Failure on non-2xx', () async {
      when(() => mockApiClient.delete(any())).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/travelers/t-1',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );
      expect(await repository.deleteTraveler('trip-1', 't-1'), isA<Failure>());
    });

    test('deleteTraveler maps DioException to Failure', () async {
      when(() => mockApiClient.delete(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/travelers/t-1'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repository.deleteTraveler('trip-1', 't-1'), isA<Failure>());
    });
  });
}
