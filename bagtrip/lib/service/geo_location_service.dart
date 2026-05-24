import 'dart:developer' as developer;

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:geolocator/geolocator.dart';

/// Resolves the user's current city from device GPS + the nearest-location API.
class GeoLocationService {
  final LocationService _locationService;

  GeoLocationService({required LocationService locationService})
    : _locationService = locationService;

  /// Returns the nearest city to the user's current position.
  ///
  /// Requests location permission if needed. Returns [Failure] silently
  /// if permission is denied or location services are disabled — the caller
  /// should treat this as "no pre-fill" rather than a blocking error.
  Future<Result<LocationResult>> getNearestCity() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return loggedFailure(const UnknownError('Location services disabled'));
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return loggedFailure(const UnknownError('Location permission denied'));
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return _resolveNearest(position.latitude, position.longitude);
    } catch (e, stack) {
      developer.log(
        'GeoLocationService.getNearestCity failed',
        name: 'GeoLocationService',
        error: e,
        stackTrace: stack,
      );
      return loggedFailure(
        UnknownError('Geolocation failed: $e', originalError: e),
      );
    }
  }

  Future<Result<LocationResult>> _resolveNearest(double lat, double lon) async {
    try {
      final result = await _locationService.searchNearestLocations(lat, lon);
      if (result case Success(:final data)) {
        if (data.isEmpty) {
          return loggedFailure(const UnknownError('No nearby locations found'));
        }
        final nearest = data.first;
        return Success(
          LocationResult(
            name:
                nearest['city'] as String? ?? nearest['name'] as String? ?? '',
            iataCode: nearest['iataCode'] as String? ?? '',
            city: nearest['city'] as String? ?? '',
            countryCode: nearest['countryCode'] as String? ?? '',
            countryName: nearest['countryName'] as String? ?? '',
            subType: 'CITY',
          ),
        );
      }
      return loggedFailure(
        const UnknownError('Failed to resolve nearest location'),
      );
    } catch (e) {
      return loggedFailure(
        UnknownError('Nearest location lookup failed: $e', originalError: e),
      );
    }
  }
}
