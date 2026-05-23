import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/repositories/transport_repository.dart';
import 'package:bagtrip/service/cached_transport_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class MockTransportRepository extends Mock implements TransportRepository {}

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockTransportRepository mockRemote;
  late MockCacheService mockCache;
  late MockConnectivityService mockConnectivity;
  late CachedTransportRepository repo;

  setUpAll(() {
    registerFallbackValue(const Duration(minutes: 15));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRemote = MockTransportRepository();
    mockCache = MockCacheService();
    mockConnectivity = MockConnectivityService();
    repo = CachedTransportRepository(
      remote: mockRemote,
      cache: mockCache,
      connectivity: mockConnectivity,
    );
  });

  group('getManualFlights', () {
    test('online + API success → caches and returns Success', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final items = [makeManualFlight(), makeManualFlight(id: 'flight-2')];
      when(
        () => mockRemote.getManualFlights('trip-1'),
      ).thenAnswer((_) async => Success(items));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getManualFlights('trip-1');

      expect(result, isA<Success<List<ManualFlight>>>());
      verify(
        () => mockCache.put('transport_cache', 'manual_flights:trip-1', any()),
      ).called(1);
    });

    test('online + API failure → returns Failure, no cache write', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.getManualFlights('trip-1'),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.getManualFlights('trip-1');

      expect(result, isA<Failure<List<ManualFlight>>>());
      verifyNever(() => mockCache.put(any(), any(), any()));
    });

    test('offline + cache hit → returns Success from cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer(
        (_) async => {
          'items': [makeManualFlight().toJson()],
        },
      );

      final result = await repo.getManualFlights('trip-1');

      expect(result, isA<Success<List<ManualFlight>>>());
      verifyNever(() => mockRemote.getManualFlights(any()));
    });

    test('offline + cache miss → returns Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getManualFlights('trip-1');

      expect(result, isA<Failure<List<ManualFlight>>>());
    });
  });

  group('pass-through methods', () {
    test('lookupFlight delegates to remote', () async {
      when(
        () => mockRemote.lookupFlight('AF123'),
      ).thenAnswer((_) async => Success(makeFlightInfo()));

      await repo.lookupFlight('AF123');

      verify(() => mockRemote.lookupFlight('AF123')).called(1);
    });
  });

  group('write operations', () {
    test('createManualFlight success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.createManualFlight('trip-1', any()),
      ).thenAnswer((_) async => Success(makeManualFlight()));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.createManualFlight('trip-1', {
        'flightNumber': 'AF123',
      });

      expect(result, isA<Success<ManualFlight>>());
      verify(
        () => mockCache.delete('transport_cache', 'manual_flights:trip-1'),
      ).called(1);
    });

    test('createManualFlight failure → does not invalidate', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.createManualFlight('trip-1', any()),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.createManualFlight('trip-1', {
        'flightNumber': 'AF123',
      });

      expect(result, isA<Failure<ManualFlight>>());
      verifyNever(() => mockCache.delete(any(), any()));
    });

    test('updateManualFlight success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.updateManualFlight('trip-1', 'flight-1', any()),
      ).thenAnswer((_) async => Success(makeManualFlight()));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.updateManualFlight('trip-1', 'flight-1', {
        'airline': 'AF',
      });

      expect(result, isA<Success<ManualFlight>>());
      verify(
        () => mockCache.delete('transport_cache', 'manual_flights:trip-1'),
      ).called(1);
    });

    test('deleteManualFlight success → invalidates cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.deleteManualFlight('trip-1', 'flight-1'),
      ).thenAnswer((_) async => const Success(null));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.deleteManualFlight('trip-1', 'flight-1');

      expect(result, isA<Success<void>>());
      verify(
        () => mockCache.delete('transport_cache', 'manual_flights:trip-1'),
      ).called(1);
    });
  });
}
