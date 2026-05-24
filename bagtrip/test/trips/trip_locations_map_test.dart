// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trips/view/trip_locations_page.dart';
import 'package:bagtrip/trips/widgets/trip_locations_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../helpers/test_fixtures.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );
  }

  // Synthetic coordinates: the API models do not (yet) carry lat/lng, so the
  // widget is exercised with fabricated test points only.
  List<MapLocation> fakeLocations() => [
    const MapLocation(
      latitude: 48.8584,
      longitude: 2.2945,
      title: 'Eiffel Tower',
      subtitle: 'Champ de Mars',
      kind: MapLocationKind.activity,
      icon: Icons.museum_outlined,
      color: AppColors.activityCulture,
    ),
    const MapLocation(
      latitude: 48.8606,
      longitude: 2.3376,
      title: 'Hotel du Louvre',
      subtitle: 'Place du Palais Royal',
      kind: MapLocationKind.accommodation,
      icon: Icons.hotel_rounded,
      color: AppColors.primary,
    ),
  ];

  testWidgets('renders a FlutterMap with one Marker per location', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(child: TripLocationsMap(locations: fakeLocations())),
    );
    await tester.pump();

    expect(find.byType(FlutterMap), findsOneWidget);

    final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers, hasLength(2));
  });

  testWidgets('renders an OSM tile layer', (tester) async {
    await tester.pumpWidget(
      buildApp(child: TripLocationsMap(locations: fakeLocations())),
    );
    await tester.pump();

    final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(
      tileLayer.urlTemplate,
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
  });

  testWidgets('renders fallback map with no markers when locations empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(child: const TripLocationsMap(locations: [])),
    );
    await tester.pump();

    expect(find.byType(FlutterMap), findsOneWidget);
    final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers, isEmpty);
  });

  testWidgets('centers on fallbackCenter when provided and no locations', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        child: const TripLocationsMap(
          locations: [],
          fallbackCenter: LatLng(35.6762, 139.6503),
        ),
      ),
    );
    await tester.pump();

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter, const LatLng(35.6762, 139.6503));
  });

  testWidgets('tapping a marker opens a sheet with the location name', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(child: TripLocationsMap(locations: fakeLocations())),
    );
    await tester.pump();

    // Tap the first marker's gesture detector.
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();

    expect(find.text('Eiffel Tower'), findsOneWidget);
  });

  group('buildMapLocations', () {
    test('emits a destination marker when trip has coordinates', () {
      final trip = makeTrip(
        destinationName: 'Paris',
        destinationLatitude: 49.0097,
        destinationLongitude: 2.5479,
      );

      final locations = buildMapLocations(
        trip: trip,
        activities: const [],
        accommodations: const [],
      );

      expect(locations, hasLength(1));
      final marker = locations.single;
      expect(marker.kind, MapLocationKind.destination);
      expect(marker.title, 'Paris');
      expect(marker.point, const LatLng(49.0097, 2.5479));
    });

    test('emits no marker when trip has no destination coordinates', () {
      final trip = makeTrip();

      final locations = buildMapLocations(
        trip: trip,
        activities: const [],
        accommodations: const [],
      );

      expect(locations, isEmpty);
    });

    test('emits no marker when trip is null', () {
      final locations = buildMapLocations(
        trip: null,
        activities: const [],
        accommodations: const [],
      );

      expect(locations, isEmpty);
    });
  });

  testWidgets('centers on the destination marker when present', (tester) async {
    final destination = buildMapLocations(
      trip: makeTrip(
        destinationName: 'Paris',
        destinationLatitude: 49.0097,
        destinationLongitude: 2.5479,
      ),
      activities: const [],
      accommodations: const [],
    );

    await tester.pumpWidget(
      buildApp(child: TripLocationsMap(locations: destination)),
    );
    await tester.pump();

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter, const LatLng(49.0097, 2.5479));
    final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers, hasLength(1));
  });
}
