import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flightSearchResult/models/flight.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FlightCard extends StatelessWidget {
  final Flight flight;
  final bool isSelected;
  final VoidCallback onTap;

  const FlightCard({
    super.key,
    required this.flight,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: AppSpacing.onlyBottomSpace16,
        padding: AppSpacing.allEdgeInsetSpace24,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F8F7) : ColorName.primaryLight,
          borderRadius: const BorderRadius.all(Radius.circular(48)),
          boxShadow: [
            BoxShadow(
              color: ColorName.primary.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildFlightTimeline(flight),
            const SizedBox(height: AppSpacing.space16),
            _buildAirlineInfo(flight, context),
            const SizedBox(height: AppSpacing.space8),
            _buildAmenities(flight, context),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightTimeline(Flight flight) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                flight.departureTime,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorName.primary,
                ),
              ),
              Text(
                flight.departureCode,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ColorName.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                flight.duration,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorName.secondary,
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: Container(height: 2, color: ColorName.secondary),
                  ),

                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: ColorName.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                flight.arrivalTime,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorName.primary,
                ),
              ),
              Text(
                flight.arrivalCode,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ColorName.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAirlineInfo(Flight flight, BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            Icons.airplanemode_active,
            size: 14,
            color: Color(0xFFD32F2F),
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              flight.airline ?? AppLocalizations.of(context)!.unknownAirline,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorName.primary,
              ),
            ),
            Text(
              flight.aircraftType ??
                  AppLocalizations.of(context)!.unknownAircraft,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorName.secondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: AppSpacing.allEdgeInsetSpace8,
          decoration: const BoxDecoration(
            color: ColorName.secondary,
            borderRadius: AppRadius.large16,
          ),
          child: Text(
            '${flight.price.toStringAsFixed(0)} €',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities(Flight flight, BuildContext context) {
    final amenities = <Widget>[];

    // Check for baggage
    if (flight.checkedBags != null) {
      String label;
      if (flight.checkedBags!.weight != null) {
        label = AppLocalizations.of(
          context,
        )!.baggageKg(flight.checkedBags!.weight!);
      } else if (flight.checkedBags!.quantity != null) {
        label = AppLocalizations.of(
          context,
        )!.baggageQuantity(flight.checkedBags!.quantity!);
      } else {
        label = AppLocalizations.of(context)!.checkedBag;
      }
      amenities.add(_buildAmenityBadge(Icons.luggage_outlined, label));
    }

    if (flight.cabinBags != null) {
      String label;
      if (flight.cabinBags!.weight != null) {
        label = AppLocalizations.of(
          context,
        )!.baggageKg(flight.cabinBags!.weight!);
      } else if (flight.cabinBags!.quantity != null) {
        label = AppLocalizations.of(
          context,
        )!.baggageQuantity(flight.cabinBags!.quantity!);
      } else {
        label = AppLocalizations.of(context)!.cabinBag;
      }
      amenities.add(_buildAmenityBadge(Icons.work_outline, label));
    }

    if (amenities.isEmpty) return const SizedBox.shrink();

    return Row(
      children:
          amenities
              .expand(
                (widget) => [widget, const SizedBox(width: AppSpacing.space8)],
              )
              .take(amenities.length * 2 - 1)
              .toList(),
    );
  }

  Widget _buildAmenityBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: ColorName.secondary.withValues(alpha: 0.08),
        borderRadius: AppRadius.small4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ColorName.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ColorName.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
