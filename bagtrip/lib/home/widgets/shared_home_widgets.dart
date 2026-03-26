import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/material.dart';

class NextTripHero extends StatelessWidget {
  final Trip trip;
  final int? daysUntil;
  final int completionPercent;

  const NextTripHero({
    super.key,
    required this.trip,
    this.daysUntil,
    this.completionPercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = trip.destinationName ?? trip.title ?? '';
    final countdown = daysUntil != null
        ? l10n.nextTripCountdown(daysUntil!)
        : '';

    return Hero(
      tag: 'trip-next-${trip.id}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => TripHomeRoute(tripId: trip.id).go(context),
          borderRadius: AppRadius.large16,
          child: Container(
            width: double.infinity,
            padding: AppSpacing.allEdgeInsetSpace24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ColorName.primary, ColorName.secondary],
              ),
              borderRadius: AppRadius.large16,
              boxShadow: [
                BoxShadow(
                  color: ColorName.primary.withValues(alpha: 0.3),
                  offset: const Offset(0, 6),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ColorName.surface.withValues(alpha: 0.25),
                        borderRadius: AppRadius.medium8,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.flight_takeoff_rounded,
                        color: ColorName.surface,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: ColorName.surface,
                            ),
                          ),
                          if (countdown.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.space4),
                            Text(
                              countdown,
                              style: TextStyle(
                                fontFamily: FontFamily.b612,
                                fontSize: 13,
                                color: ColorName.surface.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: ColorName.surface.withValues(alpha: 0.7),
                      size: 22,
                    ),
                  ],
                ),
                if (completionPercent > 0) ...[
                  const SizedBox(height: AppSpacing.space16),
                  ClipRRect(
                    borderRadius: AppRadius.small4,
                    child: LinearProgressIndicator(
                      value: completionPercent / 100,
                      backgroundColor: ColorName.surface.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        ColorName.surface,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    l10n.homeTripCompletion(completionPercent),
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      color: ColorName.surface.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlanTripCta extends StatelessWidget {
  final AppLocalizations l10n;

  const PlanTripCta({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => const PlanTripRoute().go(context),
        borderRadius: AppRadius.large16,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: AppRadius.large16,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.08),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ColorName.primary, ColorName.secondary],
                  ),
                  borderRadius: AppRadius.medium8,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome,
                  color: ColorName.surface,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.planTripCta,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.planTripCtaSubtitle,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
