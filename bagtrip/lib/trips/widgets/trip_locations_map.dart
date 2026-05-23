import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Kind of a mappable trip location, used to pick the marker icon/color.
enum MapLocationKind { destination, activity, accommodation }

/// A single point rendered on [TripLocationsMap].
///
/// We keep this decoupled from the API models because none of them currently
/// expose lat/lng — when coordinates land on Activity / Accommodation / Trip,
/// the page just maps them into this value type, the widget stays untouched.
@immutable
class MapLocation {
  final double latitude;
  final double longitude;
  final String title;
  final String? subtitle;
  final MapLocationKind kind;
  final IconData icon;
  final Color color;

  const MapLocation({
    required this.latitude,
    required this.longitude,
    required this.title,
    this.subtitle,
    required this.kind,
    required this.icon,
    required this.color,
  });

  LatLng get point => LatLng(latitude, longitude);
}

/// Embedded OpenStreetMap of a trip's locations (free, no API key).
///
/// Renders a [FlutterMap] with an OSM [TileLayer] and one categorized
/// [Marker] per [MapLocation]. Tapping a marker opens a small bottom sheet
/// with its name. When [locations] is empty the map falls back to a wide
/// world view so the widget still renders something meaningful.
class TripLocationsMap extends StatelessWidget {
  final List<MapLocation> locations;
  final double height;

  /// Fallback center used when [locations] is empty (e.g. trip destination
  /// coords if ever available). Defaults to a neutral world view.
  final LatLng? fallbackCenter;

  const TripLocationsMap({
    super.key,
    required this.locations,
    this.height = AppSize.mapEmbeddedHeight,
    this.fallbackCenter,
  });

  LatLng get _initialCenter {
    if (locations.isNotEmpty) return locations.first.point;
    return fallbackCenter ?? const LatLng(20, 0);
  }

  double get _initialZoom {
    if (locations.isNotEmpty) return 11;
    return fallbackCenter != null ? 10 : 1.5;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.large16,
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: _initialZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ai.bagtrip.app',
            ),
            MarkerLayer(
              markers: [
                for (final location in locations)
                  Marker(
                    point: location.point,
                    width: AppSize.mapMarker,
                    height: AppSize.mapMarker,
                    child: _MapMarker(
                      location: location,
                      onTap: () => _showLocationSheet(context, location),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationSheet(BuildContext context, MapLocation location) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSheet(location: location),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final MapLocation location;
  final VoidCallback onTap;

  const _MapMarker({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: '${location.title}, ${_kindLabel(l10n, location.kind)}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: location.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: AppShadows.card,
          ),
          child: Icon(
            location.icon,
            size: AppSize.mapMarkerIcon,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _LocationSheet extends StatelessWidget {
  final MapLocation location;

  const _LocationSheet({required this.location});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.space12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: location.color.withValues(alpha: 0.15),
                child: Icon(location.icon, color: location.color),
              ),
              title: Text(
                location.title,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                location.subtitle ?? _kindLabel(l10n, location.kind),
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 13,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }
}

String _kindLabel(AppLocalizations l10n, MapLocationKind kind) =>
    switch (kind) {
      MapLocationKind.destination => l10n.mapDestination,
      MapLocationKind.activity => l10n.mapActivities,
      MapLocationKind.accommodation => l10n.mapAccommodations,
    };
