import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/helpers/map_launcher.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccommodationCard extends StatefulWidget {
  final Accommodation accommodation;
  final bool isViewer;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const AccommodationCard({
    super.key,
    required this.accommodation,
    this.isViewer = false,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<AccommodationCard> createState() => _AccommodationCardState();
}

class _AccommodationCardState extends State<AccommodationCard> {
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
    final theme = Theme.of(context);
    final a = widget.accommodation;
    final l10n = AppLocalizations.of(context)!;

    int? nights;
    if (a.checkIn != null && a.checkOut != null) {
      nights = a.checkOut!.difference(a.checkIn!).inDays;
      if (nights < 1) nights = 1;
    }

    final checkInStr = a.checkIn != null
        ? DateFormat('d MMM').format(a.checkIn!)
        : null;
    final checkOutStr = a.checkOut != null
        ? DateFormat('d MMM').format(a.checkOut!)
        : null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onEdit?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      onLongPress: widget.onDelete,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: AppRadius.large16,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line 1: Name + type icon
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.name,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(_typeIcon(), size: 20, color: ColorName.primary),
                  if (widget.onDelete != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: l10n.deleteAccommodationTooltip,
                      color: theme.colorScheme.outline,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ],
              ),

              // Line 2: Address (tappable → maps)
              if (a.address != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => launchMapNavigation(context, a.address!),
                  child: Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          a.address!,
                          style: TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Line 3: Dates
              if (checkInStr != null || checkOutStr != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: ColorName.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${checkInStr ?? '?'} \u2192 ${checkOutStr ?? '?'}',
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (nights != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '$nights ${l10n.accommodationNights}',
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Line 4: Price
              if (a.pricePerNight != null && !widget.isViewer) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${a.pricePerNight!.toStringAsFixed(0)} ${a.currency ?? 'EUR'}/${l10n.accommodationNights}',
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorName.primary,
                      ),
                    ),
                    if (nights != null) ...[
                      const Spacer(),
                      Text(
                        '${l10n.accommodationTotal} ${(a.pricePerNight! * nights).toStringAsFixed(0)} ${a.currency ?? 'EUR'}',
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Badge: booking reference
              if (a.bookingReference != null &&
                  a.bookingReference!.isNotEmpty &&
                  !widget.isViewer) ...[
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
      ),
    );
  }
}
