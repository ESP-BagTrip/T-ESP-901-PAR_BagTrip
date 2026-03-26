import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:bagtrip/repositories/weather_repository.dart';

class CachedWeatherRepository implements WeatherRepository {
  final WeatherRepository _remote;
  final CacheService _cache;
  final ConnectivityService _connectivity;

  static const _box = 'weather';
  static const _ttl = Duration(hours: 1);

  CachedWeatherRepository({
    required WeatherRepository remote,
    required CacheService cache,
    required ConnectivityService connectivity,
  }) : _remote = remote,
       _cache = cache,
       _connectivity = connectivity;

  @override
  Future<Result<WeatherSummary>> getWeather(String tripId) async {
    final key = 'trip_$tripId';

    if (_connectivity.isOnline) {
      final result = await _remote.getWeather(tripId);
      if (result case Success(:final data)) {
        await _cache.put(_box, key, data.toJson());
      }
      return result;
    }

    final cached = await _cache.get(_box, key, ttl: _ttl);
    if (cached != null) {
      return Success(WeatherSummary.fromJson(cached));
    }
    return const Failure(UnknownError('No cached weather data available'));
  }
}
