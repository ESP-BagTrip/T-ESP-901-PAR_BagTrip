import 'package:bagtrip/core/extensions/datetime_ext.dart';
import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FlightCard extends StatefulWidget {
  final ManualFlight flight;
  final bool compact;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FlightCard({
    super.key,
    required this.flight,
    this.compact = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<FlightCard> createState() => _FlightCardState();
}

class _FlightCardState extends State<FlightCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final depCode = flight.departureAirport ?? '---';
    final arrCode = flight.arrivalAirport ?? '---';

    String? duration;
    if (flight.departureDate != null && flight.arrivalDate != null) {
      duration = flight.departureDate!.flightDurationTo(flight.arrivalDate!);
    }

    final depTime = flight.departureDate != null
        ? DateFormat('HH:mm').format(flight.departureDate!)
        : '--:--';
    final arrTime = flight.arrivalDate != null
        ? DateFormat('HH:mm').format(flight.arrivalDate!)
        : '--:--';

    final dateStr = flight.departureDate != null
        ? DateFormat('d MMM yyyy').format(flight.departureDate!)
        : '';

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onLongPress: widget.onDelete,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.large16,
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Flight number + delete
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    flight.flightNumber,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColorName.primaryTrueDark,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: AppLocalizations.of(
                            context,
                          )!.editFlightTooltip,
                          color: ColorName.hint,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onEdit,
                        ),
                      if (widget.onEdit != null && widget.onDelete != null)
                        const SizedBox(width: 8),
                      if (widget.onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: AppLocalizations.of(
                            context,
                          )!.deleteFlightTooltip,
                          color: ColorName.hint,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onDelete,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Route line: DEP ----plane---- ARR
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          depCode,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: ColorName.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          depTime,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ColorName.primaryTrueDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (duration != null)
                          Text(
                            duration,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 12,
                              color: ColorName.secondary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: ColorName.hint.withValues(alpha: 0.3),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Transform.rotate(
                                angle: 1.5708, // 90 degrees
                                child: const Icon(
                                  Icons.flight,
                                  size: 18,
                                  color: ColorName.primary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: ColorName.hint.withValues(alpha: 0.3),
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
                          arrCode,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: ColorName.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          arrTime,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ColorName.primaryTrueDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (!widget.compact) ...[
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: ColorName.hint.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 12),
                // Footer: date, airline, price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          color: ColorName.textMutedLight,
                        ),
                      ),
                    if (flight.airline != null)
                      Text(
                        flight.airline!,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          color: ColorName.textMutedLight,
                        ),
                      ),
                    if (flight.price != null)
                      Text(
                        flight.price!.formatPrice(
                          currency: flight.currency ?? '\u20ac',
                        ),
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorName.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
