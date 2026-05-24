import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/repositories/feedback_repository.dart';
import 'package:bagtrip/service/cached_feedback_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class MockFeedbackRepository extends Mock implements FeedbackRepository {}

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockFeedbackRepository mockRemote;
  late MockCacheService mockCache;
  late MockConnectivityService mockConnectivity;
  late CachedFeedbackRepository repo;

  setUpAll(() {
    registerFallbackValue(const Duration(minutes: 15));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRemote = MockFeedbackRepository();
    mockCache = MockCacheService();
    mockConnectivity = MockConnectivityService();
    repo = CachedFeedbackRepository(
      remote: mockRemote,
      cache: mockCache,
      connectivity: mockConnectivity,
    );
  });

  group('getFeedbacks', () {
    test('online + API success → caches and returns Success', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final items = [makeTripFeedback(), makeTripFeedback(id: 'fb-2')];
      when(
        () => mockRemote.getFeedbacks('trip-1'),
      ).thenAnswer((_) async => Success(items));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getFeedbacks('trip-1');

      expect(result, isA<Success<List<TripFeedback>>>());
      verify(
        () => mockCache.put('feedback_cache', 'feedbacks:trip-1', any()),
      ).called(1);
    });

    test('online + API failure → returns Failure, no cache write', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.getFeedbacks('trip-1'),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.getFeedbacks('trip-1');

      expect(result, isA<Failure<List<TripFeedback>>>());
      verifyNever(() => mockCache.put(any(), any(), any()));
    });

    test('offline + cache hit → returns Success from cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer(
        (_) async => {
          'items': [makeTripFeedback().toJson()],
        },
      );

      final result = await repo.getFeedbacks('trip-1');

      expect(result, isA<Success<List<TripFeedback>>>());
      verifyNever(() => mockRemote.getFeedbacks(any()));
    });

    test('offline + cache miss → returns Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getFeedbacks('trip-1');

      expect(result, isA<Failure<List<TripFeedback>>>());
    });
  });

  group('write operations', () {
    test('submitFeedback success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.submitFeedback(
          'trip-1',
          overallRating: any(named: 'overallRating'),
          highlights: any(named: 'highlights'),
          lowlights: any(named: 'lowlights'),
          wouldRecommend: any(named: 'wouldRecommend'),
          aiExperienceRating: any(named: 'aiExperienceRating'),
        ),
      ).thenAnswer((_) async => Success(makeTripFeedback()));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.submitFeedback(
        'trip-1',
        overallRating: 5,
        wouldRecommend: true,
      );

      expect(result, isA<Success<TripFeedback>>());
      verify(
        () => mockCache.delete('feedback_cache', 'feedbacks:trip-1'),
      ).called(1);
    });

    test('submitFeedback failure → does not invalidate', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.submitFeedback(
          'trip-1',
          overallRating: any(named: 'overallRating'),
          highlights: any(named: 'highlights'),
          lowlights: any(named: 'lowlights'),
          wouldRecommend: any(named: 'wouldRecommend'),
          aiExperienceRating: any(named: 'aiExperienceRating'),
        ),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.submitFeedback(
        'trip-1',
        overallRating: 5,
        wouldRecommend: true,
      );

      expect(result, isA<Failure<TripFeedback>>());
      verifyNever(() => mockCache.delete(any(), any()));
    });
  });
}
