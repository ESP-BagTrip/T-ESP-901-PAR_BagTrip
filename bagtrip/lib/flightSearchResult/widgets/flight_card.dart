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
          color: isSelected ? const Color(0xFFE8F8F7) : Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
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
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 2, child: _buildDepartureInfo(flight)),
                Expanded(flex: 2, child: _buildFlightTimeline(flight)),
                Expanded(flex: 2, child: _buildArrivalInfo(flight)),
              ],
            ),
            const SizedBox(height: AppSpacing.space16),
            _buildAirlineInfo(flight, context),
            const SizedBox(height: AppSpacing.space8),
            _buildAmenities(flight, context),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartureInfo(Flight flight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          flight.departureTime,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: ColorName.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          flight.departureCode,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ColorName.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildArrivalInfo(Flight flight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          flight.arrivalTime,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: ColorName.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          flight.arrivalCode,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ColorName.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFlightTimeline(Flight flight) {
    return Column(
      children: [
        Text(
          flight.duration,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorName.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Container(height: 2, color: ColorName.secondary)),
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
    );
  }

  Widget _buildPrice(Flight flight) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space8,
      ),
      decoration: const BoxDecoration(
        color: ColorName.secondary,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Text(
        '${flight.price.toStringAsFixed(0)} €',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAirlineInfo(Flight flight, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  Icons.airplanemode_active,
                  size: 16,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      flight.airline ??
                          AppLocalizations.of(context)!.unknownAirline,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorName.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      flight.aircraftType ??
                          AppLocalizations.of(context)!.unknownAircraft,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ColorName.secondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space32),
        _buildPrice(flight),
      ],
    );
  }

  Widget _buildAmenities(Flight flight, BuildContext context) {
    final amenities = <Widget>[];

    // Check for cabin bags (hand baggage) - shown first
    if (flight.cabinBags != null) {
      amenities.add(
        _buildAmenityBadge(
          Icons.work_outline,
          AppLocalizations.of(context)!.handBaggageIncluded,
        ),
      );
    }

    // Check for checked baggage
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: ColorName.secondary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ColorName.secondary,
          ),
        ),
      ],
    );
  }
}
