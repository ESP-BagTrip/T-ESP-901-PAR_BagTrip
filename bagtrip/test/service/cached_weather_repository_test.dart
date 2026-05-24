import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:bagtrip/repositories/weather_repository.dart';
import 'package:bagtrip/service/cached_weather_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

WeatherSummary makeWeatherSummary() => const WeatherSummary(
  avgTempC: 21.5,
  minTempC: 15,
  maxTempC: 28,
  description: 'Sunny',
  rainProbability: 10,
  source: 'estimated',
);

void main() {
  late MockWeatherRepository mockRemote;
  late MockCacheService mockCache;
  late MockConnectivityService mockConnectivity;
  late CachedWeatherRepository repo;

  setUpAll(() {
    registerFallbackValue(const Duration(hours: 1));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRemote = MockWeatherRepository();
    mockCache = MockCacheService();
    mockConnectivity = MockConnectivityService();
    repo = CachedWeatherRepository(
      remote: mockRemote,
      cache: mockCache,
      connectivity: mockConnectivity,
    );
  });

  group('getWeather', () {
    test('online + API success → caches and returns Success', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final summary = makeWeatherSummary();
      when(
        () => mockRemote.getWeather('trip-1'),
      ).thenAnswer((_) async => Success(summary));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getWeather('trip-1');

      expect(result, isA<Success<WeatherSummary>>());
      verify(() => mockCache.put('weather', 'trip_trip-1', any())).called(1);
    });

    test('online + API failure → returns Failure, no cache write', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.getWeather('trip-1'),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.getWeather('trip-1');

      expect(result, isA<Failure<WeatherSummary>>());
      verifyNever(() => mockCache.put(any(), any(), any()));
    });

    test('offline + cache hit → returns Success from cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      final summary = makeWeatherSummary();
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => summary.toJson());

      final result = await repo.getWeather('trip-1');

      expect(result, isA<Success<WeatherSummary>>());
      verifyNever(() => mockRemote.getWeather(any()));
    });

    test('offline + cache miss → returns Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getWeather('trip-1');

      expect(result, isA<Failure<WeatherSummary>>());
    });
  });
}
