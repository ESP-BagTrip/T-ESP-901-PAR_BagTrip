import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/transports/widgets/flight_card.dart';
import 'package:flutter/material.dart';

class MainFlightsSection extends StatelessWidget {
  final List<ManualFlight> flights;
  final VoidCallback? onAdd;
  final void Function(String id)? onDelete;

  const MainFlightsSection({
    super.key,
    required this.flights,
    this.onAdd,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (flights.isEmpty) {
      return _EmptyCTA(onAdd: onAdd);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          for (int i = 0; i < flights.length; i++) ...[
            FlightCard(
              flight: flights[i],
              onDelete: onDelete != null
                  ? () => onDelete!(flights[i].id)
                  : null,
            ),
            if (i < flights.length - 1) ...[
              // Connecting line between outbound and return
              SizedBox(
                height: 32,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 1,
                        height: 8,
                        color: ColorName.hint.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        Icons.swap_vert,
                        size: 14,
                        color: ColorName.hint.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 1,
                        height: 8,
                        color: ColorName.hint.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptyCTA extends StatelessWidget {
  final VoidCallback? onAdd;

  const _EmptyCTA({this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: onAdd,
        borderRadius: AppRadius.large20,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large20,
            border: Border.all(color: ColorName.hint.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.flight_takeoff_rounded,
                size: 48,
                color: AppColors.hint,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.addFirstTransport,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ColorName.primaryTrueDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.addFlightSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 12,
                  color: ColorName.textMutedLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
