import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/helpers/map_launcher.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/cubit/trip_locations_cubit.dart';
import 'package:bagtrip/trips/widgets/trip_locations_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripLocationsPage extends StatelessWidget {
  final String tripId;

  const TripLocationsPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TripLocationsCubit()..load(tripId),
      child: const _TripLocationsView(),
    );
  }
}

class _TripLocationsView extends StatelessWidget {
  const _TripLocationsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapLocationsTitle)),
      body: BlocBuilder<TripLocationsCubit, TripLocationsState>(
        builder: (context, state) {
          if (state is TripLocationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final loaded = state as TripLocationsLoaded;
          return _LocationsList(
            trip: loaded.trip,
            activities: loaded.activities,
            accommodations: loaded.accommodations,
          );
        },
      ),
    );
  }
}

class _LocationsList extends StatelessWidget {
  final Trip? trip;
  final List<Activity> activities;
  final List<Accommodation> accommodations;

  const _LocationsList({
    required this.trip,
    required this.activities,
    required this.accommodations,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final activityLocations = activities
        .where((a) => a.location != null && a.location!.isNotEmpty)
        .toList();
    final accommodationLocations = accommodations
        .where((a) => a.address != null && a.address!.isNotEmpty)
        .toList();
    final hasDestination =
        trip?.destinationName != null && trip!.destinationName!.isNotEmpty;
    final hasLocations =
        hasDestination ||
        activityLocations.isNotEmpty ||
        accommodationLocations.isNotEmpty;

    if (!hasLocations) {
      return ElegantEmptyState(
        icon: Icons.map_outlined,
        title: l10n.mapLocationsTitle,
        subtitle: l10n.mapNoLocations,
      );
    }

    final mapLocations = buildMapLocations(
      trip: trip,
      activities: activityLocations,
      accommodations: accommodationLocations,
    );
    final destination = mapLocations
        .where((l) => l.kind == MapLocationKind.destination)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
          child: TripLocationsMap(
            locations: mapLocations,
            fallbackCenter: destination?.point,
          ),
        ),
        const SizedBox(height: AppSpacing.space24),
        if (hasDestination) ...[
          _SectionHeader(title: l10n.mapDestination),
          _LocationTile(
            icon: Icons.place,
            title: trip!.destinationName!,
            onTap: () => launchMapNavigation(context, trip!.destinationName!),
          ),
          const SizedBox(height: AppSpacing.space16),
        ],
        if (activityLocations.isNotEmpty) ...[
          _SectionHeader(title: l10n.mapActivities),
          ...activityLocations.map(
            (a) => _LocationTile(
              icon: Icons.hiking_rounded,
              title: a.title,
              subtitle: a.location,
              onTap: () => launchMapNavigation(context, a.location!),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
        ],
        if (accommodationLocations.isNotEmpty) ...[
          _SectionHeader(title: l10n.mapAccommodations),
          ...accommodationLocations.map(
            (a) => _LocationTile(
              icon: Icons.hotel_rounded,
              title: a.name,
              subtitle: a.address,
              onTap: () => launchMapNavigation(context, a.address!),
            ),
          ),
        ],
      ],
    );
  }
}

/// Builds categorized [MapLocation] markers from trip items.
///
/// SMP327-039 — geocoding is bounded to the trip *destination*: the backend
/// resolves `destinationIata` -> coordinates (offline aviation data) and
/// exposes them on [Trip.destinationLatitude] / [Trip.destinationLongitude].
/// When present, we emit a single destination marker so the map can center
/// on it. Activities / Accommodations still carry only free-text locations
/// (no lat/lng), so they yield no markers yet — `activities` /
/// `accommodations` are kept so the wiring is ready the moment coords land on
/// those models.
List<MapLocation> buildMapLocations({
  required Trip? trip,
  required List<Activity> activities,
  required List<Accommodation> accommodations,
}) {
  final locations = <MapLocation>[];

  final lat = trip?.destinationLatitude;
  final lng = trip?.destinationLongitude;
  if (lat != null && lng != null) {
    locations.add(
      MapLocation(
        latitude: lat,
        longitude: lng,
        title: trip?.destinationName ?? '',
        kind: MapLocationKind.destination,
        icon: Icons.place,
        color: AppColors.primary,
      ),
    );
  }

  // Activities / Accommodations have no coordinates yet — see note above.
  return locations;
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space24,
        vertical: AppSpacing.space8,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: FontFamily.b612,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ColorName.primary.withValues(alpha: 0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _LocationTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: ColorName.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: FontFamily.b612,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                color: ColorName.primary.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: const Icon(
        Icons.open_in_new,
        size: 18,
        color: ColorName.secondary,
      ),
      onTap: onTap,
    );
  }
}
