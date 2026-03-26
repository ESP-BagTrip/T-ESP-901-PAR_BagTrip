import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/trip_share_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';

void main() {
  late MockApiClient mockApiClient;
  late TripShareRepositoryImpl repo;

  setUp(() {
    mockApiClient = MockApiClient();
    repo = TripShareRepositoryImpl(apiClient: mockApiClient);
  });

  final tripShareJson = {
    'id': 'share-1',
    'trip_id': 'trip-1',
    'user_id': 'user-2',
    'role': 'VIEWER',
    'user_email': 'friend@example.com',
    'user_full_name': 'Jane Doe',
  };

  group('getSharesByTrip', () {
    test('returns Success(List<TripShare>) on 200', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [tripShareJson],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/shares'),
        ),
      );

      final result = await repo.getSharesByTrip('trip-1');

      expect(result, isA<Success>());
      final shares = (result as Success).data;
      expect(shares, hasLength(1));
      expect(shares.first.id, 'share-1');
      expect(shares.first.userEmail, 'friend@example.com');
      expect(shares.first.role, 'VIEWER');
    });
  });

  group('createShare', () {
    test('returns Success(TripShare) on 201', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tripShareJson,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/trips/trip-1/shares'),
        ),
      );

      final result = await repo.createShare(
        'trip-1',
        email: 'friend@example.com',
      );

      expect(result, isA<Success>());
      final share = (result as Success).data;
      expect(share.id, 'share-1');
      expect(share.userEmail, 'friend@example.com');
    });
  });

  group('deleteShare', () {
    test('returns Success(null) on 204', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/trips/trip-1/shares/share-1'),
        ),
      );

      final result = await repo.deleteShare('trip-1', 'share-1');

      expect(result, isA<Success>());
    });
  });

  group('createShare error handling', () {
    test('DioException connectionTimeout returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/trips/trip-1/shares'),
        ),
      );

      final result = await repo.createShare(
        'trip-1',
        email: 'friend@example.com',
      );

      expect(result, isA<Failure>());
    });
  });

  group('getSharesByTrip error handling', () {
    test('DioException 404 returns Failure(NotFoundError)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/shares'),
          response: Response(
            statusCode: 404,
            data: {'detail': 'trip not found'},
            requestOptions: RequestOptions(path: '/trips/trip-1/shares'),
          ),
        ),
      );

      final result = await repo.getSharesByTrip('trip-1');

      expect(result, isA<Failure>());
      final error = (result as Failure).error;
      expect(error, isA<NotFoundError>());
      expect(error.statusCode, 404);
      expect(error.message, 'trip not found');
    });
  });
}
