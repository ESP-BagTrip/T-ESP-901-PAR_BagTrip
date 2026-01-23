part of 'map_bloc.dart';

/// Enum for map layer types.
enum MapLayerType { airports, hotels }

@immutable
sealed class MapEvent {}

/// Fired when the map camera position changes.
class MapCameraMoved extends MapEvent {
  final double latitude;
  final double longitude;
  final double zoom;

  MapCameraMoved({
    required this.latitude,
    required this.longitude,
    required this.zoom,
  });
}

/// Loads nearby locations (airports or hotels) based on coordinates.
class LoadNearbyLocations extends MapEvent {
  final double latitude;
  final double longitude;

  LoadNearbyLocations({
    required this.latitude,
    required this.longitude,
  });
}

/// Selects a specific location on the map.
class SelectLocation extends MapEvent {
  final Map<String, dynamic> location;
  final MapLocationType type;

  SelectLocation({
    required this.location,
    required this.type,
  });
}

/// Clears the currently selected location.
class ClearSelectedLocation extends MapEvent {}

/// Searches for locations by keyword (airports/cities).
class SearchLocations extends MapEvent {
  final String keyword;

  SearchLocations(this.keyword);
}

/// Clears the search results and query.
class ClearSearch extends MapEvent {}

/// Requests the user's current GPS location.
class GetUserLocation extends MapEvent {}

/// Toggles between map layers (airports/hotels).
class ToggleLayer extends MapEvent {
  final MapLayerType layer;

  ToggleLayer(this.layer);
}

/// Navigates the map to a specific location.
class NavigateToLocation extends MapEvent {
  final double latitude;
  final double longitude;
  final double? zoom;

  NavigateToLocation({
    required this.latitude,
    required this.longitude,
    this.zoom,
  });
}

/// Sets the check-in and check-out dates for hotel searches.
class SetHotelDates extends MapEvent {
  final DateTime checkIn;
  final DateTime checkOut;

  SetHotelDates({
    required this.checkIn,
    required this.checkOut,
  });
}

/// Clears any error message.
class ClearError extends MapEvent {}
