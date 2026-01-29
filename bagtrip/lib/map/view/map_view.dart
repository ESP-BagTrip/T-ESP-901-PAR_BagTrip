import 'dart:convert';
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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  MapboxMap? _mapboxMap;
  MapLayerType? _lastActiveLayer;
  
  // Sources and Layers IDs
  static const String _sourceId = "locations-source";
  static const String _clusterLayerId = "clusters-layer";
  static const String _clusterCountLayerId = "cluster-count-layer";
  static const String _unclusteredLayerId = "unclustered-point-layer";

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MapBloc, MapState>(
      listener: (context, state) {
        if (state is MapLoaded) {
          _handleNavigation(state);
          _handleErrors(context, state);
          _handleSelection(context, state);
          _updateMapData(state);
        }
      },
      builder: (context, state) {
        if (state is MapInitial) {
          return const Center(child: CircularProgressIndicator(color: ColorName.primary));
        }

        if (state is MapError) {
          return _buildErrorView(context, state);
        }

        final loadedState = state as MapLoaded;

        return Scaffold(
          body: Stack(
            children: [
              _buildMap(loadedState),
              
              // Overlays
              const Positioned(
                top: AppSpacing.space8,
                left: AppSpacing.space16,
                right: AppSpacing.space16,
                child: SafeArea(child: MapLocationSearchBar()),
              ),
              
              Positioned(
                top: 90,
                right: AppSpacing.space16,
                child: SafeArea(
                  child: MapLayerToggle(
                    activeLayer: loadedState.activeLayer,
                    onLayerChanged: (layer) {
                      context.read<MapBloc>().add(ToggleLayer(layer));
                    },
                  ),
                ),
              ),

              if (loadedState.isLoading)
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: SafeArea(child: _buildLoadingIndicator()),
                ),

              Positioned(
                bottom: AppSpacing.space24,
                right: AppSpacing.space16,
                child: SafeArea(child: _buildMyLocationFab(context)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(MapLoaded state) {
    return MapWidget(
      resourceOptions: ResourceOptions(
        accessToken: dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
      ),
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(state.centerLng, state.centerLat)).toJson(),
        zoom: state.zoom,
      ),
      styleUri: MapboxStyles.OUTDOORS,
      onMapCreated: _onMapCreated,
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    
    // Setup listeners
    _mapboxMap?.gestures.addOnMapClickListener(
      (point) {
        _handleMapClick(point);
        return true; 
      } // Consumed
    );
    
    _mapboxMap?.gestures.addOnCameraChangeListener(
      (event) {
        _handleCameraChange();
      }
    );

    // Initial data load if state is already ready
    final state = context.read<MapBloc>().state;
    if (state is MapLoaded) {
      _updateMapData(state);
    }
  }

  Future<void> _handleCameraChange() async {
    if (_mapboxMap == null) return;
    
    final cameraState = await _mapboxMap!.getCameraState();
    final center = cameraState.center;
    final zoom = cameraState.zoom;
    
    if (center != null && mounted) {
      context.read<MapBloc>().add(MapCameraMoved(
        latitude: center.coordinates.lat.toDouble(),
        longitude: center.coordinates.lng.toDouble(),
        zoom: zoom,
      ));
    }
  }

  Future<void> _handleMapClick(Point point) async {
    if (_mapboxMap == null) return;

    final features = await _mapboxMap!.queryRenderedFeatures(
      RenderedQueryGeometry.fromPoint(point),
      RenderedQueryOptions(
        layers: [_unclusteredLayerId],
      ),
    );

    if (features.isNotEmpty) {
      final feature = features.first;
      final properties = feature.queriedFeature.feature['properties'];
      
      if (properties != null) {
        final state = context.read<MapBloc>().state;
        if (state is MapLoaded) {
          if (state.activeLayer == MapLayerType.airports) {
            final airportData = jsonDecode(properties['data']);
            context.read<MapBloc>().add(SelectLocation(
              location: airportData,
              type: MapLocationType.airport,
            ));
          } else {
             final hotelData = jsonDecode(properties['data']);
             context.read<MapBloc>().add(SelectLocation(
               location: hotelData,
               type: MapLocationType.hotel,
             ));
          }
        }
      }
    }
  }

  Future<void> _updateMapData(MapLoaded state) async {
    if (_mapboxMap == null) return;

    // Check if layer type changed to clear/reset styles if needed
    // But GeoJSON update handles it mostly.
    
    final isAirport = state.activeLayer == MapLayerType.airports;
    final color = isAirport ? ColorName.primary : ColorName.secondary;
    final colorHex = '#${color.value.toRadixString(16).substring(2)}'; // ARGB -> RGB

    // Prepare FeatureCollection
    final features = <Map<String, dynamic>>[];
    
    if (isAirport) {
      for (var airport in state.airportMarkers) {
         final geoCode = airport['geoCode'] as Map<String, dynamic>?;
         final lat = _parseDouble(geoCode?['latitude'] ?? airport['latitude']);
         final lng = _parseDouble(geoCode?['longitude'] ?? airport['longitude']);
         
         if (lat != null && lng != null) {
           features.add({
             "type": "Feature",
             "geometry": {
               "type": "Point",
               "coordinates": [lng, lat]
             },
             "properties": {
               "data": jsonEncode(airport)
             }
           });
         }
      }
    } else {
      for (var hotel in state.hotelMarkers) {
        if (hotel.latitude != null && hotel.longitude != null) {
          features.add({
             "type": "Feature",
             "geometry": {
               "type": "Point",
               "coordinates": [hotel.longitude, hotel.latitude]
             },
             "properties": {
               "data": jsonEncode(hotel.toJson()),
               "price": hotel.pricePerNight?.toInt().toString() ?? ""
             }
           });
        }
      }
    }

    final geoJson = {
      "type": "FeatureCollection",
      "features": features
    };

    // Update Source
    if (await _mapboxMap!.style.styleSourceExists(_sourceId)) {
      final source = await _mapboxMap!.style.getSource(_sourceId);
      if (source is GeoJsonSource) {
         await source.updateGeoJSON(jsonEncode(geoJson));
      }
    } else {
      await _mapboxMap!.style.addSource(
        GeoJsonSource(
          id: _sourceId,
          data: jsonEncode(geoJson),
          cluster: true,
          clusterRadius: 50,
        )
      );
    }

    // Update Layers if needed (or add them if missing)
    if (!await _mapboxMap!.style.styleLayerExists(_unclusteredLayerId)) {
       await _setupLayers(colorHex);
    } else if (_lastActiveLayer != state.activeLayer) {
       // Update layer colors if type changed
       await _updateLayerColors(colorHex);
    }
    
    _lastActiveLayer = state.activeLayer;
  }

  Future<void> _setupLayers(String colorHex) async {
    if (_mapboxMap == null) return;

    // Clusters (Circles)
    await _mapboxMap!.style.addLayer(
      CircleLayer(
        id: _clusterLayerId,
        sourceId: _sourceId,
        filter: jsonEncode(["has", "point_count"]),
        circleColor: Colors.white.value, 
        circleRadius: 20.0,
        circleStrokeWidth: 2.0,
        circleStrokeColor: int.parse(colorHex.replaceAll('#', '0xFF')), 
      )
    );

    // Cluster Counts (Text)
    await _mapboxMap!.style.addLayer(
      SymbolLayer(
        id: _clusterCountLayerId,
        sourceId: _sourceId,
        filter: jsonEncode(["has", "point_count"]),
        textField: "{point_count_abbreviated}",
        textSize: 12.0,
        textColor: Colors.black.value,
      )
    );

    // Unclustered Points (Individual locations)
    await _mapboxMap!.style.addLayer(
      CircleLayer(
        id: _unclusteredLayerId,
        sourceId: _sourceId,
        filter: jsonEncode(["!", ["has", "point_count"]]),
        circleColor: int.parse(colorHex.replaceAll('#', '0xFF')),
        circleRadius: 10.0,
        circleStrokeWidth: 2.0,
        circleStrokeColor: Colors.white.value,
      )
    );
  }

  Future<void> _updateLayerColors(String colorHex) async {
    if (_mapboxMap == null) return;
    
    final colorInt = int.parse(colorHex.replaceAll('#', '0xFF'));
    
    final clusterLayer = await _mapboxMap!.style.getLayer(_clusterLayerId) as CircleLayer?;
    if (clusterLayer != null) {
      await _mapboxMap!.style.updateLayer(
        clusterLayer.copyWith(
          circleStrokeColor: colorInt,
        )
      );
    }

    final pointLayer = await _mapboxMap!.style.getLayer(_unclusteredLayerId) as CircleLayer?;
    if (pointLayer != null) {
      await _mapboxMap!.style.updateLayer(
        pointLayer.copyWith(
          circleColor: colorInt,
        )
      );
    }
  }

  void _handleNavigation(MapLoaded state) {
    if (state.shouldNavigate && _mapboxMap != null) {
      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(state.centerLng, state.centerLat)).toJson(),
          zoom: state.zoom,
        ),
        MapAnimationOptions(duration: 1000)
      );
    }
  }

  void _handleErrors(BuildContext context, MapLoaded state) {
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: ColorName.error,
          behavior: SnackBarBehavior.floating,
          margin: AppSpacing.allEdgeInsetSpace16,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () => context.read<MapBloc>().add(ClearError()),
          ),
        ),
      );
    }
  }

  void _handleSelection(BuildContext context, MapLoaded state) {
    if (state.selectedLocation != null && state.selectedLocationType != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.cornerRaidus16),
              ),
            ),
            child: state.selectedLocationType == MapLocationType.airport
                ? MapLocationBottomSheet(
                    location: state.selectedLocation!,
                    onClose: () {
                      Navigator.pop(sheetContext);
                      context.read<MapBloc>().add(ClearSelectedLocation());
                    },
                  )
                : MapHotelBottomSheet(
                    hotel: Hotel.fromJson(state.selectedLocation!),
                    onClose: () {
                      Navigator.pop(sheetContext);
                      context.read<MapBloc>().add(ClearSelectedLocation());
                    },
                  ),
          );
        },
      ).whenComplete(() {
        if (mounted) {
           context.read<MapBloc>().add(ClearSelectedLocation());
        }
      });
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Container(
        padding: AppSpacing.allEdgeInsetSpace8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.medium8,
          boxShadow: [
            BoxShadow(
              color: ColorName.primaryTrueDark.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ColorName.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMyLocationFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'myLocation',
        onPressed: () {
          context.read<MapBloc>().add(GetUserLocation());
        },
        backgroundColor: Colors.white,
        foregroundColor: ColorName.primary,
        elevation: 0,
        child: const Icon(Icons.my_location),
      ),
    );
  }
  
  Widget _buildErrorView(BuildContext context, MapError state) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: ColorName.error),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
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

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}