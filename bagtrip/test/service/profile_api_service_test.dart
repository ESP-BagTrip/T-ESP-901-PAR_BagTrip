import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/profile_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

Response _ok(String path, Object? data) => Response(
  requestOptions: RequestOptions(path: path),
  statusCode: 200,
  data: data,
);

Map<String, dynamic> _profileJson() => <String, dynamic>{
  'id': 'profile-1',
  'travelTypes': ['culture', 'nature'],
  'travelStyle': 'balanced',
  'budget': 'medium',
  'companions': 'couple',
  'travelFrequency': 'monthly',
  'medicalConstraints': null,
  'isCompleted': true,
  'createdAt': '2025-01-01T00:00:00.000Z',
  'updatedAt': '2025-02-01T00:00:00.000Z',
};

void main() {
  late _MockApiClient mockApiClient;
  late ProfileRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApiClient = _MockApiClient();
    repository = ProfileRepositoryImpl(apiClient: mockApiClient);
  });

  group('ProfileRepositoryImpl', () {
    // ── getProfile ──────────────────────────────────────────────────────

    test('getProfile returns Success(TravelerProfile) on 200', () async {
      when(
        () => mockApiClient.get('/profile'),
      ).thenAnswer((_) async => _ok('/profile', _profileJson()));

      final result = await repository.getProfile();

      expect(result, isA<Success>());
      final profile = (result as Success).data;
      expect(profile.id, 'profile-1');
      expect(profile.travelTypes, ['culture', 'nature']);
      expect(profile.budget, 'medium');
      expect(profile.isCompleted, isTrue);
    });

    test('getProfile maps DioException to Failure(NetworkError)', () async {
      when(() => mockApiClient.get('/profile')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/profile'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await repository.getProfile();

      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<NetworkError>());
    });

    test('getProfile wraps non-DioException in UnknownError', () async {
      when(
        () => mockApiClient.get('/profile'),
      ).thenThrow(const FormatException('invalid json'));

      final result = await repository.getProfile();

      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<UnknownError>());
    });

    // ── updateProfile ───────────────────────────────────────────────────

    test('updateProfile only sends the fields that were passed', () async {
      when(
        () => mockApiClient.put(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _ok('/profile', _profileJson()));

      final result = await repository.updateProfile(
        travelTypes: ['food'],
        budget: 'low',
      );

      expect(result, isA<Success>());

      final captured = verify(
        () => mockApiClient.put('/profile', data: captureAny(named: 'data')),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      expect(payload, {
        'travelTypes': ['food'],
        'budget': 'low',
      });
      // Fields that weren't passed must not leak into the payload as `null`.
      expect(payload.containsKey('travelStyle'), isFalse);
      expect(payload.containsKey('companions'), isFalse);
      expect(payload.containsKey('medicalConstraints'), isFalse);
    });

    test('updateProfile returns Failure on DioException', () async {
      when(() => mockApiClient.put(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/profile'),
          response: Response(
            requestOptions: RequestOptions(path: '/profile'),
            statusCode: 400,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.updateProfile(budget: 'low');

      expect(result, isA<Failure>());
    });

    // ── checkCompletion ─────────────────────────────────────────────────

    test('checkCompletion parses the completion payload', () async {
      when(() => mockApiClient.get('/profile/completion')).thenAnswer(
        (_) async => _ok('/profile/completion', <String, dynamic>{
          'isCompleted': false,
          'missingFields': ['travelStyle', 'companions'],
        }),
      );

      final result = await repository.checkCompletion();

      expect(result, isA<Success>());
      final completion = (result as Success).data;
      expect(completion.isCompleted, isFalse);
      expect(completion.missingFields, ['travelStyle', 'companions']);
    });

    test('checkCompletion returns Failure on DioException', () async {
      when(() => mockApiClient.get('/profile/completion')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/profile/completion'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await repository.checkCompletion();

      expect(result, isA<Failure>());
    });
  });
}
