import 'package:bagtrip/core/extensions/datetime_ext.dart';
import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/helpers/map_launcher.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/trip_detail/helpers/accommodation_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccommodationBookingCard extends StatefulWidget {
  final Accommodation accommodation;
  final bool isOwner;
  final bool isCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AccommodationBookingCard({
    super.key,
    required this.accommodation,
    required this.isOwner,
    required this.isCompleted,
    this.onTap,
    this.onDelete,
  });

  @override
  State<AccommodationBookingCard> createState() =>
      _AccommodationBookingCardState();
}

class _AccommodationBookingCardState extends State<AccommodationBookingCard> {
  double _scale = 1.0;

  IconData _typeIcon() {
    final name = widget.accommodation.name.toLowerCase();
    if (name.contains('airbnb')) return Icons.home_outlined;
    if (name.contains('hostel') || name.contains('auberge')) {
      return Icons.single_bed_outlined;
    }
    if (name.contains('camping')) return Icons.forest_outlined;
    if (name.contains('resort')) return Icons.pool_outlined;
    return Icons.hotel_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.accommodation;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final status = deriveAccommodationStatus(a);
    final statusColor = accommodationStatusColor(status);
    final statusText = accommodationStatusLabel(status, l10n);

    int? nights;
    if (a.checkIn != null && a.checkOut != null) {
      nights = a.checkIn!.nightsUntil(a.checkOut!);
    }

    final checkInStr = a.checkIn != null
        ? DateFormat('d MMM').format(a.checkIn!)
        : '---';
    final checkOutStr = a.checkOut != null
        ? DateFormat('d MMM').format(a.checkOut!)
        : '---';

    double? totalPrice;
    if (a.pricePerNight != null && nights != null) {
      totalPrice = a.pricePerNight! * nights;
    }

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
                    Icon(_typeIcon(), size: 18, color: ColorName.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.name,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ColorName.primaryTrueDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(label: statusText, color: statusColor),
                  ],
                ),
              ),

              // ── Zone 2: Dates ─────────────────────────────────
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
                            l10n.accommodationCheckInLabel,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 10,
                              color: ColorName.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            checkInStr,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorName.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          if (nights != null)
                            Text(
                              '$nights ${l10n.accommodationNights}',
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
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.king_bed_rounded,
                                  size: 18,
                                  color: ColorName.primary,
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
                            l10n.accommodationCheckOutLabel,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 10,
                              color: ColorName.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            checkOutStr,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 18,
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

              // ── Perforation line ──────────────────────────────
              SizedBox(
                height: 20,
                child: Stack(
                  children: [
                    Center(
                      child: CustomPaint(
                        size: Size(MediaQuery.of(context).size.width - 80, 1),
                        painter: _DashedLinePainter(
                          color: ColorName.hint.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (a.address != null && a.address!.isNotEmpty)
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  launchMapNavigation(context, a.address!),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.place_outlined,
                                    size: 14,
                                    color: ColorName.textMutedLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      a.address!,
                                      style: const TextStyle(
                                        fontFamily: FontFamily.b612,
                                        fontSize: 12,
                                        color: ColorName.textMutedLight,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (a.checkIn != null)
                          Text(
                            DateFormat('d MMM yyyy').format(a.checkIn!),
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 12,
                              color: ColorName.textMutedLight,
                            ),
                          ),
                        if (totalPrice != null)
                          Text(
                            totalPrice.formatPrice(currency: a.currency ?? '€'),
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ColorName.primary,
                            ),
                          ),
                      ],
                    ),
                    if (a.bookingReference != null &&
                        a.bookingReference!.isNotEmpty &&
                        widget.isOwner) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ColorName.primary.withValues(alpha: 0.08),
                          borderRadius: AppRadius.medium8,
                        ),
                        child: Text(
                          a.bookingReference!,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 11,
                            color: ColorName.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
        key: ValueKey(a.id),
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
