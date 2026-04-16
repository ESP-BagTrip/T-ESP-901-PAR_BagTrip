import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/core/extensions/datetime_ext.dart';
import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/hotel_stats_grid.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Hotel tab of the new [TripDetailView].
///
/// One card per [Accommodation], each showing a dark header + a white body
/// with a 2×2 [HotelStatsGrid] (check-in / check-out / nights / per-night).
class HotelPanel extends StatelessWidget {
  const HotelPanel({
    super.key,
    required this.tripId,
    required this.trip,
    required this.accommodations,
    required this.canEdit,
    required this.isCompleted,
    required this.role,
  });

  final String tripId;
  final Trip trip;
  final List<Accommodation> accommodations;
  final bool canEdit;
  final bool isCompleted;
  final String role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (accommodations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ElegantEmptyState(
          icon: Icons.hotel_rounded,
          title: l10n.emptyAccommodationsTitle,
          subtitle: canEdit ? l10n.emptyAccommodationsSubtitle : null,
        ),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space24,
      ),
      itemCount: accommodations.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space16),
      itemBuilder: (context, index) {
        final acc = accommodations[index];
        final card = _HotelCard(
          accommodation: acc,
          l10n: l10n,
          locale: locale,
          onTap: canEdit ? () => _openAccommodations(context) : null,
        );
        if (!canEdit) return card;
        return Dismissible(
          key: ValueKey('accommodation-${acc.id}'),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          confirmDismiss: (_) async {
            AppHaptics.medium();
            return true;
          },
          onDismissed: (_) {
            context.read<TripDetailBloc>().add(
              DeleteAccommodationFromDetail(accommodationId: acc.id),
            );
          },
          child: card,
        );
      },
    );
  }

  void _openAccommodations(BuildContext context) {
    AccommodationsRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
      tripStartDate: trip.startDate?.toIso8601String(),
      tripEndDate: trip.endDate?.toIso8601String(),
      destinationIata: trip.destinationIata,
    ).push(context);
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({
    required this.accommodation,
    required this.l10n,
    required this.locale,
    required this.onTap,
  });

  final Accommodation accommodation;
  final AppLocalizations l10n;
  final String locale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final checkIn = accommodation.checkIn;
    final checkOut = accommodation.checkOut;
    final nights = (checkIn != null && checkOut != null)
        ? checkIn.nightsUntil(checkOut).clamp(1, 365)
        : 1;
    final perNight = accommodation.pricePerNight;

    final fmt = DateFormat('d MMM', locale);

    final card = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.large16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.reviewHeroDark, ColorName.primaryDark],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Icon(Icons.hotel_rounded, color: ColorName.surface),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accommodation.name,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ColorName.primaryDark,
                  ),
                ),
                if (accommodation.address != null &&
                    accommodation.address!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    accommodation.address!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                      color: ColorName.hint,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space16),
                HotelStatsGrid(
                  entries: [
                    (
                      l10n.reviewHotelCheckIn,
                      checkIn != null ? fmt.format(checkIn) : '--',
                    ),
                    (
                      l10n.reviewHotelCheckOut,
                      checkOut != null ? fmt.format(checkOut) : '--',
                    ),
                    (l10n.reviewHotelNights, '$nights'),
                    (
                      l10n.reviewHotelPerNight,
                      perNight != null ? perNight.formatPrice() : '--',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.large16,
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      decoration: const BoxDecoration(
        color: ColorName.error,
        borderRadius: AppRadius.large16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
