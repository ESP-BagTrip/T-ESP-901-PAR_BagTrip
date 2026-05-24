import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/home_summary.dart';
import 'package:bagtrip/repositories/home_repository.dart';

/// Wraps the remote [HomeRepository] with a Hive-backed cache so the home
/// screen survives offline (SMP327-021).
///
/// Online: read from network, write the fresh [HomeSummary] to cache.
/// Offline: serve the last cached summary. Cache reads disable the TTL so the
/// home always renders the last-known snapshot rather than an empty/error
/// state when the user reopens the app without connectivity.
class CachedHomeRepository implements HomeRepository {
  final HomeRepository _remote;
  final CacheService _cache;
  final ConnectivityService _connectivity;

  static const _box = 'home_cache';
  static const _key = 'home:summary';

  CachedHomeRepository({
    required HomeRepository remote,
    required CacheService cache,
    required ConnectivityService connectivity,
  }) : _remote = remote,
       _cache = cache,
       _connectivity = connectivity;

  @override
  Future<Result<HomeSummary>> getHome() async {
    if (_connectivity.isOnline) {
      final result = await _remote.getHome();
      if (result case Success(:final data)) {
        await _cache.put(_box, _key, data.toJson());
      } else {
        // Network read failed while "online" (e.g. flaky link / timeout):
        // fall back to the cached summary if we have one rather than bubbling
        // the error straight to the home screen.
        final cached = await _cache.get(_box, _key, ttl: null);
        if (cached != null) {
          return Success(HomeSummary.fromJson(cached));
        }
      }
      return result;
    }

    final cached = await _cache.get(_box, _key, ttl: null);
    if (cached != null) {
      return Success(HomeSummary.fromJson(cached));
    }
    return const Failure(UnknownError('No cached home data available'));
  }
}
