import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/widgets/trip_detail_shimmer.dart';
import 'package:bagtrip/trip_detail/widgets/trip_hero_header.dart';
import 'package:bagtrip/trips/widgets/trip_section_card.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripDetailView extends StatelessWidget {
  final String tripId;

  const TripDetailView({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<TripDetailBloc, TripDetailState>(
        listener: (context, state) {
          if (state is TripDetailDeleted) {
            const HomeRoute().go(context);
          }
          if (state is TripDetailError) {
            AppSnackBar.showError(
              context,
              message: toUserFriendlyMessage(
                state.error,
                AppLocalizations.of(context)!,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TripDetailLoading) {
            return const TripDetailShimmer();
          }

          if (state is TripDetailError) {
            return ErrorView(
              message: toUserFriendlyMessage(
                state.error,
                AppLocalizations.of(context)!,
              ),
              onRetry: () => context.read<TripDetailBloc>().add(
                LoadTripDetail(tripId: tripId),
              ),
            );
          }

          if (state is TripDetailLoaded) {
            return _LoadedContent(tripId: tripId, state: state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LoadedContent extends StatelessWidget {
  final String tripId;
  final TripDetailLoaded state;

  const _LoadedContent({required this.tripId, required this.state});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _refreshAfterReturn(BuildContext context) {
    if (context.mounted) {
      context.read<TripDetailBloc>().add(RefreshTripDetail());
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final dateRange = [
      if (trip.startDate != null) _formatDate(trip.startDate),
      if (trip.endDate != null) _formatDate(trip.endDate),
    ].join(' - ');

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TripDetailBloc>().add(RefreshTripDetail());
      },
      child: CustomScrollView(
        slivers: [
          // ── SliverAppBar with hero ──────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: Icon(
                AdaptivePlatform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
              ),
              onPressed: () => const HomeRoute().go(context),
            ),
            actions: [
              if (!state.isViewer)
                IconButton(
                  icon: Icon(
                    AdaptivePlatform.isIOS ? CupertinoIcons.share : Icons.share,
                  ),
                  onPressed: () => SharesRoute(
                    tripId: tripId,
                    role: trip.role ?? 'OWNER',
                  ).go(context),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 56,
                bottom: 16,
                right: 56,
              ),
              title: Text(
                trip.title ?? 'Mon voyage',
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: TripHeroHeader(
                trip: trip,
                dateRange: dateRange,
                daysUntilTrip: state.daysUntilTrip,
                currentDay: state.currentDay,
                totalDays: state.totalDays,
                isCompleted: state.isCompleted,
                isOngoing: state.isOngoing,
              ),
            ),
          ),

          // ── Read-only banner ────────────────────────────────────
          if (state.isCompleted)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space8,
                ),
                padding: AppSpacing.allEdgeInsetSpace12,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppRadius.medium8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AppColors.hint),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(child: Text(l10n.tripCompletedReadOnly)),
                  ],
                ),
              ),
            ),

          // ── Stats row ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space24,
                vertical: AppSpacing.space8,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: AppRadius.large20,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      offset: const Offset(0, 2),
                      blurRadius: 12,
                    ),
                    BoxShadow(color: AppColors.shadowFaint, blurRadius: 4),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      icon: Icons.people_rounded,
                      value: '${trip.nbTravelers ?? 0}',
                      label: l10n.tripTravelers,
                    ),
                    if (state.daysUntilTrip != null)
                      _StatItem(
                        icon: Icons.timer_rounded,
                        value: '${state.daysUntilTrip}',
                        label: l10n.tripDaysRemaining,
                      ),
                    if (state.totalDays > 0)
                      _StatItem(
                        icon: Icons.date_range_rounded,
                        value: '${state.totalDays}',
                        label: l10n.tripTravelDays,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Completion bar ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space24,
                vertical: AppSpacing.space8,
              ),
              child: _CompletionBar(percentage: state.completionPercentage),
            ),
          ),

          // ── Quick actions ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _QuickActions(
              trip: trip,
              isViewer: state.isViewer,
              tripId: tripId,
            ),
          ),

          // ── Section cards ───────────────────────────────────────
          SliverPadding(
            padding: AppSpacing.horizontalSpace24,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.space8),
                StaggeredFadeIn(
                  index: 0,
                  child: TripSectionCard(
                    icon: Icons.flight_rounded,
                    title: l10n.transportsTitle,
                    itemCount: state.flights.length,
                    previewItems: state.flights
                        .take(3)
                        .map((f) => f.flightNumber)
                        .toList(),
                    emptyLabel: l10n.addFirstTransport,
                    onTap: () async {
                      await TransportsRoute(
                        tripId: tripId,
                        role: trip.role ?? 'OWNER',
                        isCompleted: state.isCompleted,
                      ).push(context);
                      if (!context.mounted) return;
                      _refreshAfterReturn(context);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),
                StaggeredFadeIn(
                  index: 1,
                  child: TripSectionCard(
                    icon: Icons.hotel_rounded,
                    title: l10n.accommodationsTitle,
                    itemCount: state.accommodations.length,
                    previewItems: state.accommodations
                        .take(3)
                        .map((a) => a.name)
                        .toList(),
                    emptyLabel: l10n.addFirstAccommodation,
                    onTap: () async {
                      await AccommodationsRoute(
                        tripId: tripId,
                        role: trip.role ?? 'OWNER',
                        isCompleted: state.isCompleted,
                        tripStartDate: trip.startDate?.toIso8601String(),
                        tripEndDate: trip.endDate?.toIso8601String(),
                      ).push(context);
                      if (!context.mounted) return;
                      _refreshAfterReturn(context);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),
                StaggeredFadeIn(
                  index: 2,
                  child: TripSectionCard(
                    icon: Icons.hiking_rounded,
                    title: l10n.activitiesTitle,
                    itemCount: state.activities.length,
                    previewItems: state.activities
                        .take(3)
                        .map((a) => a.title)
                        .toList(),
                    emptyLabel: l10n.addFirstActivity,
                    onTap: () async {
                      await ActivitiesRoute(
                        tripId: tripId,
                        role: trip.role ?? 'OWNER',
                        isCompleted: state.isCompleted,
                      ).push(context);
                      if (!context.mounted) return;
                      _refreshAfterReturn(context);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),
                StaggeredFadeIn(
                  index: 3,
                  child: TripSectionCard(
                    icon: Icons.luggage_rounded,
                    title: l10n.baggageTitle,
                    itemCount: state.baggageItems.length,
                    previewItems: state.baggageItems.isNotEmpty
                        ? [
                            '${state.baggagePackedCount}/${state.baggageItems.length} packed',
                          ]
                        : const [],
                    emptyLabel: l10n.addFirstBaggage,
                    onTap: () async {
                      await BaggageRoute(
                        tripId: tripId,
                        role: trip.role ?? 'OWNER',
                        isCompleted: state.isCompleted,
                      ).push(context);
                      if (!context.mounted) return;
                      _refreshAfterReturn(context);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),
                StaggeredFadeIn(
                  index: 4,
                  child: TripSectionCard(
                    icon: Icons.wallet_rounded,
                    title: l10n.budgetTitle,
                    itemCount: state.budgetSummary != null ? 1 : 0,
                    previewItems: state.budgetSummary != null
                        ? [
                            '${state.budgetSummary!.totalSpent.toStringAsFixed(0)} spent',
                            if (state.budgetSummary!.alertLevel != null)
                              state.budgetSummary!.alertLevel!,
                          ]
                        : const [],
                    emptyLabel: l10n.addFirstBudget,
                    onTap: () async {
                      await BudgetRoute(
                        tripId: tripId,
                        role: trip.role ?? 'OWNER',
                        isCompleted: state.isCompleted,
                      ).push(context);
                      if (!context.mounted) return;
                      _refreshAfterReturn(context);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),
                StaggeredFadeIn(
                  index: 5,
                  child: TripSectionCard(
                    icon: Icons.map_rounded,
                    title: l10n.mapTitle,
                    itemCount: 0,
                    previewItems: const [],
                    emptyLabel: l10n.mapComingSoonShort,
                    onTap: () => MapRoute(tripId: tripId).go(context),
                  ),
                ),
              ]),
            ),
          ),

          // ── Status action buttons ───────────────────────────────
          if (trip.status == TripStatus.draft && !state.isViewer)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space24,
                  vertical: AppSpacing.space8,
                ),
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<TripDetailBloc>().add(
                      UpdateTripStatus(status: 'PLANNED'),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: Text(l10n.markAsReady),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

          if (trip.status == TripStatus.ongoing && !state.isViewer)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.allEdgeInsetSpace24,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<TripDetailBloc>().add(
                      UpdateTripStatus(status: 'COMPLETED'),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l10n.tripComplete),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

          if (state.isCompleted)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space24,
                  vertical: AppSpacing.space8,
                ),
                child: OutlinedButton.icon(
                  onPressed: () => FeedbackRoute(tripId: tripId).go(context),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(l10n.tripGiveReview),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

          if (trip.status == TripStatus.draft && !state.isViewer)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space24,
                  vertical: AppSpacing.space8,
                ),
                child: OutlinedButton.icon(
                  onPressed: () {
                    showAdaptiveAlertDialog(
                      context: context,
                      title: l10n.tripDeleteTitle,
                      content: l10n.tripDeleteConfirm,
                      confirmLabel: l10n.deleteButton,
                      cancelLabel: l10n.cancelButton,
                      isDestructive: true,
                      onConfirm: () {
                        context.read<TripDetailBloc>().add(DeleteTripDetail());
                      },
                    );
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.tripDeleteTitle),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

          // ── Bottom padding ──────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: AdaptivePlatform.isIOS ? 100 : AppSpacing.space32,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion Bar ───────────────────────────────────────────────────────────

class _CompletionBar extends StatelessWidget {
  final int percentage;

  const _CompletionBar({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final segments = percentage ~/ 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$percentage%',
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorName.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: Row(
                children: List.generate(5, (i) {
                  final isFilled = i < segments;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: 6,
                      margin: EdgeInsets.only(right: i < 4 ? 3 : 0),
                      decoration: BoxDecoration(
                        color: isFilled
                            ? ColorName.primary
                            : ColorName.shimmerBase,
                        borderRadius: AppRadius.pill,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final Trip trip;
  final bool isViewer;
  final String tripId;

  const _QuickActions({
    required this.trip,
    required this.isViewer,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _buildActions(context);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space24,
        vertical: AppSpacing.space8,
      ),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space12),
          itemBuilder: (_, i) => actions[i],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final theme = Theme.of(context);

    if (isViewer) {
      return [
        _QuickActionChip(
          icon: Icons.flight_rounded,
          label: 'Flights',
          theme: theme,
          onTap: () => TransportsRoute(
            tripId: tripId,
            role: 'VIEWER',
            isCompleted: trip.status == TripStatus.completed,
          ).push(context),
        ),
        _QuickActionChip(
          icon: Icons.hiking_rounded,
          label: 'Activities',
          theme: theme,
          onTap: () => ActivitiesRoute(
            tripId: tripId,
            role: 'VIEWER',
            isCompleted: trip.status == TripStatus.completed,
          ).push(context),
        ),
      ];
    }

    return switch (trip.status) {
      TripStatus.draft || TripStatus.planned => [
        _QuickActionChip(
          icon: Icons.flight_rounded,
          label: 'Add flight',
          theme: theme,
          onTap: () async {
            await TransportsRoute(
              tripId: tripId,
              role: trip.role ?? 'OWNER',
            ).push(context);
            if (context.mounted) {
              context.read<TripDetailBloc>().add(RefreshTripDetail());
            }
          },
        ),
        _QuickActionChip(
          icon: Icons.hotel_rounded,
          label: 'Add hotel',
          theme: theme,
          onTap: () async {
            await AccommodationsRoute(
              tripId: tripId,
              role: trip.role ?? 'OWNER',
              tripStartDate: trip.startDate?.toIso8601String(),
              tripEndDate: trip.endDate?.toIso8601String(),
            ).push(context);
            if (context.mounted) {
              context.read<TripDetailBloc>().add(RefreshTripDetail());
            }
          },
        ),
        _QuickActionChip(
          icon: Icons.hiking_rounded,
          label: 'Add activity',
          theme: theme,
          onTap: () async {
            await ActivitiesRoute(
              tripId: tripId,
              role: trip.role ?? 'OWNER',
            ).push(context);
            if (context.mounted) {
              context.read<TripDetailBloc>().add(RefreshTripDetail());
            }
          },
        ),
      ],
      TripStatus.ongoing => [
        _QuickActionChip(
          icon: Icons.wallet_rounded,
          label: 'Expense',
          theme: theme,
          onTap: () async {
            await BudgetRoute(
              tripId: tripId,
              role: trip.role ?? 'OWNER',
            ).push(context);
            if (context.mounted) {
              context.read<TripDetailBloc>().add(RefreshTripDetail());
            }
          },
        ),
        _QuickActionChip(
          icon: Icons.hiking_rounded,
          label: 'Activities',
          theme: theme,
          onTap: () async {
            await ActivitiesRoute(
              tripId: tripId,
              role: trip.role ?? 'OWNER',
            ).push(context);
            if (context.mounted) {
              context.read<TripDetailBloc>().add(RefreshTripDetail());
            }
          },
        ),
      ],
      TripStatus.completed => [
        _QuickActionChip(
          icon: Icons.rate_review_outlined,
          label: 'Memories',
          theme: theme,
          onTap: () => FeedbackRoute(tripId: tripId).go(context),
        ),
      ],
    };
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: AppRadius.large16,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              offset: const Offset(0, 1),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ColorName.primary, size: 24),
            const SizedBox(height: AppSpacing.space4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 11,
                color: ColorName.textMutedLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Item ────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: ColorName.primary, size: 24),
        const SizedBox(height: AppSpacing.space4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorName.primaryTrueDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 11,
            color: ColorName.textMutedLight,
          ),
        ),
      ],
    );
  }
}
