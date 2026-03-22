import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/widgets/accommodation_booking_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripAccommodationSection extends StatelessWidget {
  final List<Accommodation> accommodations;
  final String tripId;
  final Trip trip;
  final bool isOwner;
  final bool isCompleted;

  const TripAccommodationSection({
    super.key,
    required this.accommodations,
    required this.tripId,
    required this.trip,
    required this.isOwner,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────
        _SectionHeader(
          title: l10n.accommodationsTitle,
          count: accommodations.length,
        ),
        const SizedBox(height: 12),

        if (accommodations.isEmpty)
          _EmptyState(
            isOwner: isOwner,
            isCompleted: isCompleted,
            tripId: tripId,
            trip: trip,
          )
        else
          _AccommodationsList(
            accommodations: accommodations,
            tripId: tripId,
            trip: trip,
            isOwner: isOwner,
            isCompleted: isCompleted,
          ),
      ],
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.hotel_rounded, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ColorName.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorName.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Accommodations List ─────────────────────────────────────────────────────

class _AccommodationsList extends StatelessWidget {
  final List<Accommodation> accommodations;
  final String tripId;
  final Trip trip;
  final bool isOwner;
  final bool isCompleted;

  const _AccommodationsList({
    required this.accommodations,
    required this.tripId,
    required this.trip,
    required this.isOwner,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = accommodations.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...List.generate(preview.length, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < preview.length - 1 ? 12 : 0),
            child: StaggeredFadeIn(
              index: i,
              child: AccommodationBookingCard(
                accommodation: preview[i],
                isOwner: isOwner,
                isCompleted: isCompleted,
                onDelete: () {
                  context.read<TripDetailBloc>().add(
                    DeleteAccommodationFromDetail(
                      accommodationId: preview[i].id,
                    ),
                  );
                },
                onTap: () async {
                  await AccommodationsRoute(
                    tripId: tripId,
                    role: trip.role ?? 'OWNER',
                    isCompleted: isCompleted,
                    tripStartDate: trip.startDate?.toIso8601String(),
                    tripEndDate: trip.endDate?.toIso8601String(),
                    destinationIata: trip.destinationIata,
                  ).push(context);
                  if (!context.mounted) return;
                  context.read<TripDetailBloc>().add(RefreshTripDetail());
                },
              ),
            ),
          );
        }),
        if (accommodations.length > 3) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await AccommodationsRoute(
                tripId: tripId,
                role: trip.role ?? 'OWNER',
                isCompleted: isCompleted,
                tripStartDate: trip.startDate?.toIso8601String(),
                tripEndDate: trip.endDate?.toIso8601String(),
              ).push(context);
              if (!context.mounted) return;
              context.read<TripDetailBloc>().add(RefreshTripDetail());
            },
            child: Text(
              l10n.accommodationSectionSeeAll(accommodations.length),
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorName.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isOwner;
  final bool isCompleted;
  final String tripId;
  final Trip trip;

  const _EmptyState({
    required this.isOwner,
    required this.isCompleted,
    required this.tripId,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: AppSpacing.allEdgeInsetSpace24,
        child: Column(
          children: [
            // Halo icon
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          ColorName.primary.withValues(alpha: 0.08),
                          ColorName.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorName.primary.withValues(alpha: 0.06),
                    ),
                    child: const Icon(
                      Icons.night_shelter_rounded,
                      size: 36,
                      color: ColorName.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.emptyAccommodationsTitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.emptyAccommodationsSubtitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                color: ColorName.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),

            if (isOwner && !isCompleted) ...[
              const SizedBox(height: 20),
              _OptionTile(
                icon: Icons.search_rounded,
                title: l10n.accommodationSearchHotels,
                subtitle: l10n.accommodationSearchHotelsSubtitle,
                onTap: () async {
                  await AccommodationsRoute(
                    tripId: tripId,
                    role: trip.role ?? 'OWNER',
                    isCompleted: isCompleted,
                    tripStartDate: trip.startDate?.toIso8601String(),
                    tripEndDate: trip.endDate?.toIso8601String(),
                    destinationIata: trip.destinationIata,
                  ).push(context);
                  if (!context.mounted) return;
                  context.read<TripDetailBloc>().add(RefreshTripDetail());
                },
              ),
              const SizedBox(height: 12),
              _OptionTile(
                icon: Icons.edit_rounded,
                title: l10n.accommodationAddManually,
                subtitle: l10n.accommodationAddManuallySubtitle,
                onTap: () async {
                  await AccommodationsRoute(
                    tripId: tripId,
                    role: trip.role ?? 'OWNER',
                    isCompleted: isCompleted,
                    tripStartDate: trip.startDate?.toIso8601String(),
                    tripEndDate: trip.endDate?.toIso8601String(),
                    destinationIata: trip.destinationIata,
                  ).push(context);
                  if (!context.mounted) return;
                  context.read<TripDetailBloc>().add(RefreshTripDetail());
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Option Tile ─────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.large16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: AppRadius.large16,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorName.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.medium8,
              ),
              child: Icon(icon, color: ColorName.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
