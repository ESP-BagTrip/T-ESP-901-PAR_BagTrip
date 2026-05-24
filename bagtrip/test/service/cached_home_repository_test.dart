import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/home_summary.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/repositories/home_repository.dart';
import 'package:bagtrip/service/cached_home_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class _MockHomeRepository extends Mock implements HomeRepository {}

class _MockCacheService extends Mock implements CacheService {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late _MockHomeRepository mockRemote;
  late _MockCacheService mockCache;
  late _MockConnectivityService mockConnectivity;
  late CachedHomeRepository repo;

  setUpAll(() {
    registerFallbackValue(const Duration(hours: 1));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRemote = _MockHomeRepository();
    mockCache = _MockCacheService();
    mockConnectivity = _MockConnectivityService();
    repo = CachedHomeRepository(
      remote: mockRemote,
      cache: mockCache,
      connectivity: mockConnectivity,
    );
  });

  group('getHome', () {
    test('online + API success → caches and returns Success', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final summary = makeHomeSummary(
        ongoingTrips: [makeTrip(id: 't1', status: TripStatus.ongoing)],
      );
      when(
        () => mockRemote.getHome(),
      ).thenAnswer((_) async => Success(summary));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getHome();

      expect(result, isA<Success<HomeSummary>>());
      verify(
        () => mockCache.put('home_cache', 'home:summary', any()),
      ).called(1);
    });

    test(
      'online + API failure with cached summary → returns cached Success',
      () async {
        when(() => mockConnectivity.isOnline).thenReturn(true);
        when(
          () => mockRemote.getHome(),
        ).thenAnswer((_) async => const Failure(ServerError('flaky')));
        when(
          () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
        ).thenAnswer((_) async => makeHomeSummary().toJson());

        final result = await repo.getHome();

        expect(result, isA<Success<HomeSummary>>());
        verifyNever(() => mockCache.put(any(), any(), any()));
      },
    );

    test('online + API failure with no cache → bubbles the Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.getHome(),
      ).thenAnswer((_) async => const Failure(ServerError('down')));
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getHome();

      expect(result, isA<Failure<HomeSummary>>());
    });

    test('offline + cache hit → returns Success from cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => makeHomeSummary().toJson());

      final result = await repo.getHome();

      expect(result, isA<Success<HomeSummary>>());
      verifyNever(() => mockRemote.getHome());
    });

    test('offline + cache miss → returns Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getHome();

      expect(result, isA<Failure<HomeSummary>>());
    });
  });
}
