// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../../service/LocationService.dart';
import '../../service/geolocation_service.dart';
import '../../service/hotel_service.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final LocationService _locationService;
  final GeolocationService _geolocationService;
  final HotelService _hotelService;

  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 500);

  MapBloc({
    LocationService? locationService,
    GeolocationService? geolocationService,
    HotelService? hotelService,
  })  : _locationService = locationService ?? LocationService(),
        _geolocationService = geolocationService ?? GeolocationService(),
        _hotelService = hotelService ?? HotelService(),
        super(MapInitial()) {
    on<MapCameraMoved>(_onMapCameraMoved);
    on<LoadNearbyLocations>(_onLoadNearbyLocations);
    on<SelectLocation>(_onSelectLocation);
    on<ClearSelectedLocation>(_onClearSelectedLocation);
    on<SearchLocations>(_onSearchLocations);
    on<ClearSearch>(_onClearSearch);
    on<GetUserLocation>(_onGetUserLocation);
    on<ToggleLayer>(_onToggleLayer);
    on<NavigateToLocation>(_onNavigateToLocation);
    on<SetHotelDates>(_onSetHotelDates);
    on<ClearError>(_onClearError);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  MapLoaded _currentState() {
    if (state is MapLoaded) {
      return state as MapLoaded;
    }
    return MapLoaded();
  }

  Future<void> _onMapCameraMoved(
    MapCameraMoved event,
    Emitter<MapState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(
      centerLat: event.latitude,
      centerLng: event.longitude,
      zoom: event.zoom,
    ));

    // Debounce the location fetch
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      add(LoadNearbyLocations(
        latitude: event.latitude,
        longitude: event.longitude,
      ));
    });
  }

  Future<void> _onLoadNearbyLocations(
    LoadNearbyLocations event,
    Emitter<MapState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(isLoading: true, clearError: true));

    try {
      if (current.activeLayer == MapLayerType.airports) {
        final airports = await _locationService.searchNearestLocations(
          event.latitude,
          event.longitude,
        );
        emit(current.copyWith(
          isLoading: false,
          airportMarkers: airports,
          clearError: true,
        ));
      } else {
        // Load hotels
        final checkIn = current.hotelCheckIn ?? DateTime.now().add(const Duration(days: 1));
        final checkOut = current.hotelCheckOut ?? DateTime.now().add(const Duration(days: 2));
        final dateFormat = DateFormat('yyyy-MM-dd');

        final hotels = await _hotelService.searchHotelsByLocation(
          latitude: event.latitude,
          longitude: event.longitude,
          checkIn: dateFormat.format(checkIn),
          checkOut: dateFormat.format(checkOut),
        );
        emit(current.copyWith(
          isLoading: false,
          hotelMarkers: hotels,
          clearError: true,
        ));
      }
    } catch (e) {
      emit(current.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSelectLocation(
    SelectLocation event,
    Emitter<MapState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(
      selectedLocation: event.location,
      selectedLocationType: event.type,
    ));
  }

  Future<void> _onClearSelectedLocation(
    ClearSelectedLocation event,
    Emitter<MapState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(clearSelectedLocation: true));
  }

  Future<void> _onSearchLocations(
    SearchLocations event,
    Emitter<MapState> emit,
  ) async {
    final current = _currentState();

    if (event.keyword.isEmpty) {
      emit(current.copyWith(clearSearch: true));
      return;
    }

    emit(current.copyWith(
      isLoading: true,
      searchQuery: event.keyword,
      clearError: true,
    ));

    try {
      // Search for both cities and airports
      final results = await _locationService.searchLocationsByKeyword(
        event.keyword,
        'CITY,AIRPORT',
      );
      emit(current.copyWith(
        isLoading: false,
        searchResults: results,
        searchQuery: event.keyword,
        clearError: true,
      ));
    } catch (e) {
      emit(current.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<MapState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(clearSearch: true));
  }

  Future<void> _onGetUserLocation(
    GetUserLocation event,
    Emitter<MapState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(isLoading: true, clearError: true));

    try {
      final position = await _geolocationService.getCurrentPosition();
      emit(current.copyWith(
        isLoading: false,
        userLat: position.latitude,
        userLng: position.longitude,
        centerLat: position.latitude,
        centerLng: position.longitude,
        shouldNavigate: true,
        clearError: true,
      ));

      // Load nearby locations for the user's position
      add(LoadNearbyLocations(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } on GeolocationException catch (e) {
      emit(current.copyWith(
        isLoading: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(current.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get your location: $e',
      ));
    }
  }

  Future<void> _onToggleLayer(
    ToggleLayer event,
    Emitter<MapState> emit,
  ) async {
    final current = _currentState();

    if (current.activeLayer == event.layer) return;

    emit(current.copyWith(
      activeLayer: event.layer,
      clearSelectedLocation: true,
    ));

    // Reload locations for the new layer
    add(LoadNearbyLocations(
      latitude: current.centerLat,
      longitude: current.centerLng,
    ));
  }

  Future<void> _onNavigateToLocation(
    NavigateToLocation event,
    Emitter<MapState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(
      centerLat: event.latitude,
      centerLng: event.longitude,
      zoom: event.zoom,
      shouldNavigate: true,
      clearSearch: true,
    ));

    // Load nearby locations for the new position
    add(LoadNearbyLocations(
      latitude: event.latitude,
      longitude: event.longitude,
    ));
  }

  Future<void> _onSetHotelDates(
    SetHotelDates event,
    Emitter<MapState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(
      hotelCheckIn: event.checkIn,
      hotelCheckOut: event.checkOut,
    ));

    // Reload hotels if currently viewing hotel layer
    if (current.activeLayer == MapLayerType.hotels) {
      add(LoadNearbyLocations(
        latitude: current.centerLat,
        longitude: current.centerLng,
      ));
    }
  }

  Future<void> _onClearError(
    ClearError event,
    Emitter<MapState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(clearError: true));
  }
}
