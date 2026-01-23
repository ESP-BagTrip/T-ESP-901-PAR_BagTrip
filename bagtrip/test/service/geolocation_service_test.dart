import 'package:bagtrip/service/geolocation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'geolocation_service_test.mocks.dart';

@GenerateMocks([GeolocatorPlatform])
void main() {
  group('GeolocationService', () {
    late GeolocationService geolocationService;
    late MockGeolocatorPlatform mockGeolocator;

    setUp(() {
      mockGeolocator = MockGeolocatorPlatform();
      geolocationService = GeolocationService(geolocator: mockGeolocator);
    });

    group('checkPermission', () {
      test('should return the permission status', () async {
        when(mockGeolocator.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);

        final result = await geolocationService.checkPermission();

        expect(result, LocationPermission.whileInUse);
        verify(mockGeolocator.checkPermission()).called(1);
      });
    });

    group('requestPermission', () {
      test('should return the permission status after request', () async {
        when(mockGeolocator.requestPermission())
            .thenAnswer((_) async => LocationPermission.always);

        final result = await geolocationService.requestPermission();

        expect(result, LocationPermission.always);
        verify(mockGeolocator.requestPermission()).called(1);
      });
    });

    group('isLocationServiceEnabled', () {
      test('should return true when location services are enabled', () async {
        when(mockGeolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => true);

        final result = await geolocationService.isLocationServiceEnabled();

        expect(result, true);
        verify(mockGeolocator.isLocationServiceEnabled()).called(1);
      });

      test('should return false when location services are disabled', () async {
        when(mockGeolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => false);

        final result = await geolocationService.isLocationServiceEnabled();

        expect(result, false);
        verify(mockGeolocator.isLocationServiceEnabled()).called(1);
      });
    });

    group('getCurrentPosition', () {
      test('should return position when everything is OK', () async {
        when(mockGeolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(mockGeolocator.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(mockGeolocator.getCurrentPosition(
          locationSettings: anyNamed('locationSettings'),
        )).thenAnswer((_) async => Position(
              latitude: 48.8566,
              longitude: 2.3522,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            ));

        final result = await geolocationService.getCurrentPosition();

        expect(result.latitude, 48.8566);
        expect(result.longitude, 2.3522);
      });

      test('should throw GeolocationException when location services disabled', () async {
        when(mockGeolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => false);

        expect(
          () => geolocationService.getCurrentPosition(),
          throwsA(isA<GeolocationException>().having(
            (e) => e.type,
            'type',
            GeolocationErrorType.serviceDisabled,
          )),
        );
      });

      test('should request permission when initially denied', () async {
        when(mockGeolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(mockGeolocator.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        when(mockGeolocator.requestPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(mockGeolocator.getCurrentPosition(
          locationSettings: anyNamed('locationSettings'),
        )).thenAnswer((_) async => Position(
              latitude: 48.8566,
              longitude: 2.3522,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            ));

        final result = await geolocationService.getCurrentPosition();

        expect(result.latitude, 48.8566);
        verify(mockGeolocator.requestPermission()).called(1);
      });

      test('should throw GeolocationException when permission denied after request', () async {
        when(mockGeolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(mockGeolocator.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        when(mockGeolocator.requestPermission())
            .thenAnswer((_) async => LocationPermission.denied);

        expect(
          () => geolocationService.getCurrentPosition(),
          throwsA(isA<GeolocationException>().having(
            (e) => e.type,
            'type',
            GeolocationErrorType.permissionDenied,
          )),
        );
      });

      test('should throw GeolocationException when permission permanently denied', () async {
        when(mockGeolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(mockGeolocator.checkPermission())
            .thenAnswer((_) async => LocationPermission.deniedForever);

        expect(
          () => geolocationService.getCurrentPosition(),
          throwsA(isA<GeolocationException>().having(
            (e) => e.type,
            'type',
            GeolocationErrorType.permissionDeniedForever,
          )),
        );
      });

      test('should throw GeolocationException when getCurrentPosition fails', () async {
        when(mockGeolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(mockGeolocator.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(mockGeolocator.getCurrentPosition(
          locationSettings: anyNamed('locationSettings'),
        )).thenThrow(Exception('GPS error'));

        expect(
          () => geolocationService.getCurrentPosition(),
          throwsA(isA<GeolocationException>().having(
            (e) => e.type,
            'type',
            GeolocationErrorType.unknown,
          )),
        );
      });
    });

    group('openLocationSettings', () {
      test('should call geolocator.openLocationSettings', () async {
        when(mockGeolocator.openLocationSettings())
            .thenAnswer((_) async => true);

        final result = await geolocationService.openLocationSettings();

        expect(result, true);
        verify(mockGeolocator.openLocationSettings()).called(1);
      });
    });

    group('openAppSettings', () {
      test('should call geolocator.openAppSettings', () async {
        when(mockGeolocator.openAppSettings())
            .thenAnswer((_) async => true);

        final result = await geolocationService.openAppSettings();

        expect(result, true);
        verify(mockGeolocator.openAppSettings()).called(1);
      });
    });
  });

  group('GeolocationException', () {
    test('should have correct toString output', () {
      final exception = GeolocationException(
        'Test error message',
        GeolocationErrorType.permissionDenied,
      );

      expect(exception.toString(), 'GeolocationException: Test error message');
      expect(exception.message, 'Test error message');
      expect(exception.type, GeolocationErrorType.permissionDenied);
    });
  });
}
