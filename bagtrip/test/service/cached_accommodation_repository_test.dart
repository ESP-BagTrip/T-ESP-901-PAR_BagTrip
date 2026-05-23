import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';
import 'package:bagtrip/service/cached_accommodation_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class MockAccommodationRepository extends Mock
    implements AccommodationRepository {}

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockAccommodationRepository mockRemote;
  late MockCacheService mockCache;
  late MockConnectivityService mockConnectivity;
  late CachedAccommodationRepository repo;

  setUpAll(() {
    registerFallbackValue(const Duration(minutes: 15));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRemote = MockAccommodationRepository();
    mockCache = MockCacheService();
    mockConnectivity = MockConnectivityService();
    repo = CachedAccommodationRepository(
      remote: mockRemote,
      cache: mockCache,
      connectivity: mockConnectivity,
    );
  });

  group('getByTrip', () {
    test('online + API success → caches and returns Success', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final items = [makeAccommodation(), makeAccommodation(id: 'acc-2')];
      when(
        () => mockRemote.getByTrip('trip-1'),
      ).thenAnswer((_) async => Success(items));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getByTrip('trip-1');

      expect(result, isA<Success<List<Accommodation>>>());
      verify(
        () => mockCache.put(
          'accommodation_cache',
          'accommodations:trip-1',
          any(),
        ),
      ).called(1);
    });

    test('online + API failure → returns Failure, no cache write', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.getByTrip('trip-1'),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.getByTrip('trip-1');

      expect(result, isA<Failure<List<Accommodation>>>());
      verifyNever(() => mockCache.put(any(), any(), any()));
    });

    test('offline + cache hit → returns Success from cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      final item = makeAccommodation();
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer(
        (_) async => {
          'items': [item.toJson()],
        },
      );

      final result = await repo.getByTrip('trip-1');

      expect(result, isA<Success<List<Accommodation>>>());
      verifyNever(() => mockRemote.getByTrip(any()));
    });

    test('offline + cache miss → returns Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getByTrip('trip-1');

      expect(result, isA<Failure<List<Accommodation>>>());
    });
  });

  group('pass-through methods', () {
    test('suggestAccommodations delegates to remote', () async {
      when(
        () => mockRemote.suggestAccommodations(
          'trip-1',
          constraints: any(named: 'constraints'),
        ),
      ).thenAnswer((_) async => const Success([]));

      await repo.suggestAccommodations('trip-1');

      verify(
        () => mockRemote.suggestAccommodations(
          'trip-1',
          constraints: any(named: 'constraints'),
        ),
      ).called(1);
    });

    test('searchHotelsByCity delegates to remote', () async {
      when(
        () => mockRemote.searchHotelsByCity('PAR'),
      ).thenAnswer((_) async => const Success([]));

      await repo.searchHotelsByCity('PAR');

      verify(() => mockRemote.searchHotelsByCity('PAR')).called(1);
    });

    test('searchHotelOffers delegates to remote', () async {
      when(
        () => mockRemote.searchHotelOffers('H1'),
      ).thenAnswer((_) async => const Success([]));

      await repo.searchHotelOffers('H1');

      verify(() => mockRemote.searchHotelOffers('H1')).called(1);
    });
  });

  group('write operations', () {
    test('createAccommodation success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final item = makeAccommodation();
      when(
        () =>
            mockRemote.createAccommodation('trip-1', name: any(named: 'name')),
      ).thenAnswer((_) async => Success(item));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.createAccommodation('trip-1', name: 'Hotel');

      expect(result, isA<Success<Accommodation>>());
      verify(
        () => mockCache.delete('accommodation_cache', 'accommodations:trip-1'),
      ).called(1);
    });

    test('createAccommodation failure → does not invalidate', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () =>
            mockRemote.createAccommodation('trip-1', name: any(named: 'name')),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.createAccommodation('trip-1', name: 'Hotel');

      expect(result, isA<Failure<Accommodation>>());
      verifyNever(() => mockCache.delete(any(), any()));
    });

    test('updateAccommodation success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final item = makeAccommodation();
      when(
        () => mockRemote.updateAccommodation('trip-1', 'acc-1', any()),
      ).thenAnswer((_) async => Success(item));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.updateAccommodation('trip-1', 'acc-1', {
        'name': 'New',
      });

      expect(result, isA<Success<Accommodation>>());
      verify(
        () => mockCache.delete('accommodation_cache', 'accommodations:trip-1'),
      ).called(1);
    });

    test('deleteAccommodation success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.deleteAccommodation('trip-1', 'acc-1'),
      ).thenAnswer((_) async => const Success(null));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.deleteAccommodation('trip-1', 'acc-1');

      expect(result, isA<Success<void>>());
      verify(
        () => mockCache.delete('accommodation_cache', 'accommodations:trip-1'),
      ).called(1);
    });
  });
}
