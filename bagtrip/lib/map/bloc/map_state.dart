part of 'map_bloc.dart';

/// Enum for location types displayed on the map.
enum MapLocationType { airport, hotel }

@immutable
sealed class MapState {}

/// Initial state before the map is loaded.
final class MapInitial extends MapState {}

/// Main loaded state containing all map data.
final class MapLoaded extends MapState {
  // Camera position
  final double centerLat;
  final double centerLng;
  final double zoom;

  // Markers for airports
  final List<Map<String, dynamic>> airportMarkers;

  // Markers for hotels
  final List<Hotel> hotelMarkers;

  // Selected location
  final Map<String, dynamic>? selectedLocation;
  final MapLocationType? selectedLocationType;

  // Loading state
  final bool isLoading;

  // Search
  final List<Map<String, dynamic>> searchResults;
  final String? searchQuery;

  // Active layer
  final MapLayerType activeLayer;

  // User location
  final double? userLat;
  final double? userLng;

  // Error handling
  final String? errorMessage;

  // Hotel search dates
  final DateTime? hotelCheckIn;
  final DateTime? hotelCheckOut;

  // Navigation request (consumed by UI)
  final bool shouldNavigate;

  MapLoaded({
    this.centerLat = 48.8566,
    this.centerLng = 2.3522,
    this.zoom = 10.0,
    this.airportMarkers = const [],
    this.hotelMarkers = const [],
    this.selectedLocation,
    this.selectedLocationType,
    this.isLoading = false,
    this.searchResults = const [],
    this.searchQuery,
    this.activeLayer = MapLayerType.airports,
    this.userLat,
    this.userLng,
    this.errorMessage,
    this.hotelCheckIn,
    this.hotelCheckOut,
    this.shouldNavigate = false,
  });

  MapLoaded copyWith({
    double? centerLat,
    double? centerLng,
    double? zoom,
    List<Map<String, dynamic>>? airportMarkers,
    List<Hotel>? hotelMarkers,
    Map<String, dynamic>? selectedLocation,
    MapLocationType? selectedLocationType,
    bool? isLoading,
    List<Map<String, dynamic>>? searchResults,
    String? searchQuery,
    MapLayerType? activeLayer,
    double? userLat,
    double? userLng,
    String? errorMessage,
    DateTime? hotelCheckIn,
    DateTime? hotelCheckOut,
    bool? shouldNavigate,
    bool clearSelectedLocation = false,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return MapLoaded(
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      zoom: zoom ?? this.zoom,
      airportMarkers: airportMarkers ?? this.airportMarkers,
      hotelMarkers: hotelMarkers ?? this.hotelMarkers,
      selectedLocation: clearSelectedLocation ? null : (selectedLocation ?? this.selectedLocation),
      selectedLocationType: clearSelectedLocation ? null : (selectedLocationType ?? this.selectedLocationType),
      isLoading: isLoading ?? this.isLoading,
      searchResults: clearSearch ? const [] : (searchResults ?? this.searchResults),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      activeLayer: activeLayer ?? this.activeLayer,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hotelCheckIn: hotelCheckIn ?? this.hotelCheckIn,
      hotelCheckOut: hotelCheckOut ?? this.hotelCheckOut,
      shouldNavigate: shouldNavigate ?? false,
    );
  }
}

/// Error state when something goes wrong.
final class MapError extends MapState {
  final String message;

  MapError(this.message);
}
