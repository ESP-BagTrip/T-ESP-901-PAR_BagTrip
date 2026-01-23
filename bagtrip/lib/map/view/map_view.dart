import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/map/bloc/map_bloc.dart';
import 'package:bagtrip/map/widgets/map_hotel_bottom_sheet.dart';
import 'package:bagtrip/map/widgets/map_layer_toggle.dart';
import 'package:bagtrip/map/widgets/map_location_bottom_sheet.dart';
import 'package:bagtrip/map/widgets/map_location_search_bar.dart';
import 'package:bagtrip/service/hotel_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MapBloc, MapState>(
      listener: (context, state) {
        if (state is MapLoaded) {
          // Handle navigation requests
          if (state.shouldNavigate) {
            _mapController.move(
              LatLng(state.centerLat, state.centerLng),
              state.zoom,
            );
          }

          // Show error snackbar
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: ColorName.error,
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<MapBloc>().add(ClearError());
                  },
                ),
              ),
            );
          }

          // Show bottom sheet for selected location
          if (state.selectedLocation != null && state.selectedLocationType != null) {
            _showLocationBottomSheet(context, state);
          }
        }
      },
      builder: (context, state) {
        if (state is MapInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MapError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: ColorName.error),
                const SizedBox(height: AppSpacing.space16),
                Text(state.message),
                const SizedBox(height: AppSpacing.space16),
                ElevatedButton(
                  onPressed: () {
                    context.read<MapBloc>().add(LoadNearbyLocations(
                      latitude: 48.8566,
                      longitude: 2.3522,
                    ));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final loadedState = state as MapLoaded;
        final markers = _buildMarkers(context, loadedState);

        return Scaffold(
          body: Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(loadedState.centerLat, loadedState.centerLng),
                  initialZoom: loadedState.zoom,
                  onPositionChanged: (camera, hasGesture) {
                    if (hasGesture) {
                      context.read<MapBloc>().add(MapCameraMoved(
                        latitude: camera.center.latitude,
                        longitude: camera.center.longitude,
                        zoom: camera.zoom,
                      ));
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.epitech.bagtrip',
                  ),
                  // User location marker
                  if (loadedState.userLat != null && loadedState.userLng != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(loadedState.userLat!, loadedState.userLng!),
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorName.info.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: ColorName.info, width: 3),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: ColorName.info,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Location markers with clustering
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(40, 40),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      markers: markers,
                      builder: (context, clusterMarkers) {
                        final isHotelLayer = loadedState.activeLayer == MapLayerType.hotels;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isHotelLayer ? ColorName.secondary : ColorName.primary,
                          ),
                          child: Center(
                            child: Text(
                              clusterMarkers.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),

              // Search bar (top)
              const Positioned(
                top: 50,
                left: AppSpacing.space16,
                right: AppSpacing.space16,
                child: MapLocationSearchBar(),
              ),

              // Layer toggle (right side)
              Positioned(
                top: 120,
                right: AppSpacing.space16,
                child: MapLayerToggle(
                  activeLayer: loadedState.activeLayer,
                  onLayerChanged: (layer) {
                    context.read<MapBloc>().add(ToggleLayer(layer));
                  },
                ),
              ),

              // Loading indicator
              if (loadedState.isLoading)
                const Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: AppSpacing.allEdgeInsetSpace8,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                ),

              // My Location FAB (bottom-right)
              Positioned(
                bottom: AppSpacing.space24,
                right: AppSpacing.space16,
                child: FloatingActionButton(
                  heroTag: 'myLocation',
                  onPressed: () {
                    context.read<MapBloc>().add(GetUserLocation());
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: ColorName.primary,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Marker> _buildMarkers(BuildContext context, MapLoaded state) {
    if (state.activeLayer == MapLayerType.airports) {
      return _buildAirportMarkers(context, state.airportMarkers);
    } else {
      return _buildHotelMarkers(context, state.hotelMarkers);
    }
  }

  List<Marker> _buildAirportMarkers(BuildContext context, List<Map<String, dynamic>> airports) {
    return airports.map((airport) {
      final geoCode = airport['geoCode'] as Map<String, dynamic>?;
      if (geoCode == null) return null;

      final lat = geoCode['latitude'] as double?;
      final lng = geoCode['longitude'] as double?;
      if (lat == null || lng == null) return null;

      return Marker(
        point: LatLng(lat, lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            context.read<MapBloc>().add(SelectLocation(
              location: airport,
              type: MapLocationType.airport,
            ));
          },
          child: Container(
            decoration: const BoxDecoration(
              color: ColorName.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_airport,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  List<Marker> _buildHotelMarkers(BuildContext context, List<Hotel> hotels) {
    return hotels.map((hotel) {
      if (hotel.latitude == null || hotel.longitude == null) return null;

      return Marker(
        point: LatLng(hotel.latitude!, hotel.longitude!),
        width: 70,
        height: 36,
        child: GestureDetector(
          onTap: () {
            context.read<MapBloc>().add(SelectLocation(
              location: hotel.toJson(),
              type: MapLocationType.hotel,
            ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ColorName.secondary,
              borderRadius: AppRadius.medium8,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hotel,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  hotel.pricePerNight != null
                      ? '${hotel.pricePerNight!.toInt()}€'
                      : '---',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  void _showLocationBottomSheet(BuildContext context, MapLoaded state) {
    final blocContext = context;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cornerRaidus16)),
      ),
      builder: (sheetContext) {
        if (state.selectedLocationType == MapLocationType.airport) {
          return MapLocationBottomSheet(
            location: state.selectedLocation!,
            onClose: () {
              Navigator.pop(sheetContext);
              blocContext.read<MapBloc>().add(ClearSelectedLocation());
            },
          );
        } else {
          return MapHotelBottomSheet(
            hotel: Hotel.fromJson(state.selectedLocation!),
            onClose: () {
              Navigator.pop(sheetContext);
              blocContext.read<MapBloc>().add(ClearSelectedLocation());
            },
          );
        }
      },
    ).whenComplete(() {
      if (mounted) {
        blocContext.read<MapBloc>().add(ClearSelectedLocation());
      }
    });
  }
}
