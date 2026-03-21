import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/widgets/baggage_checklist_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripBaggageSection extends StatelessWidget {
  final List<BaggageItem> baggageItems;
  final String tripId;
  final Trip trip;
  final bool isOwner;
  final bool isCompleted;

  const TripBaggageSection({
    super.key,
    required this.baggageItems,
    required this.tripId,
    required this.trip,
    required this.isOwner,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final packedCount = baggageItems.where((b) => b.isPacked).length;
    final totalCount = baggageItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────
        _SectionHeader(
          title: l10n.baggageTitle,
          packedCount: packedCount,
          totalCount: totalCount,
        ),
        const SizedBox(height: 12),

        if (baggageItems.isEmpty)
          _EmptyState(
            isOwner: isOwner,
            isCompleted: isCompleted,
            tripId: tripId,
            trip: trip,
          )
        else
          _BaggageList(
            baggageItems: baggageItems,
            tripId: tripId,
            trip: trip,
            isOwner: isOwner,
            isCompleted: isCompleted,
          ),
      ],
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int packedCount;
  final int totalCount;

  const _SectionHeader({
    required this.title,
    required this.packedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.luggage_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (totalCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorName.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '$packedCount/$totalCount',
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorName.primary,
                  ),
                ),
              ),
          ],
        ),
        if (totalCount > 0) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppRadius.pill,
            child: LinearProgressIndicator(
              value: totalCount > 0 ? packedCount / totalCount : 0,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Baggage List ────────────────────────────────────────────────────────────

class _BaggageList extends StatelessWidget {
  final List<BaggageItem> baggageItems;
  final String tripId;
  final Trip trip;
  final bool isOwner;
  final bool isCompleted;

  const _BaggageList({
    required this.baggageItems,
    required this.tripId,
    required this.trip,
    required this.isOwner,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = baggageItems.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...List.generate(preview.length, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < preview.length - 1 ? 12 : 0),
            child: StaggeredFadeIn(
              index: i,
              child: BaggageChecklistCard(
                item: preview[i],
                isOwner: isOwner,
                isCompleted: isCompleted,
                onToggle: () {
                  context.read<TripDetailBloc>().add(
                    ToggleBaggagePackedFromDetail(baggageItemId: preview[i].id),
                  );
                },
                onDelete: () {
                  context.read<TripDetailBloc>().add(
                    DeleteBaggageItemFromDetail(baggageItemId: preview[i].id),
                  );
                },
                onTap: () async {
                  await BaggageRoute(
                    tripId: tripId,
                    role: trip.role ?? 'OWNER',
                    isCompleted: isCompleted,
                  ).push(context);
                  if (!context.mounted) return;
                  context.read<TripDetailBloc>().add(RefreshTripDetail());
                },
              ),
            ),
          );
        }),
        if (baggageItems.length > 3) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await BaggageRoute(
                tripId: tripId,
                role: trip.role ?? 'OWNER',
                isCompleted: isCompleted,
              ).push(context);
              if (!context.mounted) return;
              context.read<TripDetailBloc>().add(RefreshTripDetail());
            },
            child: Text(
              l10n.baggageSectionSeeAll(baggageItems.length),
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorName.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isOwner;
  final bool isCompleted;
  final String tripId;
  final Trip trip;

  const _EmptyState({
    required this.isOwner,
    required this.isCompleted,
    required this.tripId,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: AppSpacing.allEdgeInsetSpace24,
        child: Column(
          children: [
            // Halo icon
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          ColorName.primary.withValues(alpha: 0.08),
                          ColorName.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorName.primary.withValues(alpha: 0.06),
                    ),
                    child: const Icon(
                      Icons.luggage_outlined,
                      size: 36,
                      color: ColorName.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.emptyBaggageTitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.emptyBaggageSubtitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                color: ColorName.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),

            if (isOwner && !isCompleted) ...[
              const SizedBox(height: 20),
              _OptionTile(
                icon: Icons.checklist_rounded,
                title: l10n.baggageSectionAddItem,
                subtitle: l10n.baggageSectionAddItemSubtitle,
                onTap: () async {
                  await BaggageRoute(
                    tripId: tripId,
                    role: trip.role ?? 'OWNER',
                    isCompleted: isCompleted,
                  ).push(context);
                  if (!context.mounted) return;
                  context.read<TripDetailBloc>().add(RefreshTripDetail());
                },
              ),
              const SizedBox(height: 12),
              _OptionTile(
                icon: Icons.auto_awesome,
                title: l10n.baggageSectionAiSuggest,
                subtitle: l10n.baggageSectionAiSuggestSubtitle,
                onTap: () async {
                  await BaggageRoute(
                    tripId: tripId,
                    role: trip.role ?? 'OWNER',
                    isCompleted: isCompleted,
                  ).push(context);
                  if (!context.mounted) return;
                  context.read<TripDetailBloc>().add(RefreshTripDetail());
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Option Tile ─────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.large16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: AppRadius.large16,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorName.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.medium8,
              ),
              child: Icon(icon, color: ColorName.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
