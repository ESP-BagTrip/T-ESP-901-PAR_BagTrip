import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_grouped.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bagtrip/service/cached_trip_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTripRepository extends Mock implements TripRepository {}

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

Trip _makeTrip({String id = '1'}) =>
    Trip(id: id, userId: 'user1', title: 'Test Trip');

TripGrouped _makeGrouped() => const TripGrouped();

TripHome _makeTripHome() => TripHome(
  trip: _makeTrip(),
  stats: const TripHomeStats(),
  features: const [],
);

void main() {
  late MockTripRepository mockRemote;
  late MockCacheService mockCache;
  late MockConnectivityService mockConnectivity;
  late CachedTripRepository repo;

  setUpAll(() {
    registerFallbackValue(const Duration(minutes: 15));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRemote = MockTripRepository();
    mockCache = MockCacheService();
    mockConnectivity = MockConnectivityService();
    repo = CachedTripRepository(
      remote: mockRemote,
      cache: mockCache,
      connectivity: mockConnectivity,
    );
  });

  group('getGroupedTrips', () {
    test('online + API success → caches and returns Success', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final grouped = _makeGrouped();
      when(
        () => mockRemote.getGroupedTrips(),
      ).thenAnswer((_) async => Success(grouped));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getGroupedTrips();

      expect(result, isA<Success<TripGrouped>>());
      verify(
        () => mockCache.put('trips_cache', 'grouped_trips', any()),
      ).called(1);
    });

    test('online + API failure → returns Failure, no cache write', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.getGroupedTrips(),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.getGroupedTrips();

      expect(result, isA<Failure<TripGrouped>>());
      verifyNever(() => mockCache.put(any(), any(), any()));
    });

    test('offline + cache hit → returns Success from cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer(
        (_) async => {
          'ongoing': <dynamic>[],
          'planned': <dynamic>[],
          'completed': <dynamic>[],
        },
      );

      final result = await repo.getGroupedTrips();

      expect(result, isA<Success<TripGrouped>>());
      verifyNever(() => mockRemote.getGroupedTrips());
    });

    test('offline + cache miss → returns Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getGroupedTrips();

      expect(result, isA<Failure<TripGrouped>>());
    });
  });

  group('getTripById', () {
    test('online + success → caches trip', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final trip = _makeTrip();
      when(
        () => mockRemote.getTripById('1'),
      ).thenAnswer((_) async => Success(trip));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getTripById('1');

      expect(result, isA<Success<Trip>>());
      verify(() => mockCache.put('trips_cache', 'trip:1', any())).called(1);
    });

    test('offline + cache hit → returns cached trip', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => _makeTrip().toJson());

      final result = await repo.getTripById('1');

      expect(result, isA<Success<Trip>>());
    });
  });

  group('getTripHome', () {
    test('online + success → caches trip home', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final home = _makeTripHome();
      when(
        () => mockRemote.getTripHome('1'),
      ).thenAnswer((_) async => Success(home));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getTripHome('1');

      expect(result, isA<Success<TripHome>>());
      verify(
        () => mockCache.put('trips_cache', 'trip_home:1', any()),
      ).called(1);
    });
  });

  group('write operations', () {
    test('deleteTrip success → invalidates caches', () async {
      when(
        () => mockRemote.deleteTrip('1'),
      ).thenAnswer((_) async => const Success(null));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.deleteTrip('1');

      expect(result, isA<Success<void>>());
      verify(() => mockCache.delete('trips_cache', 'grouped_trips')).called(1);
      verify(() => mockCache.delete('trips_cache', 'all_trips')).called(1);
      verify(() => mockCache.delete('trips_cache', 'trip:1')).called(1);
      verify(() => mockCache.delete('trips_cache', 'trip_home:1')).called(1);
    });

    test('updateTrip success → invalidates caches', () async {
      final trip = _makeTrip();
      when(
        () => mockRemote.updateTrip('1', any()),
      ).thenAnswer((_) async => Success(trip));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.updateTrip('1', {'title': 'Updated'});

      expect(result, isA<Success<Trip>>());
      verify(() => mockCache.delete('trips_cache', 'grouped_trips')).called(1);
      verify(() => mockCache.delete('trips_cache', 'trip:1')).called(1);
    });

    test('createTrip success → invalidates list caches', () async {
      final trip = _makeTrip();
      when(
        () => mockRemote.createTrip(title: any(named: 'title')),
      ).thenAnswer((_) async => Success(trip));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.createTrip(title: 'New Trip');

      expect(result, isA<Success<Trip>>());
      verify(() => mockCache.delete('trips_cache', 'grouped_trips')).called(1);
      verify(() => mockCache.delete('trips_cache', 'all_trips')).called(1);
    });

    test('deleteTrip failure → does not invalidate caches', () async {
      when(
        () => mockRemote.deleteTrip('1'),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.deleteTrip('1');

      expect(result, isA<Failure<void>>());
      verifyNever(() => mockCache.delete(any(), any()));
    });
  });
}
