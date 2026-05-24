// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/feedback_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

Response _response({
  required String path,
  required int statusCode,
  required Object? data,
}) => Response(
  requestOptions: RequestOptions(path: path),
  statusCode: statusCode,
  data: data,
);

/// Keys must match the snake_case names produced by
/// `_$TripFeedbackFromJson` (the json_serializable default).
Map<String, dynamic> _feedbackJson({
  String id = 'fb-1',
  String tripId = 'trip-1',
  int overallRating = 4,
}) => <String, dynamic>{
  'id': id,
  'trip_id': tripId,
  'user_id': 'user-1',
  'overall_rating': overallRating,
  'highlights': 'Great guides',
  'lowlights': null,
  'would_recommend': true,
  'ai_experience_rating': 5,
  'created_at': '2025-01-15T10:00:00.000Z',
};

void main() {
  late _MockApiClient mockApiClient;
  late FeedbackRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApiClient = _MockApiClient();
    repository = FeedbackRepositoryImpl(apiClient: mockApiClient);
  });

  group('FeedbackRepositoryImpl', () {
    // ── submitFeedback ──────────────────────────────────────────────────

    test('submitFeedback returns Success(TripFeedback) on 201', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/feedback',
          statusCode: 201,
          data: _feedbackJson(),
        ),
      );

      final result = await repository.submitFeedback(
        'trip-1',
        overallRating: 4,
        highlights: 'Great guides',
        wouldRecommend: true,
        aiExperienceRating: 5,
      );

      expect(result, isA<Success<dynamic>>());
      final fb = (result as Success).data;
      expect(fb.id, 'fb-1');
      expect(fb.overallRating, 4);

      final captured = verify(
        () => mockApiClient.post(
          '/trips/trip-1/feedback',
          data: captureAny(named: 'data'),
        ),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      expect(payload['overallRating'], 4);
      expect(payload['highlights'], 'Great guides');
      expect(payload['wouldRecommend'], true);
      expect(payload['aiExperienceRating'], 5);
      // lowlights wasn't passed, should not be in payload.
      expect(payload.containsKey('lowlights'), isFalse);
    });

    test('submitFeedback returns Success on 200 too', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/feedback',
          statusCode: 200,
          data: _feedbackJson(),
        ),
      );

      final result = await repository.submitFeedback(
        'trip-1',
        overallRating: 3,
        wouldRecommend: false,
      );

      expect(result, isA<Success<dynamic>>());
    });

    test('submitFeedback returns Failure on non-2xx status', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/feedback',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );

      final result = await repository.submitFeedback(
        'trip-1',
        overallRating: 4,
        wouldRecommend: true,
      );

      expect(result, isA<Failure<dynamic>>());
      expect((result as Failure).error, isA<UnknownError>());
    });

    test('submitFeedback maps DioException to Failure', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/feedback'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await repository.submitFeedback(
        'trip-1',
        overallRating: 4,
        wouldRecommend: true,
      );

      expect(result, isA<Failure<dynamic>>());
    });

    // ── getFeedbacks ────────────────────────────────────────────────────

    test('getFeedbacks parses an `items` envelope', () async {
      when(() => mockApiClient.get(any())).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/feedback',
          statusCode: 200,
          data: <String, dynamic>{
            'items': [
              _feedbackJson(id: 'fb-1'),
              _feedbackJson(id: 'fb-2', overallRating: 5),
            ],
          },
        ),
      );

      final result = await repository.getFeedbacks('trip-1');

      expect(result, isA<Success<dynamic>>());
      final list = (result as Success).data as List;
      expect(list.length, 2);
      expect(list.first.id, 'fb-1');
      expect(list.last.overallRating, 5);
    });

    test('getFeedbacks parses a raw list response', () async {
      when(() => mockApiClient.get(any())).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/feedback',
          statusCode: 200,
          data: [_feedbackJson()],
        ),
      );

      final result = await repository.getFeedbacks('trip-1');

      expect(result, isA<Success<dynamic>>());
      expect(((result as Success).data as List).length, 1);
    });

    test(
      'getFeedbacks returns empty Success on unknown payload shape',
      () async {
        when(() => mockApiClient.get(any())).thenAnswer(
          (_) async => _response(
            path: '/trips/trip-1/feedback',
            statusCode: 200,
            data: <String, dynamic>{},
          ),
        );

        final result = await repository.getFeedbacks('trip-1');

        expect(result, isA<Success<dynamic>>());
        expect(((result as Success).data as List).isEmpty, isTrue);
      },
    );

    test('getFeedbacks returns Failure on non-200 status', () async {
      when(() => mockApiClient.get(any())).thenAnswer(
        (_) async => _response(
          path: '/trips/trip-1/feedback',
          statusCode: 404,
          data: <String, dynamic>{},
        ),
      );

      final result = await repository.getFeedbacks('trip-1');

      expect(result, isA<Failure<dynamic>>());
    });

    test('getFeedbacks maps DioException to Failure', () async {
      when(() => mockApiClient.get(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/feedback'),
          response: Response(
            requestOptions: RequestOptions(path: '/trips/trip-1/feedback'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.getFeedbacks('trip-1');

      expect(result, isA<Failure<dynamic>>());
    });
  });
}
