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
import 'package:bagtrip/home/helpers/selected_day_schedule.dart';
import 'package:bagtrip/home/widgets/active_trip_day_navigator.dart';
import 'package:bagtrip/home/widgets/active_trip_hero.dart';
import 'package:bagtrip/home/widgets/active_trip_nav_pill.dart';
import 'package:bagtrip/home/widgets/active_trip_quick_actions_section.dart';
import 'package:bagtrip/home/widgets/end_active_trip_sheet.dart';
import 'package:bagtrip/home/widgets/now_indicator_row.dart';
import 'package:bagtrip/home/widgets/quick_expense_sheet.dart';
import 'package:bagtrip/home/widgets/timeline_activity_row.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
  late int _selectedDayIndex0;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex0 = defaultSelectedDayIndex0(
      trip: widget.state.activeTrip,
      totalDays: widget.state.totalDays,
      now: DateTime.now(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = widget.state.pendingCompletionTrip;
      if (pending != null && !_completionDialogShown) {
        _completionDialogShown = true;
        _showCompletionDialog(pending);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ActiveTripHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.activeTrip.id != widget.state.activeTrip.id) {
      _selectedDayIndex0 = defaultSelectedDayIndex0(
        trip: widget.state.activeTrip,
        totalDays: widget.state.totalDays,
        now: DateTime.now(),
      );
    }
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

  int? _calendarTodayIndex0(DateTime tickNow) {
    final t = widget.state.activeTrip;
    if (t.startDate == null) return null;
    final start = DateTime(
      t.startDate!.year,
      t.startDate!.month,
      t.startDate!.day,
    );
    final today = DateTime(tickNow.year, tickNow.month, tickNow.day);
    final d = today.difference(start).inDays;
    if (d < 0 || d >= widget.state.totalDays) return null;
    return d;
  }

  bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _contextChipLabel(
    AppLocalizations l10n,
    DateTime selectedDay,
    DateTime today,
  ) {
    final s = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final t = DateTime(today.year, today.month, today.day);
    if (s.isBefore(t)) return l10n.activeHomeContextPast;
    if (_sameCalendarDay(s, t)) return l10n.activeHomeContextToday;
    if (s.difference(t).inDays == 1) return l10n.activeHomeContextTomorrow;
    return l10n.activeHomeContextTripDay(_selectedDayIndex0 + 1);
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
    final totalDays = widget.state.totalDays;
    final locale = Localizations.localeOf(context).toString();

    final schedule = buildScheduleForSelectedDay(
      allActivities: widget.state.allActivities,
      trip: trip,
      selectedDayIndex0: _selectedDayIndex0,
      totalDays: totalDays,
      now: tickNow,
    );

    final calToday0 = _calendarTodayIndex0(tickNow);
    final todayIdxForNav =
        calToday0 ??
        defaultSelectedDayIndex0(
          trip: trip,
          totalDays: totalDays,
          now: tickNow,
        );

    final todayNavSchedule = buildScheduleForSelectedDay(
      allActivities: widget.state.allActivities,
      trip: trip,
      selectedDayIndex0: todayIdxForNav,
      totalDays: totalDays,
      now: tickNow,
    );

    if (todayNavSchedule.currentActivity != null &&
        todayNavSchedule.currentActivity!.id != _previousCurrentActivityId) {
      if (_previousCurrentActivityId != null) {
        AppHaptics.medium();
      }
      _previousCurrentActivityId = todayNavSchedule.currentActivity!.id;
    } else if (todayNavSchedule.currentActivity == null &&
        _previousCurrentActivityId != null) {
      _previousCurrentActivityId = null;
    }

    final allTimeline = schedule.allTimeline;

    final nowTime =
        '${tickNow.hour.toString().padLeft(2, '0')}:${tickNow.minute.toString().padLeft(2, '0')}';

    int? currentRemainingMinutes;
    if (schedule.dayKind == SelectedDayKind.today &&
        schedule.currentActivity?.endTime != null) {
      final parts = schedule.currentActivity!.endTime!.split(':');
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

    final timelineItemCount = _countTimelineItems(schedule);
    int fi = 0;

    final selectedCal = calendarDateForTripDay(trip, _selectedDayIndex0);
    final todayCal = DateTime(tickNow.year, tickNow.month, tickNow.day);
    final longDate = DateFormat.yMMMMEEEEd(locale).format(selectedCal);

    return ColoredBox(
      color: const Color(0xFFF5F7FA),
      child: CustomScrollView(
        clipBehavior: Clip.none,
        slivers: [
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
                  totalDays: totalDays,
                  weather: widget.state.weatherData,
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

          // Programme unifié
          SliverToBoxAdapter(
            child: StaggeredFadeIn(
              index: fi++,
              child: Padding(
                padding: hPadding.copyWith(top: AppSpacing.space32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.activeHomeProgrammeTitle,
                            style: TextStyle(
                              fontFamily: FontFamily.dMSerifDisplay,
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    ActiveTripDayNavigator(
                      totalDays: totalDays,
                      selectedDayIndex0: _selectedDayIndex0,
                      tripStartDate: trip.startDate!,
                      calendarTodayIndex0: calToday0,
                      onDaySelected: (i) {
                        setState(() => _selectedDayIndex0 = i);
                      },
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space12,
                            vertical: AppSpacing.space8,
                          ),
                          decoration: BoxDecoration(
                            color: ColorName.secondary.withValues(alpha: 0.15),
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            _contextChipLabel(l10n, selectedCal, todayCal),
                            style: const TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ColorName.secondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        Expanded(
                          child: Text(
                            longDate,
                            style: TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedDayIndex0 == totalDays - 1) ...[
                      const SizedBox(height: AppSpacing.space12),
                      Container(
                        width: double.infinity,
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
                                l10n.activeHomeLastTripDayBanner,
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
            ),
          ),

          if (schedule.isEmpty)
            SliverToBoxAdapter(
              child: StaggeredFadeIn(
                index: fi++,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space16),
                  child: ElegantEmptyState(
                    icon: Icons.event_note,
                    title: l10n.activeHomeNoActivitiesDay,
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final items = _buildTimelineItems(
                  allTimeline,
                  schedule,
                  nowTime,
                  currentRemainingMinutes,
                  context,
                  l10n,
                );
                if (index >= items.length) return null;
                return StaggeredFadeIn(
                  index: fi + index,
                  child: Padding(padding: hPadding, child: items[index]),
                );
              }, childCount: timelineItemCount),
            ),

          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final emptyBump = schedule.isEmpty ? 1 : 0;
                final quickIndex = fi + timelineItemCount + emptyBump;
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
                              _resolveNavigateTarget(todayNavSchedule) != null,
                          onNavigate:
                              _resolveNavigateTarget(todayNavSchedule) != null
                              ? () => launchMapNavigation(
                                  context,
                                  _resolveNavigateTarget(todayNavSchedule)!,
                                )
                              : null,
                          onExpense: () =>
                              _showQuickExpenseSheet(context, trip.id),
                          onPhoto: () => launchCamera(context),
                          nextDayEnabled:
                              _selectedDayIndex0 < widget.state.totalDays - 1,
                          onNextDay: _selectedDayIndex0 < totalDays - 1
                              ? () {
                                  setState(() {
                                    _selectedDayIndex0++;
                                  });
                                }
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

          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).bottom + AppSpacing.space24,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveNavigateTarget(SelectedDayScheduleResult todaySch) {
    final loc =
        todaySch.currentActivity?.location ?? todaySch.nextActivity?.location;
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

  int _countTimelineItems(SelectedDayScheduleResult schedule) {
    final hasTimed = schedule.timedActivities.isNotEmpty;
    final hasNow =
        schedule.dayKind == SelectedDayKind.today &&
        schedule.nowIndicatorIndex != null &&
        hasTimed;
    return schedule.allTimeline.length + (hasNow ? 1 : 0);
  }

  String _capsuleBadge(
    AppLocalizations l10n,
    SelectedDayScheduleResult schedule,
    bool isCurrentActivity,
    bool isNext,
    bool isPastSlot,
    int indexInTimeline,
  ) {
    switch (schedule.dayKind) {
      case SelectedDayKind.beforeToday:
        return l10n.scheduleBadgeDone;
      case SelectedDayKind.afterToday:
        return indexInTimeline == 0
            ? l10n.scheduleBadgeNext
            : l10n.scheduleBadgeLater;
      case SelectedDayKind.today:
        if (isCurrentActivity) return l10n.scheduleBadgeNow;
        if (isNext) return l10n.scheduleBadgeNext;
        if (isPastSlot) return l10n.scheduleBadgeDone;
        return l10n.scheduleBadgeLater;
    }
  }

  List<Widget> _buildTimelineItems(
    List<Activity> allTimeline,
    SelectedDayScheduleResult schedule,
    String nowTime,
    int? currentRemainingMinutes,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final items = <Widget>[];
    final allDayCount = schedule.allDayActivities.length;
    final totalCount = allTimeline.length;

    final absNowIdx =
        schedule.dayKind == SelectedDayKind.today &&
            schedule.nowIndicatorIndex != null
        ? allDayCount + schedule.nowIndicatorIndex!
        : null;

    for (int i = 0; i < totalCount; i++) {
      if (absNowIdx != null && i == absNowIdx) {
        items.add(const NowIndicatorRow());
      }

      final activity = allTimeline[i];
      final isCurrentActivity =
          schedule.dayKind == SelectedDayKind.today &&
          schedule.currentActivity != null &&
          activity.id == schedule.currentActivity!.id;
      final isNext =
          schedule.dayKind == SelectedDayKind.today &&
          schedule.nextActivity != null &&
          activity.id == schedule.nextActivity!.id;
      final isPastSlot =
          schedule.dayKind == SelectedDayKind.today &&
          !isCurrentActivity &&
          !isNext &&
          activity.startTime != null &&
          activity.startTime!.compareTo(nowTime) <= 0;

      final strikeThrough =
          schedule.dayKind == SelectedDayKind.beforeToday ||
          (schedule.dayKind == SelectedDayKind.today &&
              isPastSlot &&
              !isCurrentActivity &&
              !isNext);

      final hasLocation =
          activity.location != null && activity.location!.isNotEmpty;

      final capsuleBadge = _capsuleBadge(
        l10n,
        schedule,
        isCurrentActivity,
        isNext,
        isPastSlot,
        i,
      );

      items.add(
        TimelineActivityRow(
          activity: activity,
          isNext: isNext,
          isLast: i == totalCount - 1 && absNowIdx != totalCount,
          isCurrent: isCurrentActivity,
          isPast: isPastSlot,
          minutesUntilNext: isNext ? schedule.minutesUntilNext : null,
          remainingMinutes: isCurrentActivity ? currentRemainingMinutes : null,
          capsuleScheduleBadge: capsuleBadge,
          strikeThroughTitle: strikeThrough,
          contentDimAlpha: strikeThrough ? 0.65 : null,
          onNavigate:
              hasLocation &&
                  !strikeThrough &&
                  schedule.dayKind == SelectedDayKind.today
              ? () => launchMapNavigation(context, activity.location!)
              : null,
        ),
      );
    }

    if (absNowIdx != null && absNowIdx >= totalCount) {
      items.add(const NowIndicatorRow());
    }

    return items;
  }
}
