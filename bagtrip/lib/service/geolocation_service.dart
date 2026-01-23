import 'package:geolocator/geolocator.dart';

/// Exception thrown when geolocation operations fail.
class GeolocationException implements Exception {
  final String message;
  final GeolocationErrorType type;

  GeolocationException(this.message, this.type);

  @override
  String toString() => 'GeolocationException: $message';
}

/// Types of geolocation errors.
enum GeolocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

/// Service for handling device geolocation.
class GeolocationService {
  final GeolocatorPlatform _geolocator;

  GeolocationService({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  /// Checks the current location permission status.
  Future<LocationPermission> checkPermission() async {
    return await _geolocator.checkPermission();
  }

  /// Requests location permission from the user.
  Future<LocationPermission> requestPermission() async {
    return await _geolocator.requestPermission();
  }

  /// Checks if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return await _geolocator.isLocationServiceEnabled();
  }

  /// Gets the current position of the device.
  ///
  /// Throws [GeolocationException] if:
  /// - Location services are disabled
  /// - Permission is denied
  /// - Permission is permanently denied
  Future<Position> getCurrentPosition() async {
    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw GeolocationException(
        'Location services are disabled. Please enable them in settings.',
        GeolocationErrorType.serviceDisabled,
      );
    }

    // Check permission
    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw GeolocationException(
          'Location permission denied.',
          GeolocationErrorType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw GeolocationException(
        'Location permission permanently denied. Please enable it in app settings.',
        GeolocationErrorType.permissionDeniedForever,
      );
    }

    // Get current position
    try {
      return await _geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      throw GeolocationException(
        'Failed to get current position: $e',
        GeolocationErrorType.unknown,
      );
    }
  }

  /// Opens the device location settings.
  Future<bool> openLocationSettings() async {
    return await _geolocator.openLocationSettings();
  }

  /// Opens the app settings (for permission management).
  Future<bool> openAppSettings() async {
    return await _geolocator.openAppSettings();
  }
}
