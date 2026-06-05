import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/widgets/home_trip_hero_chrome.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Day badge + travelers pill for [ReviewHero.statusBadge] on programme home.
class ActiveTripHeroStatus extends StatelessWidget {
  const ActiveTripHeroStatus({
    super.key,
    required this.currentDay,
    required this.totalDays,
    this.travelerCount,
  });

  final int currentDay;
  final int totalDays;
  final int? travelerCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final dayBadge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        l10n.homeActiveTripDay(currentDay, totalDays),
        style: const TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );

    final showTravelers = travelerCount != null && travelerCount! > 0;
    if (!showTravelers) {
      return dayBadge;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeTripTravelersPill(
          label: l10n.homeActiveTripTravelersAbbrev(travelerCount!),
        ),
        const SizedBox(width: AppSpacing.space8),
        dayBadge,
      ],
    );
  }
}
