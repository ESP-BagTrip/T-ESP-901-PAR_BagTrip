import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/widgets/trip_status_badge.dart';
import 'package:flutter/material.dart';

enum TripCardVariant { large, compact }

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final TripCardVariant _variant;
  final int completionPercent;

  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.completionPercent = 0,
  }) : _variant = TripCardVariant.compact;

  const TripCard.large({
    super.key,
    required this.trip,
    this.onTap,
    this.completionPercent = 0,
  }) : _variant = TripCardVariant.large;

  const TripCard.compact({
    super.key,
    required this.trip,
    this.onTap,
    this.completionPercent = 0,
  }) : _variant = TripCardVariant.compact;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get _dateRange {
    return [
      if (trip.startDate != null) _formatDate(trip.startDate),
      if (trip.endDate != null) _formatDate(trip.endDate),
    ].join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'trip-${trip.id}',
      child: Material(
        type: MaterialType.transparency,
        child: switch (_variant) {
          TripCardVariant.large => _LargeCard(
            trip: trip,
            onTap: onTap,
            dateRange: _dateRange,
            completionPercent: completionPercent,
          ),
          TripCardVariant.compact => _CompactCard(
            trip: trip,
            onTap: onTap,
            dateRange: _dateRange,
          ),
        },
      ),
    );
  }
}

class _LargeCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final String dateRange;
  final int completionPercent;

  const _LargeCard({
    required this.trip,
    this.onTap,
    required this.dateRange,
    this.completionPercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final destination = trip.destinationName ?? trip.title ?? '';

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.large16,
        child: SizedBox(
          width: double.infinity,
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: image or gradient placeholder
              if (trip.coverImageUrl != null && trip.coverImageUrl!.isNotEmpty)
                OptimizedImage.tripCover(
                  trip.coverImageUrl!,
                  errorWidget: const _GradientPlaceholder(),
                )
              else
                const _GradientPlaceholder(),

              // Gradient overlay
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x99000000)],
                  ),
                ),
              ),

              // Content
              Positioned(
                left: AppSpacing.space16,
                right: AppSpacing.space16,
                bottom: AppSpacing.space16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination.isNotEmpty
                                    ? destination
                                    : 'Untitled trip',
                                style: const TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (dateRange.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  dateRange,
                                  style: TextStyle(
                                    fontFamily: FontFamily.b612,
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        TripStatusBadge(status: trip.status),
                      ],
                    ),
                    if (completionPercent > 0) ...[
                      const SizedBox(height: AppSpacing.space8),
                      ClipRRect(
                        borderRadius: AppRadius.small4,
                        child: LinearProgressIndicator(
                          value: completionPercent / 100,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completionPercent%',
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
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
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorName.primary, ColorName.secondary],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.flight_rounded,
        color: ColorName.surface.withValues(alpha: 0.3),
        size: 48,
      ),
    );
  }
}

class _CompactCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final String dateRange;

  const _CompactCard({required this.trip, this.onTap, required this.dateRange});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: AppRadius.medium8,
                child: SizedBox(
                  width: 80,
                  height: 88,
                  child:
                      trip.coverImageUrl != null &&
                          trip.coverImageUrl!.isNotEmpty
                      ? OptimizedImage.activityImage(
                          trip.coverImageUrl!,
                          errorWidget: const _GradientPlaceholder(),
                        )
                      : const _GradientPlaceholder(),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip.title ?? 'Untitled trip',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: FontFamily.b612,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        TripStatusBadge(status: trip.status),
                      ],
                    ),
                    if (trip.destinationName != null) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trip.destinationName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (dateRange.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateRange,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
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
  }
}
