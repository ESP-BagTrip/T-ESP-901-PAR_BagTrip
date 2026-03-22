import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/adaptive/adaptive_edit_dialog.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/widgets/date_range_picker_sheet.dart';
import 'package:bagtrip/trip_detail/widgets/trip_completion_bar.dart';
import 'package:bagtrip/trip_detail/widgets/quick_actions_row.dart';
import 'package:bagtrip/trip_detail/widgets/trip_detail_shimmer.dart';
import 'package:bagtrip/trip_detail/widgets/trip_hero_header.dart';
import 'package:bagtrip/trip_detail/widgets/trip_timeline_section.dart';
import 'package:bagtrip/trip_detail/widgets/trip_flights_section.dart';
import 'package:bagtrip/trip_detail/widgets/trip_accommodation_section.dart';
import 'package:bagtrip/trip_detail/widgets/trip_baggage_section.dart';
import 'package:bagtrip/trip_detail/widgets/trip_budget_section.dart';
import 'package:bagtrip/trip_detail/widgets/trip_sharing_section.dart';
import 'package:bagtrip/trip_detail/widgets/travelers_edit_sheet.dart';
import 'package:bagtrip/trips/widgets/trip_section_card.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

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
          if (state is TripDetailLoaded && state.validationError != null) {
            final l10n = AppLocalizations.of(context)!;
            AppSnackBar.showError(context, message: l10n.cannotFinalizeMessage);
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

class _LoadedContent extends StatefulWidget {
  final String tripId;
  final TripDetailLoaded state;

  const _LoadedContent({required this.tripId, required this.state});

  @override
  State<_LoadedContent> createState() => _LoadedContentState();
}

class _LoadedContentState extends State<_LoadedContent> {
  final _sectionKeys = <CompletionSegmentType, GlobalKey>{
    CompletionSegmentType.flights: GlobalKey(),
    CompletionSegmentType.accommodation: GlobalKey(),
    CompletionSegmentType.activities: GlobalKey(),
    CompletionSegmentType.baggage: GlobalKey(),
    CompletionSegmentType.budget: GlobalKey(),
  };

  String get tripId => widget.tripId;
  TripDetailLoaded get state => widget.state;

  bool get _canEdit => state.isOwner && !state.isCompleted;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _refreshAfterReturn(BuildContext context) {
    if (context.mounted) {
      context.read<TripDetailBloc>().add(RefreshTripDetail());
    }
  }

  Future<void> _showTitleEditor(BuildContext context, Trip trip) async {
    final l10n = AppLocalizations.of(context)!;
    final newTitle = await showAdaptiveEditDialog(
      context: context,
      title: l10n.editTripTitle,
      currentValue: trip.title ?? '',
      confirmLabel: l10n.saveButton,
      cancelLabel: l10n.cancelButton,
    );
    if (newTitle != null && newTitle.isNotEmpty && context.mounted) {
      context.read<TripDetailBloc>().add(UpdateTripTitle(title: newTitle));
    }
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    TripDetailLoaded state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<TripDetailBloc>();
    final result = await showTripDateRangePicker(
      context: context,
      currentStart: state.trip.startDate,
      currentEnd: state.trip.endDate,
    );

    if (result == null || !context.mounted) return;

    final newStart = result.start;
    final newEnd = result.end;

    // Check for activities out of range
    final outOfRange = state.activities.where((a) {
      final d = DateTime(a.date.year, a.date.month, a.date.day);
      final s = DateTime(newStart.year, newStart.month, newStart.day);
      final e = DateTime(newEnd.year, newEnd.month, newEnd.day);
      return d.isBefore(s) || d.isAfter(e);
    }).toList();

    if (outOfRange.isNotEmpty && context.mounted) {
      showAdaptiveAlertDialog(
        context: context,
        title: l10n.activitiesOutOfRangeTitle,
        content: l10n.activitiesOutOfRangeMessage(outOfRange.length),
        confirmLabel: l10n.continueButton,
        cancelLabel: l10n.cancelButton,
        isDestructive: true,
        onConfirm: () {
          bloc.add(UpdateTripDates(startDate: newStart, endDate: newEnd));
        },
      );
      return;
    }

    bloc.add(UpdateTripDates(startDate: newStart, endDate: newEnd));
  }

  Future<void> _showTravelersEditor(BuildContext context, Trip trip) async {
    final newCount = await showTravelersEditSheet(
      context: context,
      currentValue: trip.nbTravelers ?? 1,
    );
    if (newCount != null && context.mounted) {
      context.read<TripDetailBloc>().add(
        UpdateTripTravelers(nbTravelers: newCount),
      );
    }
  }

  void _scrollToSection(CompletionSegmentType type) {
    if (type == CompletionSegmentType.dates) {
      // Scroll to top (hero area)
      Scrollable.ensureVisible(
        context,
        duration: AppAnimations.cardTransition,
        curve: AppAnimations.standardCurve,
      );
      return;
    }
    final key = _sectionKeys[type];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: AppAnimations.cardTransition,
        curve: AppAnimations.standardCurve,
      );
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
              tooltip: l10n.backTooltip,
              onPressed: () => const HomeRoute().go(context),
            ),
            actions: [
              if (!state.isViewer)
                IconButton(
                  icon: Icon(
                    AdaptivePlatform.isIOS ? CupertinoIcons.share : Icons.share,
                  ),
                  tooltip: l10n.shareTooltip,
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
              title: GestureDetector(
                onTap: _canEdit ? () => _showTitleEditor(context, trip) : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        trip.title ?? 'Mon voyage',
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_canEdit) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ),
              background: TripHeroHeader(
                trip: trip,
                dateRange: dateRange,
                daysUntilTrip: state.daysUntilTrip,
                currentDay: state.currentDay,
                totalDays: state.totalDays,
                isCompleted: state.isCompleted,
                isOngoing: state.isOngoing,
                isEditable: _canEdit,
                onTapDates: _canEdit
                    ? () => _showDateRangePicker(context, state)
                    : null,
              ),
            ),
          ),

          // ── Viewer read-only banner ─────────────────────────────
          if (state.isViewer)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space8,
                ),
                padding: AppSpacing.allEdgeInsetSpace12,
                decoration: BoxDecoration(
                  color: ColorName.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.medium8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      color: ColorName.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      child: Text(
                        l10n.viewerBadgeReadOnly,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ColorName.primary,
                        ),
                      ),
                    ),
                  ],
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
                    GestureDetector(
                      onTap: _canEdit
                          ? () => _showTravelersEditor(context, trip)
                          : null,
                      child: _StatItem(
                        icon: Icons.people_rounded,
                        value: '${trip.nbTravelers ?? 0}',
                        label: l10n.tripTravelers,
                      ),
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
          if (!state.isViewer)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space24,
                  vertical: AppSpacing.space8,
                ),
                child: TripCompletionBar(
                  percentage: state.completionResult.percentage,
                  segments: state.completionResult.segments,
                  onSegmentTap: _scrollToSection,
                ),
              ),
            ),

          // ── Quick actions ───────────────────────────────────────
          SliverToBoxAdapter(
            child: QuickActionsRow(
              trip: trip,
              tripId: tripId,
              isViewer: state.isViewer,
              isCompleted: state.isCompleted,
              onReturnFromAction: () => _refreshAfterReturn(context),
            ),
          ),

          // ── Timeline section ────────────────────────────────────
          if (state.totalDays > 0)
            SliverToBoxAdapter(
              key: _sectionKeys[CompletionSegmentType.activities],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space24,
                  vertical: AppSpacing.space8,
                ),
                child: TripTimelineSection(
                  trip: trip,
                  activities: state.activities,
                  selectedDayIndex: state.selectedDayIndex,
                  totalDays: state.totalDays,
                  isOwner: state.isOwner,
                  isCompleted: state.isCompleted,
                  tripId: tripId,
                ),
              ),
            ),

          // ── Section cards ───────────────────────────────────────
          SliverPadding(
            padding: AppSpacing.horizontalSpace24,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.space8),
                StaggeredFadeIn(
                  key: _sectionKeys[CompletionSegmentType.flights],
                  index: 0,
                  child: state.deferredLoaded
                      ? TripFlightsSection(
                          flights: state.flights,
                          tripId: tripId,
                          trip: trip,
                          isOwner: state.isOwner,
                          isCompleted: state.isCompleted,
                        )
                      : const _DeferredSectionShimmer(),
                ),
                const SizedBox(height: AppSpacing.space12),
                StaggeredFadeIn(
                  key: _sectionKeys[CompletionSegmentType.accommodation],
                  index: 1,
                  child: state.deferredLoaded
                      ? TripAccommodationSection(
                          accommodations: state.accommodations,
                          tripId: tripId,
                          trip: trip,
                          isOwner: state.isOwner,
                          isCompleted: state.isCompleted,
                        )
                      : const _DeferredSectionShimmer(),
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
                  key: _sectionKeys[CompletionSegmentType.baggage],
                  index: 3,
                  child: state.deferredLoaded
                      ? TripBaggageSection(
                          baggageItems: state.baggageItems,
                          tripId: tripId,
                          trip: trip,
                          isOwner: state.isOwner,
                          isCompleted: state.isCompleted,
                        )
                      : const _DeferredSectionShimmer(),
                ),
                const SizedBox(height: AppSpacing.space12),
                StaggeredFadeIn(
                  key: _sectionKeys[CompletionSegmentType.budget],
                  index: 4,
                  child: state.deferredLoaded
                      ? TripBudgetSection(
                          budgetSummary: state.budgetSummary,
                          tripId: tripId,
                          trip: trip,
                          isOwner: state.isOwner,
                          isCompleted: state.isCompleted,
                        )
                      : const _DeferredSectionShimmer(),
                ),
                const SizedBox(height: AppSpacing.space12),
                StaggeredFadeIn(
                  index: 5,
                  child: state.deferredLoaded
                      ? TripSharingSection(
                          shares: state.shares,
                          tripId: tripId,
                          trip: trip,
                          isOwner: state.isOwner,
                          isCompleted: state.isCompleted,
                        )
                      : const _DeferredSectionShimmer(),
                ),
                const SizedBox(height: AppSpacing.space12),
                StaggeredFadeIn(
                  index: 6,
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
                    final hasDestination =
                        trip.destinationName != null &&
                        trip.destinationName!.isNotEmpty;
                    final hasDates =
                        trip.startDate != null && trip.endDate != null;

                    if (!hasDestination || !hasDates) {
                      final missing = <String>[];
                      if (!hasDestination) {
                        missing.add(l10n.finalizeMissingDestination);
                      }
                      if (!hasDates) {
                        missing.add(l10n.finalizeMissingDates);
                      }
                      showAdaptiveAlertDialog(
                        context: context,
                        title: l10n.cannotFinalizeTitle,
                        content: missing.join('\n'),
                        confirmLabel: 'OK',
                        cancelLabel: l10n.cancelButton,
                      );
                      return;
                    }

                    AppHaptics.medium();
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

// ── Stat Item ────────────────────────────────────────────────────────────────

class _DeferredSectionShimmer extends StatelessWidget {
  const _DeferredSectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.large16,
        ),
      ),
    );
  }
}

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
