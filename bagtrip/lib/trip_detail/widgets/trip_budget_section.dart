import 'package:bagtrip/budget/widgets/budget_alert_banner.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripBudgetSection extends StatelessWidget {
  final BudgetSummary? budgetSummary;
  final String tripId;
  final Trip trip;
  final bool isOwner;
  final bool isCompleted;

  const TripBudgetSection({
    super.key,
    required this.budgetSummary,
    required this.tripId,
    required this.trip,
    required this.isOwner,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.budgetTitle,
          percentConsumed: budgetSummary?.percentConsumed,
        ),
        const SizedBox(height: 12),
        if (budgetSummary == null)
          _EmptyState(
            isOwner: isOwner,
            isCompleted: isCompleted,
            tripId: tripId,
            trip: trip,
          )
        else
          _BudgetDashboard(
            budgetSummary: budgetSummary!,
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
  final double? percentConsumed;

  const _SectionHeader({required this.title, this.percentConsumed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.wallet_rounded, size: 20, color: AppColors.primary),
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
        if (percentConsumed != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ColorName.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              '${percentConsumed!.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorName.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Budget Dashboard ────────────────────────────────────────────────────────

class _BudgetDashboard extends StatelessWidget {
  final BudgetSummary budgetSummary;
  final String tripId;
  final Trip trip;
  final bool isOwner;
  final bool isCompleted;

  const _BudgetDashboard({
    required this.budgetSummary,
    required this.tripId,
    required this.trip,
    required this.isOwner,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final confirmedRatio = budgetSummary.totalBudget > 0
        ? budgetSummary.confirmedTotal / budgetSummary.totalBudget
        : 0.0;
    final forecastedRatio = budgetSummary.totalBudget > 0
        ? (budgetSummary.confirmedTotal + budgetSummary.forecastedTotal) /
              budgetSummary.totalBudget
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AmountColumn(
              label: l10n.budgetTotal,
              amount: budgetSummary.totalBudget,
              color: AppColors.primary,
              isLarge: true,
            ),
            _AmountColumn(
              label: l10n.budgetSpent,
              amount: budgetSummary.totalSpent,
              color: AppColors.primary,
            ),
            _AmountColumn(
              label: l10n.budgetRemaining,
              amount: budgetSummary.remaining,
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Progress bar ──
        SizedBox(
          height: 8,
          child: ClipRRect(
            borderRadius: AppRadius.small4,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.small4,
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: forecastedRatio.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: AppRadius.small4,
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: confirmedRatio.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.small4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Alert banner ──
        if (budgetSummary.alertLevel != null)
          BudgetAlertBanner(summary: budgetSummary),

        // ── Category breakdown ──
        if (budgetSummary.byCategory.isNotEmpty) ...[
          Text(
            l10n.budgetCategoryBreakdown,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...budgetSummary.byCategory.entries.map((entry) {
            final meta = _categoryMeta(entry.key, l10n);
            final maxVal = budgetSummary.totalSpent > budgetSummary.totalBudget
                ? budgetSummary.totalSpent
                : budgetSummary.totalBudget;
            final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: meta.barColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        meta.label,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${entry.value.toStringAsFixed(2)} \u20ac',
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 4,
                    child: ClipRRect(
                      borderRadius: AppRadius.small4,
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: AppColors.border,
                              borderRadius: AppRadius.small4,
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: meta.barColor,
                                borderRadius: AppRadius.small4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        // ── Manage button ──
        if (isOwner && !isCompleted) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                await BudgetRoute(
                  tripId: tripId,
                  role: trip.role ?? 'OWNER',
                  isCompleted: isCompleted,
                ).push(context);
                if (!context.mounted) return;
                context.read<TripDetailBloc>().add(RefreshTripDetail());
              },
              child: Text(
                l10n.budgetManageAll,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ColorName.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Amount Column ───────────────────────────────────────────────────────────

class _AmountColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isLarge;

  const _AmountColumn({
    required this.label,
    required this.amount,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.hint),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          '${amount.toStringAsFixed(2)} \u20ac',
          style: isLarge
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                )
              : Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
        ),
      ],
    );
  }
}

// ── Category Meta ───────────────────────────────────────────────────────────

class _CategoryMeta {
  final Color barColor;
  final String label;

  const _CategoryMeta({required this.barColor, required this.label});
}

_CategoryMeta _categoryMeta(String key, AppLocalizations l10n) {
  switch (key) {
    case 'flight':
      return _CategoryMeta(
        barColor: AppColors.categoryFlightDark,
        label: l10n.reviewBudgetFlights,
      );
    case 'accommodation':
      return _CategoryMeta(
        barColor: AppColors.categoryAccommodationDark,
        label: l10n.reviewBudgetAccommodation,
      );
    case 'food':
      return _CategoryMeta(
        barColor: AppColors.categoryFoodDark,
        label: l10n.reviewBudgetMeals,
      );
    case 'activity':
      return _CategoryMeta(
        barColor: AppColors.categoryActivityDark,
        label: l10n.reviewBudgetActivities,
      );
    case 'transport':
      return _CategoryMeta(
        barColor: AppColors.categoryTransportDark,
        label: l10n.reviewBudgetTransport,
      );
    default:
      return _CategoryMeta(
        barColor: AppColors.categoryOtherDark,
        label: l10n.reviewBudgetOther,
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
                      Icons.wallet_rounded,
                      size: 36,
                      color: ColorName.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.emptyBudgetTitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.emptyBudgetSubtitle,
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
                icon: Icons.auto_awesome,
                title: l10n.budgetEstimateButton,
                subtitle: l10n.budgetEstimateOptionSubtitle,
                onTap: () async {
                  await BudgetRoute(
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
                icon: Icons.add_card_rounded,
                title: l10n.addExpense,
                subtitle: l10n.budgetAddExpenseSubtitle,
                onTap: () async {
                  await BudgetRoute(
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
