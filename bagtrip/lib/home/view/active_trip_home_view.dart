import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/cubit/quick_expense_cubit.dart';
import 'package:bagtrip/home/cubit/today_tick_cubit.dart';
import 'package:bagtrip/home/helpers/camera_launcher.dart';
import 'package:bagtrip/home/helpers/map_launcher.dart';
import 'package:bagtrip/home/helpers/today_activities.dart';
import 'package:bagtrip/home/widgets/active_trip_hero.dart';
import 'package:bagtrip/home/widgets/active_trip_nav_pill.dart';
import 'package:bagtrip/home/widgets/active_trip_quick_actions_section.dart';
import 'package:bagtrip/home/widgets/active_trip_weather_card.dart';
import 'package:bagtrip/home/widgets/end_active_trip_sheet.dart';
import 'package:bagtrip/home/widgets/now_indicator_row.dart';
import 'package:bagtrip/home/widgets/quick_expense_sheet.dart';
import 'package:bagtrip/home/widgets/timeline_activity_row.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActiveTripHomeView extends StatefulWidget {
  final HomeActiveTrip state;

  const ActiveTripHomeView({super.key, required this.state});

  @override
  State<ActiveTripHomeView> createState() => _ActiveTripHomeViewState();
}

/// Key attached to the "Tomorrow" section header — exported so tests can
/// assert presence/absence of the section (distinct from the
/// [QuickActionsBar] entry which uses the same "Tomorrow" label).
const tomorrowSectionHeaderKey = ValueKey('tomorrow-section-header');

class _ActiveTripHomeViewState extends State<ActiveTripHomeView> {
  String? _previousCurrentActivityId;
  bool _completionDialogShown = false;
  final _tomorrowSectionKey = GlobalKey();

