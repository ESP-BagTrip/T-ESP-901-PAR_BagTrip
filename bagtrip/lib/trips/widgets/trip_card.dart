import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/widgets/trip_status_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum TripCardVariant { large, compact }

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onArchive;
  final String? role;
  final TripCardVariant _variant;
  final int completionPercent;

  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onShare,
    this.onArchive,
    this.role,
    this.completionPercent = 0,
  }) : _variant = TripCardVariant.compact;

  const TripCard.large({
    super.key,
    required this.trip,
    this.onTap,
    this.onShare,
    this.onArchive,
    this.role,
    this.completionPercent = 0,
  }) : _variant = TripCardVariant.large;

  const TripCard.compact({
    super.key,
    required this.trip,
    this.onTap,
    this.onShare,
    this.onArchive,
    this.role,
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

  List<AdaptiveContextAction> _buildContextActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = <AdaptiveContextAction>[];

    if (onTap != null) {
      actions.add(
        AdaptiveContextAction(
          label: l10n.contextMenuView,
          icon: CupertinoIcons.eye,
          onPressed: onTap!,
        ),
      );
    }
    if (onShare != null) {
      actions.add(
        AdaptiveContextAction(
          label: l10n.contextMenuShare,
          icon: CupertinoIcons.share,
          onPressed: onShare!,
        ),
      );
    }
    if (onArchive != null &&
        role == 'OWNER' &&
        trip.status != TripStatus.completed) {
      actions.add(
        AdaptiveContextAction(
          label: l10n.contextMenuArchive,
          icon: CupertinoIcons.archivebox,
          onPressed: onArchive!,
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final hero = Hero(
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

    return AdaptiveContextMenu(
      actions: _buildContextActions(context),
      previewBuilder: _variant == TripCardVariant.compact
          ? (ctx, animation, child) {
              if (animation.value < CupertinoContextMenu.animationOpensAt) {
                return child;
              }
              return Center(
                child: SizedBox(
                  width: MediaQuery.of(ctx).size.width * 0.9,
                  child: ClipRRect(
                    borderRadius: AppRadius.large16,
                    child: Material(
                      elevation: 4,
                      borderRadius: AppRadius.large16,
                      child: child,
                    ),
                  ),
                ),
              );
            }
          : null,
      child: hero,
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
    final l10n = AppLocalizations.of(context)!;
    final destination = trip.destinationName ?? trip.title ?? '';
    final statusLabel = switch (trip.status) {
      TripStatus.ongoing => l10n.tripStatusOngoing,
      TripStatus.planned || TripStatus.draft => l10n.tripStatusPlanned,
      TripStatus.completed => l10n.tripStatusCompleted,
    };

    return Semantics(
      button: true,
      label: l10n.tripCardSemanticLabel(destination, dateRange, statusLabel),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: AppRadius.large16,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 200),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                // Background: image or gradient placeholder
                if (trip.coverImageUrl != null &&
                    trip.coverImageUrl!.isNotEmpty)
                  OptimizedImage.tripCover(
                    trip.coverImageUrl!,
                    errorWidget: const _GradientPlaceholder(),
                    semanticLabel: l10n.tripCoverImageLabel(destination),
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
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
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
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final destination = trip.destinationName ?? trip.title ?? '';
    final statusLabel = switch (trip.status) {
      TripStatus.ongoing => l10n.tripStatusOngoing,
      TripStatus.planned || TripStatus.draft => l10n.tripStatusPlanned,
      TripStatus.completed => l10n.tripStatusCompleted,
    };

    return Semantics(
      button: true,
      label: l10n.tripCardSemanticLabel(
        trip.title ?? l10n.tripCardNoTitle,
        dateRange,
        statusLabel,
      ),
      excludeSemantics: true,
      child: Card(
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
                            semanticLabel: l10n.tripCoverImageLabel(
                              trip.destinationName ?? destination,
                            ),
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
      ),
    );
  }
}
