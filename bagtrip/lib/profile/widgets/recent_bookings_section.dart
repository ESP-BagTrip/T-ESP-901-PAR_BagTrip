import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';

class RecentBookingsSection extends StatelessWidget {
  final List<RecentBooking> recentBookings;

  const RecentBookingsSection({super.key, required this.recentBookings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
        boxShadow: [
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      padding: AppSpacing.allEdgeInsetSpace24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.flight_outlined,
                    color: ColorName.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    AppLocalizations.of(context)!.recentBookingsTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ColorName.primaryTrueDark,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppLocalizations.of(context)!.viewAllButton,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ColorName.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (recentBookings.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space16),
              child: Text(
                AppLocalizations.of(context)!.noRecentBookings,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorName.primaryTrueDark.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            ...recentBookings.map(
              (booking) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space16),
                child: _buildBookingRow(booking, context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingRow(RecentBooking booking, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final localizedStatus = _getLocalizedStatus(booking.status, localizations);
    final isCompleted =
        booking.status.toUpperCase() == 'CONFIRMED' ||
        booking.status == localizations.bookingStatusCompleted ||
        localizedStatus == localizations.bookingStatusCompleted;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColorName.primary, ColorName.secondary],
            ),
          ),
          child: const Icon(Icons.flight, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.route,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorName.primaryTrueDark,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                booking.details,
                style: TextStyle(
                  fontSize: 12,
                  color: ColorName.primaryTrueDark.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: ColorName.primaryTrueDark.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  Text(
                    booking.date,
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorName.primaryTrueDark.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorName.primaryTrueDark.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    booking.price,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorName.primaryTrueDark.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space8,
            vertical: AppSpacing.space4,
          ),
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? ColorName.primaryLight
                    : ColorName.secondary.withValues(alpha: 0.2),
            borderRadius: AppRadius.small4,
          ),
          child: Text(
            localizedStatus,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  isCompleted
                      ? ColorName.primaryTrueDark.withValues(alpha: 0.7)
                      : ColorName.secondary,
            ),
          ),
        ),
      ],
    );
  }

  String _getLocalizedStatus(String status, AppLocalizations localizations) {
    final upper = status.toUpperCase();
    if (upper == 'CONFIRMED' || status == 'Confirmé') {
      return localizations.bookingStatusConfirmed;
    }
    if (status == 'Terminé') {
      return localizations.bookingStatusCompleted;
    }
    return status;
  }
}
