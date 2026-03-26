import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FlightDetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String date;
  final String departureTime;
  final String departureAirport;
  final String arrivalTime;
  final String arrivalAirport;
  final String duration;
  final String? airline;
  final String? aircraft;
  final String tagLabel;
  final Color tagColor;

  const FlightDetailCard({
    super.key,
    required this.title,
    required this.icon,
    required this.date,
    required this.departureTime,
    required this.departureAirport,
    required this.arrivalTime,
    required this.arrivalAirport,
    required this.duration,
    required this.airline,
    required this.aircraft,
    required this.tagLabel,
    this.tagColor = ColorName.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
      padding: AppSpacing.allEdgeInsetSpace16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(icon, color: ColorName.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: ColorName.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Date
          Text(
            date,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 14,
              color: ColorName.primary,
            ),
          ),
          const SizedBox(height: 16),
          // Time & Duration Line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Departure
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    departureTime,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: ColorName.primary,
                    ),
                  ),
                  Text(
                    departureAirport,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      color: ColorName.secondary,
                    ),
                  ),
                ],
              ),
              // Duration Line
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        duration,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          color: ColorName.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(height: 2, color: ColorName.secondary),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: ColorName.secondary,
                              ),
                              CircleAvatar(
                                radius: 4,
                                backgroundColor: ColorName.secondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Arrival
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    arrivalTime,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: ColorName.primary,
                    ),
                  ),
                  Text(
                    arrivalAirport,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      color: ColorName.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Airline & Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Placeholder for Airline Logo
                  Container(
                    width: 24,
                    height: 24,
                    color: AppColors.border,
                    child: const Icon(
                      Icons.airlines,
                      size: 16,
                      color: AppColors.hint,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        airline ?? AppLocalizations.of(context)!.unknownAirline,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: ColorName.secondary,
                        ),
                      ),
                      Text(
                        aircraft ??
                            AppLocalizations.of(context)!.unknownAircraft,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 10,
                          color: ColorName.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tagColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tagLabel,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
