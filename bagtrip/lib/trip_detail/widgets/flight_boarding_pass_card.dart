import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/trip_detail/helpers/flight_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FlightBoardingPassCard extends StatefulWidget {
  final ManualFlight flight;
  final bool isOwner;
  final bool isCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FlightBoardingPassCard({
    super.key,
    required this.flight,
    required this.isOwner,
    required this.isCompleted,
    this.onTap,
    this.onDelete,
  });

  @override
  State<FlightBoardingPassCard> createState() => _FlightBoardingPassCardState();
}

class _FlightBoardingPassCardState extends State<FlightBoardingPassCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final status = deriveFlightStatus(flight);
    final statusColor = flightStatusColor(status);
    final statusText = flightStatusLabel(status, l10n);

    final depCode = flight.departureAirport ?? '---';
    final arrCode = flight.arrivalAirport ?? '---';

    String? duration;
    if (flight.departureDate != null && flight.arrivalDate != null) {
      final diff = flight.arrivalDate!.difference(flight.departureDate!);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      duration = '${hours}h${minutes.toString().padLeft(2, '0')}';
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

    final card = GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        AppHaptics.light();
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: AppRadius.large16,
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              // ── Zone 1: Identity ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Text(
                      flight.flightNumber,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ColorName.primaryTrueDark,
                      ),
                    ),
                    if (flight.airline != null) ...[
                      const Text(
                        ' · ',
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 13,
                          color: ColorName.textMutedLight,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          flight.airline!,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: ColorName.textMutedLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    const SizedBox(width: 8),
                    _StatusBadge(label: statusText, color: statusColor),
                  ],
                ),
              ),

              // ── Zone 2: Route ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
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
                                  angle: 1.5708,
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
              ),

              // ── Perforation line ──────────────────────────────
              SizedBox(
                height: 20,
                child: Stack(
                  children: [
                    // Dashed line
                    Center(
                      child: CustomPaint(
                        size: Size(MediaQuery.of(context).size.width - 80, 1),
                        painter: _DashedLinePainter(
                          color: ColorName.hint.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    // Left notch
                    Positioned(
                      left: -10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    // Right notch
                    Positioned(
                      right: -10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Zone 3: Details ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
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
                    if (flight.price != null)
                      Text(
                        '${flight.price!.toStringAsFixed(0)} ${flight.currency ?? '€'}',
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorName.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isOwner && !widget.isCompleted) {
      return Dismissible(
        key: ValueKey(flight.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.space24),
          decoration: const BoxDecoration(
            color: AppColors.error,
            borderRadius: AppRadius.large16,
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (_) async => true,
        onDismissed: (_) => widget.onDelete?.call(),
        child: card,
      );
    }

    return card;
  }
}

// ── Status Badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: FontFamily.b612,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Dashed Line Painter ─────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 4.0;
    const dashGap = 3.0;
    var startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
