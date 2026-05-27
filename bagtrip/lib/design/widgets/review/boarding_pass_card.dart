import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Pure-data model describing a flight for [BoardingPassCard].
class BoardingPassModel {
  const BoardingPassModel({
    required this.origin,
    required this.destination,
    required this.subtitle,
    required this.departure,
    required this.arrival,
    required this.airlineLine,
    required this.flightDate,
  });

  final String origin;
  final String destination;
  final String subtitle;
  final String departure;
  final String arrival;
  final String airlineLine;
  final String flightDate;
}

/// Boarding-pass-styled card with a dark header (airline code + IATA
/// origin/destination) and a white body (subtitle + departure/arrival times).
///
/// [onTap] / [onLongPress] are optional; when null the card is purely
/// informational (wizard review case).
class BoardingPassCard extends StatelessWidget {
  const BoardingPassCard({
    super.key,
    required this.title,
    required this.flight,
    this.onTap,
    this.onLongPress,
    this.showAiBadge = false,
  });

  final String title;
  final BoardingPassModel flight;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showAiBadge;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.large16,
        border: Border.all(
          color: AppColors.reviewCardBorderOf(brightness),
          width: 0.5,
        ),
        boxShadow: AppColors.reviewCardShadowOf(brightness),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.large16,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.reviewCardSurfaceOf(brightness),
          ),
          child: Column(
            children: [
              Container(
                color: AppColors.reviewAccentSurfaceOf(brightness),
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            flight.airlineLine.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 1,
                              color: ColorName.hint,
                            ),
                          ),
                        ),
                        if (showAiBadge) ...[
                          const SizedBox(width: AppSpacing.space8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space12,
                              vertical: AppSpacing.space8,
                            ),
                            decoration: BoxDecoration(
                              color: ColorName.secondary.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: AppRadius.pill,
                              border: Border.all(color: ColorName.secondary),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: ColorName.secondary,
                                ),
                                SizedBox(width: AppSpacing.space4),
                                Text(
                                  'IA',
                                  style: TextStyle(
                                    fontFamily: FontFamily.dMSans,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ColorName.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          flight.origin,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: ColorName.surface,
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: ColorName.hint,
                            indent: 10,
                            endIndent: 10,
                          ),
                        ),
                        Text(
                          flight.destination,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: ColorName.surface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Column(
                  children: [
                    if (flight.subtitle.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          flight.subtitle,
                          style: TextStyle(
                            fontFamily: FontFamily.b612,
                            color: AppColors.textSecondaryOf(brightness),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: FlightMeta(
                            label: AppLocalizations.of(
                              context,
                            )!.reviewFlightDeparture,
                            value: flight.departure,
                            date: flight.flightDate,
                            brightness: brightness,
                          ),
                        ),
                        Expanded(
                          child: FlightMeta(
                            label: AppLocalizations.of(
                              context,
                            )!.reviewFlightArrival,
                            value: flight.arrival,
                            date: flight.flightDate,
                            brightness: brightness,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null && onLongPress == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.large16,
        onTap: onTap,
        onLongPress: onLongPress,
        child: card,
      ),
    );
  }
}

/// One metadata column inside [BoardingPassCard] (label caps, time value,
/// date caps).
class FlightMeta extends StatelessWidget {
  const FlightMeta({
    super.key,
    required this.label,
    required this.value,
    required this.date,
    required this.brightness,
  });

  final String label;
  final String value;
  final String date;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: FontFamily.dMSans,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 1,
            color: AppColors.textSecondaryOf(brightness),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: FontFamily.dMSerifDisplay,
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: AppColors.profileMenuTitleOf(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          date.toUpperCase(),
          style: TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
            color: AppColors.textSecondaryOf(brightness),
          ),
        ),
      ],
    );
  }
}
