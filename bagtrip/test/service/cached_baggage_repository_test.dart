import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/repositories/baggage_repository.dart';
import 'package:bagtrip/service/cached_baggage_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class MockBaggageRepository extends Mock implements BaggageRepository {}

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockBaggageRepository mockRemote;
  late MockCacheService mockCache;
  late MockConnectivityService mockConnectivity;
  late CachedBaggageRepository repo;

  setUpAll(() {
    registerFallbackValue(const Duration(minutes: 15));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRemote = MockBaggageRepository();
    mockCache = MockCacheService();
    mockConnectivity = MockConnectivityService();
    repo = CachedBaggageRepository(
      remote: mockRemote,
      cache: mockCache,
      connectivity: mockConnectivity,
    );
  });

  group('getByTrip', () {
    test('online + API success → caches and returns Success', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final items = [makeBaggageItem(), makeBaggageItem(id: 'bag-2')];
      when(
        () => mockRemote.getByTrip('trip-1'),
      ).thenAnswer((_) async => Success(items));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getByTrip('trip-1');

      expect(result, isA<Success<List<BaggageItem>>>());
      verify(
        () => mockCache.put('baggage_cache', 'baggage:trip-1', any()),
      ).called(1);
    });

    test('online + API failure → returns Failure, no cache write', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.getByTrip('trip-1'),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.getByTrip('trip-1');

      expect(result, isA<Failure<List<BaggageItem>>>());
      verifyNever(() => mockCache.put(any(), any(), any()));
    });

    test('offline + cache hit → returns Success from cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      final item = makeBaggageItem();
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer(
        (_) async => {
          'items': [item.toJson()],
        },
      );

      final result = await repo.getByTrip('trip-1');

      expect(result, isA<Success<List<BaggageItem>>>());
      verifyNever(() => mockRemote.getByTrip(any()));
    });

    test('offline + cache miss → returns Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getByTrip('trip-1');

      expect(result, isA<Failure<List<BaggageItem>>>());
    });
  });

  group('pass-through methods', () {
    test('suggestBaggage delegates to remote', () async {
      when(
        () => mockRemote.suggestBaggage('trip-1'),
      ).thenAnswer((_) async => const Success([]));

      await repo.suggestBaggage('trip-1');

      verify(() => mockRemote.suggestBaggage('trip-1')).called(1);
    });
  });

  group('write operations', () {
    test('createBaggageItem success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final item = makeBaggageItem();
      when(
        () => mockRemote.createBaggageItem('trip-1', name: any(named: 'name')),
      ).thenAnswer((_) async => Success(item));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.createBaggageItem('trip-1', name: 'Socks');

      expect(result, isA<Success<BaggageItem>>());
      verify(
        () => mockCache.delete('baggage_cache', 'baggage:trip-1'),
      ).called(1);
    });

    test('createBaggageItem failure → does not invalidate', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.createBaggageItem('trip-1', name: any(named: 'name')),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.createBaggageItem('trip-1', name: 'Socks');

      expect(result, isA<Failure<BaggageItem>>());
      verifyNever(() => mockCache.delete(any(), any()));
    });

    test('updateBaggageItem success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final item = makeBaggageItem();
      when(
        () => mockRemote.updateBaggageItem('trip-1', 'bag-1', any()),
      ).thenAnswer((_) async => Success(item));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.updateBaggageItem('trip-1', 'bag-1', {
        'isPacked': true,
      });

      expect(result, isA<Success<BaggageItem>>());
      verify(
        () => mockCache.delete('baggage_cache', 'baggage:trip-1'),
      ).called(1);
    });

    test('deleteBaggageItem success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.deleteBaggageItem('trip-1', 'bag-1'),
      ).thenAnswer((_) async => const Success(null));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.deleteBaggageItem('trip-1', 'bag-1');

      expect(result, isA<Success<void>>());
      verify(
        () => mockCache.delete('baggage_cache', 'baggage:trip-1'),
      ).called(1);
    });
  });
}
