import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/models/flight_info.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/repositories/transport_repository.dart';

class CachedTransportRepository implements TransportRepository {
  final TransportRepository _remote;
  final CacheService _cache;
  final ConnectivityService _connectivity;
  final OfflineWriteQueue? _queue;

  static const _box = 'transport_cache';

  CachedTransportRepository({
    required TransportRepository remote,
    required CacheService cache,
    required ConnectivityService connectivity,
    OfflineWriteQueue? queue,
  }) : _remote = remote,
       _cache = cache,
       _connectivity = connectivity,
       _queue = queue {
    _registerReplayHandlers();
  }

  void _registerReplayHandlers() {
    final q = _queue;
    if (q == null) return;
    q.registerHandler('transport:createManualFlight', (args) async {
      final result = await _remote.createManualFlight(
        args['tripId'] as String,
        Map<String, dynamic>.from(args['data'] as Map),
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
    q.registerHandler('transport:updateManualFlight', (args) async {
      final result = await _remote.updateManualFlight(
        args['tripId'] as String,
        args['flightId'] as String,
        Map<String, dynamic>.from(args['data'] as Map),
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
    q.registerHandler('transport:deleteManualFlight', (args) async {
      final result = await _remote.deleteManualFlight(
        args['tripId'] as String,
        args['flightId'] as String,
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
  }

  // --------------- READ methods ---------------

  @override
  Future<Result<List<ManualFlight>>> getManualFlights(String tripId) async {
    final key = 'manual_flights:$tripId';
    if (_connectivity.isOnline) {
      final result = await _remote.getManualFlights(tripId);
      if (result case Success(:final data)) {
        await _cache.put(_box, key, {
          'items': data.map((f) => f.toJson()).toList(),
        });
      }
      return result;
    }
    final cached = await _cache.get(_box, key);
    if (cached != null) {
      final items = (cached['items'] as List)
          .map(
            (e) => ManualFlight.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      return Success(items);
    }
    return const Failure(UnknownError('No cached data available'));
  }

  // --------------- WRITE methods ---------------

  @override
  Future<Result<ManualFlight>> createManualFlight(
    String tripId,
    Map<String, dynamic> data,
  ) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'transport',
          method: 'createManualFlight',
          arguments: {'tripId': tripId, 'data': data},
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.createManualFlight(tripId, data);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<ManualFlight>> updateManualFlight(
    String tripId,
    String flightId,
    Map<String, dynamic> data,
  ) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'transport',
          method: 'updateManualFlight',
          arguments: {'tripId': tripId, 'flightId': flightId, 'data': data},
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.updateManualFlight(tripId, flightId, data);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<void>> deleteManualFlight(
    String tripId,
    String flightId,
  ) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'transport',
          method: 'deleteManualFlight',
          arguments: {'tripId': tripId, 'flightId': flightId},
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.deleteManualFlight(tripId, flightId);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  // --------------- Pass-through methods ---------------

  @override
  Future<Result<FlightInfo>> lookupFlight(String flightNumber) async {
    return _remote.lookupFlight(flightNumber);
  }

  @override
  Future<Result<List<PersistedFlightSearchResult>>> searchMultiDestFlights({
    required String tripId,
    required List<Map<String, dynamic>> segments,
    required int adults,
    int? children,
    int? infants,
    String? travelClass,
    String? currency,
  }) async {
    return _remote.searchMultiDestFlights(
      tripId: tripId,
      segments: segments,
      adults: adults,
      children: children,
      infants: infants,
      travelClass: travelClass,
      currency: currency,
    );
  }

  @override
  Future<Result<PersistedFlightSearchResult>> searchFlightsPersisted({
    required String tripId,
    required String originIata,
    required String destinationIata,
    required String departureDate,
    String? returnDate,
    required int adults,
    int? children,
    int? infants,
    String? travelClass,
    String? currency,
  }) async {
    return _remote.searchFlightsPersisted(
      tripId: tripId,
      originIata: originIata,
      destinationIata: destinationIata,
      departureDate: departureDate,
      returnDate: returnDate,
      adults: adults,
      children: children,
      infants: infants,
      travelClass: travelClass,
      currency: currency,
    );
  }

  // --------------- Helpers ---------------

  Future<void> _invalidate(String tripId) async {
    await _cache.delete(_box, 'manual_flights:$tripId');
  }
}
