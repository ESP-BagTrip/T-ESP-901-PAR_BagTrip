import 'package:bagtrip/map/bloc/map_bloc.dart';
import 'package:bagtrip/service/LocationService.dart';
import 'package:bagtrip/service/geolocation_service.dart';
import 'package:bagtrip/service/hotel_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'map_bloc_test.mocks.dart';

@GenerateMocks([GeolocatorPlatform])
void main() {
  group('MapBloc', () {
    late LocationService locationService;
    late GeolocationService geolocationService;
    late HotelService hotelService;
    late Dio dio;
    late DioAdapter dioAdapter;
    late MockGeolocatorPlatform mockGeolocator;

    setUp(() {
      dio = Dio();
      dioAdapter = DioAdapter(dio: dio);
      locationService = LocationService(dio: dio);
      hotelService = HotelService(dio: dio);
      mockGeolocator = MockGeolocatorPlatform();
      geolocationService = GeolocationService(geolocator: mockGeolocator);
    });

    tearDown(() {
      dio.close();
    });

    test('initial state should be MapInitial', () {
      final bloc = MapBloc(
        locationService: locationService,
        geolocationService: geolocationService,
        hotelService: hotelService,
      );
      expect(bloc.state, isA<MapInitial>());
      bloc.close();
    });

    group('LoadNearbyLocations', () {
      blocTest<MapBloc, MapState>(
        'loads airports when LoadNearbyLocations is called',
        build: () {
          dioAdapter.onGet(
            RegExp(r'/travel/locations/nearest'),
            (server) => server.reply(200, {
              'locations': [
                {
                  'iataCode': 'CDG',
                  'name': 'Charles de Gaulle',
                  'geoCode': {'latitude': 49.0097, 'longitude': 2.5479},
                },
              ],
            }),
          );
          return MapBloc(
            locationService: locationService,
            geolocationService: geolocationService,
            hotelService: hotelService,
          );
        },
        act: (bloc) => bloc.add(LoadNearbyLocations(latitude: 48.8566, longitude: 2.3522)),
        wait: const Duration(milliseconds: 100),
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<MapLoaded>());
        },
      );
    });

    group('GetUserLocation', () {
      blocTest<MapBloc, MapState>(
        'emits [MapLoaded with error] when location services are disabled',
        build: () {
          when(mockGeolocator.isLocationServiceEnabled())
              .thenAnswer((_) async => false);
          return MapBloc(
            locationService: locationService,
            geolocationService: geolocationService,
            hotelService: hotelService,
          );
        },
        act: (bloc) => bloc.add(GetUserLocation()),
        expect: () => [
          isA<MapLoaded>().having((s) => s.isLoading, 'isLoading', true),
          isA<MapLoaded>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.errorMessage, 'errorMessage', contains('disabled')),
        ],
      );

      blocTest<MapBloc, MapState>(
        'emits [MapLoaded with error] when permission is denied',
        build: () {
          when(mockGeolocator.isLocationServiceEnabled())
              .thenAnswer((_) async => true);
          when(mockGeolocator.checkPermission())
              .thenAnswer((_) async => LocationPermission.denied);
          when(mockGeolocator.requestPermission())
              .thenAnswer((_) async => LocationPermission.denied);
          return MapBloc(
            locationService: locationService,
            geolocationService: geolocationService,
            hotelService: hotelService,
          );
        },
        act: (bloc) => bloc.add(GetUserLocation()),
        expect: () => [
          isA<MapLoaded>().having((s) => s.isLoading, 'isLoading', true),
          isA<MapLoaded>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.errorMessage, 'errorMessage', contains('denied')),
        ],
      );

      blocTest<MapBloc, MapState>(
        'updates user location when GetUserLocation succeeds',
        build: () {
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
          dioAdapter.onGet(
            'http://localhost:3000/v1/travel/locations/nearest',
            (server) => server.reply(200, {'locations': []}),
            queryParameters: {'latitude': 48.8566, 'longitude': 2.3522},
          );
          return MapBloc(
            locationService: locationService,
            geolocationService: geolocationService,
            hotelService: hotelService,
          );
        },
        act: (bloc) => bloc.add(GetUserLocation()),
        verify: (bloc) {
          final state = bloc.state as MapLoaded;
          expect(state.userLat, 48.8566);
          expect(state.userLng, 2.3522);
        },
      );
    });

    group('SearchLocations', () {
      blocTest<MapBloc, MapState>(
        'clears search when keyword is empty',
        build: () => MapBloc(
          locationService: locationService,
          geolocationService: geolocationService,
          hotelService: hotelService,
        ),
        act: (bloc) => bloc.add(SearchLocations('')),
        expect: () => [
          isA<MapLoaded>()
              .having((s) => s.searchResults.isEmpty, 'searchResults.isEmpty', true)
              .having((s) => s.searchQuery, 'searchQuery', null),
        ],
      );

      blocTest<MapBloc, MapState>(
        'updates search results when SearchLocations succeeds',
        build: () {
          dioAdapter.onGet(
            RegExp(r'/travel/locations'),
            (server) => server.reply(200, [
              {
                'iataCode': 'CDG',
                'name': 'Charles de Gaulle',
                'subType': 'AIRPORT',
                'geoCode': {'latitude': 49.0097, 'longitude': 2.5479},
              },
            ]),
          );
          return MapBloc(
            locationService: locationService,
            geolocationService: geolocationService,
            hotelService: hotelService,
          );
        },
        act: (bloc) => bloc.add(SearchLocations('Paris')),
        wait: const Duration(milliseconds: 100),
        verify: (bloc) {
          final state = bloc.state as MapLoaded;
          expect(state.searchQuery, 'Paris');
        },
      );
    });

    group('ToggleLayer', () {
      blocTest<MapBloc, MapState>(
        'does nothing when toggling to current layer',
        build: () => MapBloc(
          locationService: locationService,
          geolocationService: geolocationService,
          hotelService: hotelService,
        ),
        act: (bloc) => bloc.add(ToggleLayer(MapLayerType.airports)),
        expect: () => [],
      );

      blocTest<MapBloc, MapState>(
        'changes active layer when toggling to different layer',
        build: () {
          dioAdapter.onPost(
            'http://localhost:3000/v1/trips/default/hotels/searches',
            (server) => server.reply(200, {'hotels': []}),
            data: Matchers.any,
          );
          return MapBloc(
            locationService: locationService,
            geolocationService: geolocationService,
            hotelService: hotelService,
          );
        },
        act: (bloc) => bloc.add(ToggleLayer(MapLayerType.hotels)),
        verify: (bloc) {
          final state = bloc.state as MapLoaded;
          expect(state.activeLayer, MapLayerType.hotels);
        },
      );
    });

    group('SelectLocation', () {
      blocTest<MapBloc, MapState>(
        'emits [MapLoaded with selected airport]',
        build: () => MapBloc(
          locationService: locationService,
          geolocationService: geolocationService,
          hotelService: hotelService,
        ),
        act: (bloc) => bloc.add(SelectLocation(
          location: {'iataCode': 'CDG', 'name': 'Charles de Gaulle'},
          type: MapLocationType.airport,
        )),
        expect: () => [
          isA<MapLoaded>()
              .having((s) => s.selectedLocation?['iataCode'], 'selectedLocation.iataCode', 'CDG')
              .having((s) => s.selectedLocationType, 'selectedLocationType', MapLocationType.airport),
        ],
      );
    });

    group('ClearSelectedLocation', () {
      blocTest<MapBloc, MapState>(
        'emits [MapLoaded with null selected location]',
        build: () => MapBloc(
          locationService: locationService,
          geolocationService: geolocationService,
          hotelService: hotelService,
        ),
        seed: () => MapLoaded(
          selectedLocation: {'iataCode': 'CDG'},
          selectedLocationType: MapLocationType.airport,
        ),
        act: (bloc) => bloc.add(ClearSelectedLocation()),
        expect: () => [
          isA<MapLoaded>()
              .having((s) => s.selectedLocation, 'selectedLocation', null)
              .having((s) => s.selectedLocationType, 'selectedLocationType', null),
        ],
      );
    });

    group('NavigateToLocation', () {
      blocTest<MapBloc, MapState>(
        'updates center coordinates when navigating',
        build: () {
          dioAdapter.onGet(
            'http://localhost:3000/v1/travel/locations/nearest',
            (server) => server.reply(200, {'locations': []}),
            queryParameters: {'latitude': 51.5074, 'longitude': -0.1278},
          );
          return MapBloc(
            locationService: locationService,
            geolocationService: geolocationService,
            hotelService: hotelService,
          );
        },
        act: (bloc) => bloc.add(NavigateToLocation(
          latitude: 51.5074,
          longitude: -0.1278,
          zoom: 12.0,
        )),
        verify: (bloc) {
          final state = bloc.state as MapLoaded;
          expect(state.centerLat, 51.5074);
          expect(state.centerLng, -0.1278);
        },
      );
    });

    group('SetHotelDates', () {
      blocTest<MapBloc, MapState>(
        'updates hotel dates',
        build: () => MapBloc(
          locationService: locationService,
          geolocationService: geolocationService,
          hotelService: hotelService,
        ),
        act: (bloc) => bloc.add(SetHotelDates(
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 17),
        )),
        expect: () => [
          isA<MapLoaded>()
              .having((s) => s.hotelCheckIn, 'hotelCheckIn', DateTime(2024, 1, 15))
              .having((s) => s.hotelCheckOut, 'hotelCheckOut', DateTime(2024, 1, 17)),
        ],
      );
    });

    group('ClearError', () {
      blocTest<MapBloc, MapState>(
        'clears error message',
        build: () => MapBloc(
          locationService: locationService,
          geolocationService: geolocationService,
          hotelService: hotelService,
        ),
        seed: () => MapLoaded(errorMessage: 'Test error'),
        act: (bloc) => bloc.add(ClearError()),
        expect: () => [
          isA<MapLoaded>().having((s) => s.errorMessage, 'errorMessage', null),
        ],
      );
    });
  });
}
