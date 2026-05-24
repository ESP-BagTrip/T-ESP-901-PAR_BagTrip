import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/repositories/trip_share_repository.dart';
import 'package:bagtrip/service/cached_trip_share_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class MockTripShareRepository extends Mock implements TripShareRepository {}

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockTripShareRepository mockRemote;
  late MockCacheService mockCache;
  late MockConnectivityService mockConnectivity;
  late CachedTripShareRepository repo;

  setUpAll(() {
    registerFallbackValue(const Duration(minutes: 15));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRemote = MockTripShareRepository();
    mockCache = MockCacheService();
    mockConnectivity = MockConnectivityService();
    repo = CachedTripShareRepository(
      remote: mockRemote,
      cache: mockCache,
      connectivity: mockConnectivity,
    );
  });

  group('getSharesByTrip', () {
    test('online + API success → caches and returns Success', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final items = [makeTripShare(), makeTripShare(id: 'share-2')];
      when(
        () => mockRemote.getSharesByTrip('trip-1'),
      ).thenAnswer((_) async => Success(items));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getSharesByTrip('trip-1');

      expect(result, isA<Success<List<TripShare>>>());
      verify(
        () => mockCache.put('trip_share_cache', 'shares:trip-1', any()),
      ).called(1);
    });

    test('online + API failure → returns Failure, no cache write', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.getSharesByTrip('trip-1'),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.getSharesByTrip('trip-1');

      expect(result, isA<Failure<List<TripShare>>>());
      verifyNever(() => mockCache.put(any(), any(), any()));
    });

    test('offline + cache hit → returns Success from cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer(
        (_) async => {
          'items': [makeTripShare().toJson()],
        },
      );

      final result = await repo.getSharesByTrip('trip-1');

      expect(result, isA<Success<List<TripShare>>>());
      verifyNever(() => mockRemote.getSharesByTrip(any()));
    });

    test('offline + cache miss → returns Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getSharesByTrip('trip-1');

      expect(result, isA<Failure<List<TripShare>>>());
    });
  });

  group('write operations', () {
    test('createShare success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.createShare(
          'trip-1',
          email: any(named: 'email'),
          message: any(named: 'message'),
          role: any(named: 'role'),
        ),
      ).thenAnswer((_) async => Success(makeTripShare()));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.createShare('trip-1', email: 'a@b.com');

      expect(result, isA<Success<TripShare>>());
      verify(
        () => mockCache.delete('trip_share_cache', 'shares:trip-1'),
      ).called(1);
    });

    test('createShare failure → does not invalidate', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.createShare(
          'trip-1',
          email: any(named: 'email'),
          message: any(named: 'message'),
          role: any(named: 'role'),
        ),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.createShare('trip-1', email: 'a@b.com');

      expect(result, isA<Failure<TripShare>>());
      verifyNever(() => mockCache.delete(any(), any()));
    });

    test('deleteShare success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.deleteShare('trip-1', 'share-1'),
      ).thenAnswer((_) async => const Success(null));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.deleteShare('trip-1', 'share-1');

      expect(result, isA<Success<void>>());
      verify(
        () => mockCache.delete('trip_share_cache', 'shares:trip-1'),
      ).called(1);
    });
  });
}
