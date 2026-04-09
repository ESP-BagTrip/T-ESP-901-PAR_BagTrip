import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/service/cached_activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class MockActivityRepository extends Mock implements ActivityRepository {}

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockActivityRepository mockRemote;
  late MockCacheService mockCache;
  late MockConnectivityService mockConnectivity;
  late CachedActivityRepository repo;

  setUpAll(() {
    registerFallbackValue(const Duration(minutes: 15));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRemote = MockActivityRepository();
    mockCache = MockCacheService();
    mockConnectivity = MockConnectivityService();
    repo = CachedActivityRepository(
      remote: mockRemote,
      cache: mockCache,
      connectivity: mockConnectivity,
    );
  });

  group('getActivities', () {
    test('online + API success → caches and returns Success', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final activities = [makeActivity(), makeActivity(id: 'act-2')];
      when(
        () => mockRemote.getActivities('trip-1'),
      ).thenAnswer((_) async => Success(activities));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getActivities('trip-1');

      expect(result, isA<Success<List<Activity>>>());
      verify(
        () => mockCache.put('activities_cache', 'activities:trip-1', any()),
      ).called(1);
    });

    test('online + API failure → returns Failure, no cache write', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.getActivities('trip-1'),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.getActivities('trip-1');

      expect(result, isA<Failure<List<Activity>>>());
      verifyNever(() => mockCache.put(any(), any(), any()));
    });

    test('offline + cache hit → returns Success from cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      final activity = makeActivity();
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer(
        (_) async => {
          'items': [activity.toJson()],
        },
      );

      final result = await repo.getActivities('trip-1');

      expect(result, isA<Success<List<Activity>>>());
      verifyNever(() => mockRemote.getActivities(any()));
    });

    test('offline + cache miss → returns Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getActivities('trip-1');

      expect(result, isA<Failure<List<Activity>>>());
    });
  });

  group('pass-through methods', () {
    test('getActivitiesPaginated delegates to remote', () async {
      when(
        () => mockRemote.getActivitiesPaginated('trip-1'),
      ).thenAnswer((_) async => const Failure(ServerError('not tested')));

      await repo.getActivitiesPaginated('trip-1');

      verify(() => mockRemote.getActivitiesPaginated('trip-1')).called(1);
    });

    test('suggestActivities delegates to remote', () async {
      when(
        () => mockRemote.suggestActivities('trip-1'),
      ).thenAnswer((_) async => const Success([]));

      await repo.suggestActivities('trip-1');

      verify(() => mockRemote.suggestActivities('trip-1')).called(1);
    });
  });

  group('write operations', () {
    test('createActivity success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final activity = makeActivity();
      when(
        () => mockRemote.createActivity('trip-1', any()),
      ).thenAnswer((_) async => Success(activity));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.createActivity('trip-1', {'title': 'New'});

      expect(result, isA<Success<Activity>>());
      verify(
        () => mockCache.delete('activities_cache', 'activities:trip-1'),
      ).called(1);
    });

    test('createActivity failure → does not invalidate cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.createActivity('trip-1', any()),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.createActivity('trip-1', {'title': 'New'});

      expect(result, isA<Failure<Activity>>());
      verifyNever(() => mockCache.delete(any(), any()));
    });

    test('updateActivity success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final activity = makeActivity();
      when(
        () => mockRemote.updateActivity('trip-1', 'act-1', any()),
      ).thenAnswer((_) async => Success(activity));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.updateActivity('trip-1', 'act-1', {
        'title': 'Updated',
      });

      expect(result, isA<Success<Activity>>());
      verify(
        () => mockCache.delete('activities_cache', 'activities:trip-1'),
      ).called(1);
    });

    test('deleteActivity success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.deleteActivity('trip-1', 'act-1'),
      ).thenAnswer((_) async => const Success(null));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.deleteActivity('trip-1', 'act-1');

      expect(result, isA<Success<void>>());
      verify(
        () => mockCache.delete('activities_cache', 'activities:trip-1'),
      ).called(1);
    });

    test('batchUpdateActivities success → invalidates cache', () async {
      final activities = [makeActivity()];
      when(
        () => mockRemote.batchUpdateActivities('trip-1', any(), any()),
      ).thenAnswer((_) async => Success(activities));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.batchUpdateActivities(
        'trip-1',
        ['act-1'],
        {'validated': true},
      );

      expect(result, isA<Success<List<Activity>>>());
      verify(
        () => mockCache.delete('activities_cache', 'activities:trip-1'),
      ).called(1);
    });
  });
}