  @override
  void didUpdateWidget(covariant ActiveTripHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pending = widget.state.pendingCompletionTrip;
    final oldPending = oldWidget.state.pendingCompletionTrip;
    if (pending != null && pending.id != oldPending?.id) {
      _completionDialogShown = false;
    }
    if (pending != null && !_completionDialogShown) {
      _completionDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCompletionDialog(pending);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = widget.state.pendingCompletionTrip;
      if (pending != null && !_completionDialogShown) {
        _completionDialogShown = true;
        _showCompletionDialog(pending);
      }
    });
  }

  void _scrollToTomorrow() {
    final target = _tomorrowSectionKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  }

  void _showCompletionDialog(Trip trip) {
    final l10n = AppLocalizations.of(context)!;
    showAdaptiveAlertDialog(
      context: context,
      title: l10n.postTripDetectionTitle,
      content: l10n.postTripDetectionMessage(
        trip.destinationName ?? trip.title ?? '',
      ),
      confirmLabel: l10n.postTripDetectionConfirm,
      cancelLabel: l10n.postTripDetectionRemindLater,
      onConfirm: () {
        context.read<HomeBloc>().add(ConfirmTripCompletion(tripId: trip.id));
      },
      onCancel: () {
        context.read<HomeBloc>().add(DismissTripCompletion(tripId: trip.id));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TodayTickCubit(
        destinationTimezone: widget.state.activeTrip.destinationTimezone,
      ),
      child: BlocBuilder<TodayTickCubit, DateTime>(
        builder: (context, tickNow) {
          return _buildContent(context, tickNow);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, DateTime tickNow) {
    final l10n = AppLocalizations.of(context)!;
    final trip = widget.state.activeTrip;
    final result = classifyTodayActivities(
      allActivities: widget.state.allActivities,
      now: tickNow,
      tripEndDate: trip.endDate,
    );

    // Haptic on current activity change
    if (result.currentActivity != null &&
        result.currentActivity!.id != _previousCurrentActivityId) {
      if (_previousCurrentActivityId != null) {
        AppHaptics.medium();
      }
      _previousCurrentActivityId = result.currentActivity!.id;
    } else if (result.currentActivity == null &&
        _previousCurrentActivityId != null) {
      _previousCurrentActivityId = null;
    }

    final allTimeline = [...result.allDayActivities, ...result.timedActivities];

    final nowTime =
        '${tickNow.hour.toString().padLeft(2, '0')}:${tickNow.minute.toString().padLeft(2, '0')}';

    // Compute remaining minutes for current activity
    int? currentRemainingMinutes;
    if (result.currentActivity?.endTime != null) {
      final parts = result.currentActivity!.endTime!.split(':');
      if (parts.length == 2) {
        final endH = int.tryParse(parts[0]);
        final endM = int.tryParse(parts[1]);
        if (endH != null && endM != null) {
          currentRemainingMinutes =
              (endH * 60 + endM) - (tickNow.hour * 60 + tickNow.minute);
          if (currentRemainingMinutes < 0) currentRemainingMinutes = null;
        }
      }
    }

    final hPadding = EdgeInsets.only(
      left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
      right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
    );

    final timelineItemCount = _countTimelineItems(allTimeline, result);
    int fi = 0;

    return ColoredBox(
      color: const Color(0xFFF5F7FA),
      child: CustomScrollView(
        slivers: [
          // Hero
          SliverToBoxAdapter(
            child: StaggeredFadeIn(
              index: fi++,
              child: Padding(
                padding: hPadding.copyWith(
                  top: MediaQuery.paddingOf(context).top + AppSpacing.space16,
                ),
                child: ActiveTripHero(
                  trip: trip,
                  currentDay: widget.state.currentDay,
                  totalDays: widget.state.totalDays,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: StaggeredFadeIn(
              index: fi++,
              child: Padding(
                padding: hPadding.copyWith(top: AppSpacing.space16),
                child: const ActiveTripNavPill(),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: StaggeredFadeIn(
              index: fi++,
              child: Padding(
                padding: hPadding.copyWith(top: AppSpacing.space16),
                child: ActiveTripWeatherCard(
                  weather: widget.state.weatherData,
                  destinationLabel: trip.destinationName ?? trip.title ?? '',
                ),
              ),
            ),
          ),

          // Today's schedule header
          SliverToBoxAdapter(
            child: StaggeredFadeIn(
              index: fi++,
              child: Padding(
                padding: hPadding.copyWith(top: AppSpacing.space32),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.homeTodayActivities,
                        style: TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (result.currentActivity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space12,
                          vertical: AppSpacing.space4,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF34B7A4),
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(
                          l10n.homeSectionNowBadge,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Timeline or empty state
          if (allTimeline.isEmpty)
            SliverToBoxAdapter(
              child: StaggeredFadeIn(
                index: fi++,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space16),
                  child: ElegantEmptyState(
                    icon: Icons.event_note,
                    title: l10n.homeNoActivitiesToday,
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                // Build combined list: all-day + timed with now indicator
                final items = _buildTimelineItems(
                  allTimeline,
                  result,
                  nowTime,
                  tickNow,
                  currentRemainingMinutes,
                  context,
                );
                if (index >= items.length) return null;
                return StaggeredFadeIn(
                  index: fi + index,
                  child: Padding(padding: hPadding, child: items[index]),
                );
              }, childCount: timelineItemCount),
            ),

          // Tomorrow section
          if (result.tomorrowActivities.isNotEmpty) ...[
            SliverToBoxAdapter(
              key: _tomorrowSectionKey,
              child: Builder(
                builder: (context) {
                  final tomorrowHeaderIndex = fi + timelineItemCount;
                  return StaggeredFadeIn(
                    index: tomorrowHeaderIndex,
                    child: Padding(
                      padding: hPadding.copyWith(top: AppSpacing.space32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.activeTripsTomorrow,
                                style: TextStyle(
                                  fontFamily: FontFamily.dMSans,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space8),
                              Text(
                                l10n.activeTripsTomorrowCount(
                                  result.tomorrowActivities.length,
                                ),
                                style: TextStyle(
                                  fontFamily: FontFamily.dMSans,
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (result.isTomorrowLastDay) ...[
                            const SizedBox(height: AppSpacing.space8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space12,
                                vertical: AppSpacing.space8,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFE8B3),
                                borderRadius: AppRadius.large24,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: ColorName.warning,
                                  ),
                                  const SizedBox(width: AppSpacing.space8),
                                  Expanded(
                                    child: Text(
                                      l10n.activeTripsTomorrowLastDay,
                                      style: const TextStyle(
                                        fontFamily: FontFamily.dMSans,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _CollapsibleTomorrowSection(
                activities: result.tomorrowActivities,
                hPadding: hPadding,
                baseFadeIndex: fi + timelineItemCount + 1,
              ),
            ),
          ],

          // Quick actions
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final tomorrowBlock = result.tomorrowActivities.isNotEmpty
                    ? result.tomorrowActivities.length + 2
                    : 0;
                final emptyBump = allTimeline.isEmpty ? 1 : 0;
                final quickIndex =
                    fi + timelineItemCount + tomorrowBlock + emptyBump;
                return StaggeredFadeIn(
                  index: quickIndex,
                  child: Padding(
                    padding: hPadding.copyWith(top: AppSpacing.space32),
                    child: Column(
                      key: tomorrowSectionHeaderKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.activeTripsQuickActions,
                          style: TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space16),
                        ActiveTripQuickActionsSection(
                          navigateEnabled:
                              _resolveNavigateTarget(result) != null,
                          onNavigate: _resolveNavigateTarget(result) != null
                              ? () => launchMapNavigation(
                                  context,
                                  _resolveNavigateTarget(result)!,
                                )
                              : null,
                          onExpense: () =>
                              _showQuickExpenseSheet(context, trip.id),
                          onPhoto: () => launchCamera(context),
                          tomorrowEnabled: result.tomorrowActivities.isNotEmpty,
                          onTomorrow: result.tomorrowActivities.isNotEmpty
                              ? _scrollToTomorrow
                              : null,
                          onEndTrip: () => showEndActiveTripSheet(context),
                          destinationLabel: () {
                            final raw =
                                trip.destinationName ?? trip.title ?? '';
                            return raw.trim().isNotEmpty
                                ? raw.trim()
                                : l10n.tripCardNoDestination;
                          }(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom padding (tab bar hidden on this screen; keep safe area only)
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).bottom + AppSpacing.space24,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveNavigateTarget(TodayActivitiesResult result) {
    final loc =
        result.currentActivity?.location ?? result.nextActivity?.location;
    return (loc != null && loc.isNotEmpty) ? loc : null;
  }

  void _showQuickExpenseSheet(BuildContext context, String tripId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => QuickExpenseCubit(),
        child: QuickExpenseSheet(tripId: tripId),
      ),
    );
  }

  int _countTimelineItems(List allTimeline, TodayActivitiesResult result) {
    // Count: allTimeline items + 1 for now indicator (if applicable)
    final hasNowIndicator =
        result.nowIndicatorIndex != null && result.timedActivities.isNotEmpty;
    return allTimeline.length + (hasNowIndicator ? 1 : 0);
  }

  List<Widget> _buildTimelineItems(
    List allTimeline,
    TodayActivitiesResult result,
    String nowTime,
    DateTime tickNow,
    int? currentRemainingMinutes,
    BuildContext context,
  ) {
    final items = <Widget>[];
    final allDayCount = result.allDayActivities.length;
    final totalCount = allTimeline.length;

    // The now indicator index is relative to timedActivities.
    // In allTimeline, timed activities start at allDayCount.
    final absNowIdx = result.nowIndicatorIndex != null
        ? allDayCount + result.nowIndicatorIndex!
        : null;

    for (int i = 0; i < totalCount; i++) {
      // Insert now indicator before this item if needed
      if (absNowIdx != null && i == absNowIdx) {
        items.add(const NowIndicatorRow());
      }

      final activity = allTimeline[i];
      final isCurrentActivity =
          result.currentActivity != null &&
          activity.id == result.currentActivity!.id;
      final isNext = activity == result.nextActivity;
      final isPast =
          !isCurrentActivity &&
          !isNext &&
          activity.startTime != null &&
          activity.startTime!.compareTo(nowTime) <= 0;

      final hasLocation =
          activity.location != null && activity.location!.isNotEmpty;

      items.add(
        TimelineActivityRow(
          activity: activity,
          isNext: isNext,
          isLast: i == totalCount - 1 && absNowIdx != totalCount,
          isCurrent: isCurrentActivity,
          isPast: isPast,
          minutesUntilNext: isNext ? result.minutesUntilNext : null,
          remainingMinutes: isCurrentActivity ? currentRemainingMinutes : null,
          onNavigate: hasLocation
              ? () => launchMapNavigation(context, activity.location!)
              : null,
        ),
      );
    }

    // Now indicator at end (all activities are past)
    if (absNowIdx != null && absNowIdx >= totalCount) {
      items.add(const NowIndicatorRow());
    }

    return items;
  }
}

class _CollapsibleTomorrowSection extends StatefulWidget {
  final List activities;
  final EdgeInsets hPadding;
  final int baseFadeIndex;

  const _CollapsibleTomorrowSection({
    required this.activities,
    required this.hPadding,
    required this.baseFadeIndex,
  });

  @override
  State<_CollapsibleTomorrowSection> createState() =>
      _CollapsibleTomorrowSectionState();
}

class _CollapsibleTomorrowSectionState
    extends State<_CollapsibleTomorrowSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _chevronController;
  late Animation<double> _chevronRotation;

  @override
  void initState() {
    super.initState();
    _chevronController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _chevronRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _chevronController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showAll = _expanded || widget.activities.length <= 3;
    final displayCount = showAll ? widget.activities.length : 3;

    return Column(
      children: [
        for (int i = 0; i < displayCount; i++)
          StaggeredFadeIn(
            index: widget.baseFadeIndex + i,
            child: Padding(
              padding: widget.hPadding,
              child: TimelineActivityRow(
                activity: widget.activities[i],
                isLast: i == displayCount - 1 && showAll,
              ),
            ),
          ),
        if (widget.activities.length > 3)
          Padding(
            padding: widget.hPadding.copyWith(top: AppSpacing.space8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                  if (_expanded) {
                    _chevronController.forward();
                  } else {
                    _chevronController.reverse();
                  }
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded
                        ? l10n.activeTripsTomorrowCollapse
                        : l10n.activeTripsTomorrowShowAll(
                            widget.activities.length,
                          ),
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorName.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  RotationTransition(
                    turns: _chevronRotation,
                    child: const Icon(
                      Icons.expand_more,
                      size: 18,
                      color: ColorName.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
