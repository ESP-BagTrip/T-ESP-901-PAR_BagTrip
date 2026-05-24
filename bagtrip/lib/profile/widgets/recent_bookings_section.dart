import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/recent_booking.dart';
import 'package:bagtrip/profile/widgets/profile_menu_group_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentBookingsSection extends StatelessWidget {
  final List<RecentBooking> recentBookings;

  /// Long-press callback per row. Used by the profile page to surface the
  /// refund sheet on captured bookings — kept as a callback (rather than
  /// owned here) so the section stays presentational.
  final void Function(RecentBooking booking)? onLongPressBooking;

  const RecentBookingsSection({
    super.key,
    required this.recentBookings,
    this.onLongPressBooking,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.profileMenuTitleOf(brightness);
    final mutedColor = AppColors.profileMenuMutedOf(brightness);

    return ProfileMenuGroupCard(
      children: [
        Padding(
          padding: AppSpacing.allEdgeInsetSpace16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    l10n.recentBookingsTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
              if (recentBookings.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space16),
                  child: Text(
                    l10n.noRecentBookings,
                    style: TextStyle(fontSize: 14, color: mutedColor),
                  ),
                )
              else
                ...recentBookings.map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space16),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: onLongPressBooking == null
                          ? null
                          : () => onLongPressBooking!(booking),
                      child: _buildBookingRow(
                        booking,
                        context,
                        titleColor: titleColor,
                        mutedColor: mutedColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingRow(
    RecentBooking booking,
    BuildContext context, {
    required Color titleColor,
    required Color mutedColor,
  }) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final localizedStatus = _getLocalizedStatus(booking.status, localizations);
    final isCompleted =
        booking.status.toUpperCase() == 'CONFIRMED' ||
        booking.status == localizations.bookingStatusCompleted ||
        localizedStatus == localizations.bookingStatusCompleted;
    final formattedDate = DateFormat('d MMM yyyy', locale).format(booking.date);
    final formattedPrice =
        '${NumberFormat.decimalPattern(locale).format(booking.priceTotal)} ${booking.currency}';

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
          child: const Icon(Icons.flight, color: AppColors.surface, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.bookingLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                booking.details,
                style: TextStyle(fontSize: 12, color: mutedColor),
              ),
              const SizedBox(height: AppSpacing.space8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: mutedColor,
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: mutedColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    formattedPrice,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: titleColor.withValues(alpha: 0.85),
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
            color: isCompleted
                ? ColorName.primaryLight
                : ColorName.secondary.withValues(alpha: 0.2),
            borderRadius: AppRadius.small4,
          ),
          child: Text(
            localizedStatus,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isCompleted
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
