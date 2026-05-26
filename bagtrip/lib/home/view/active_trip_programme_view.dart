import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/review_hero.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/helpers/selected_day_schedule.dart';
import 'package:bagtrip/home/widgets/active_trip_day_navigator.dart';
import 'package:bagtrip/home/widgets/active_trip_hero_status.dart';
import 'package:bagtrip/home/widgets/active_trip_hero_typography.dart';
import 'package:bagtrip/home/widgets/now_indicator_row.dart';
import 'package:bagtrip/home/widgets/timeline_activity_row.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/helpers/trip_hero_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-day schedule for the active trip. Reads live [HomeActiveTrip] from
/// [HomeBloc] when [state] is omitted (production navigation).
class ActiveTripProgrammeView extends StatelessWidget {
  const ActiveTripProgrammeView({super.key, this.state});

  /// Test-only override; production passes null and listens to [HomeBloc].
  final HomeActiveTrip? state;

  @override
  Widget build(BuildContext context) {
    return _ActiveTripProgrammeShell(initialState: state);
  }
}

/// Centralises leaving the programme route (back button, swipe-back, bloc exit).
class _ActiveTripProgrammeShell extends StatefulWidget {
  const _ActiveTripProgrammeShell({this.initialState});

  final HomeActiveTrip? initialState;

  @override
  State<_ActiveTripProgrammeShell> createState() =>
      _ActiveTripProgrammeShellState();
}

class _ActiveTripProgrammeShellState extends State<_ActiveTripProgrammeShell> {
  bool _exitRequested = false;

  /// Clears the nested `/home/active-trip/programme` location. [context.pop]
  /// alone can leave the child path matched and immediately rebuild programme.
  void _leaveProgramme() {
    if (_exitRequested || !mounted) return;
    _exitRequested = true;
    const HomeRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    final content = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leaveProgramme();
      },
      child: _buildContent(),
    );

    if (widget.initialState != null) {
      return content;
    }

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (previous, current) =>
          previous is HomeActiveTrip &&
          current is! HomeActiveTrip &&
          current is! HomeLoading,
      listener: (context, state) => _leaveProgramme(),
      child: content,
    );
  }

  Widget _buildContent() {
    final initial = widget.initialState;
    if (initial != null) {
      return _ActiveTripProgrammeBody(state: initial, onBack: _leaveProgramme);
    }

    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          (current is HomeActiveTrip &&
              (previous is! HomeActiveTrip ||
                  previous.allActivities != current.allActivities ||
                  previous.activeTrip.id != current.activeTrip.id)),
      builder: (context, homeState) {
        if (homeState is! HomeActiveTrip) {
          return const SizedBox.shrink();
        }
        return _ActiveTripProgrammeBody(
          state: homeState,
          onBack: _leaveProgramme,
        );
      },
    );
  }
}

class _ActiveTripProgrammeBody extends StatefulWidget {
  const _ActiveTripProgrammeBody({required this.state, required this.onBack});

  final HomeActiveTrip state;
  final VoidCallback onBack;

  @override
  State<_ActiveTripProgrammeBody> createState() =>
      _ActiveTripProgrammeBodyState();
}

class _ActiveTripProgrammeBodyState extends State<_ActiveTripProgrammeBody> {
  late int _selectedDayIndex0;

  HomeActiveTrip get state => widget.state;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex0 = defaultSelectedDayIndex0(
      trip: state.activeTrip,
      totalDays: state.totalDays,
      now: DateTime.now(),
    );
  }

  @override
  void didUpdateWidget(covariant _ActiveTripProgrammeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.activeTrip.id != state.activeTrip.id) {
      _selectedDayIndex0 = defaultSelectedDayIndex0(
        trip: state.activeTrip,
        totalDays: state.totalDays,
        now: DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trip = state.activeTrip;
    final totalDays = state.totalDays;
    final now = DateTime.now();
    final safeTotalDays = totalDays < 1 ? 1 : totalDays;
    final selectedDayIndex0 = _selectedDayIndex0.clamp(0, safeTotalDays - 1);
    final tripStartDate = trip.startDate ?? now;
    final calendarToday = defaultSelectedDayIndex0(
      trip: trip,
      totalDays: safeTotalDays,
      now: now,
    );
    final schedule = buildScheduleForSelectedDay(
      allActivities: state.allActivities,
      trip: trip,
      selectedDayIndex0: selectedDayIndex0,
      totalDays: safeTotalDays,
      now: now,
    );
    final timeline = schedule.allTimeline;
    final bottomInset =
        MediaQuery.paddingOf(context).bottom + AppSpacing.space24;

    return Scaffold(
      backgroundColor: ColorName.surfaceLight,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ReviewHero(
              coverOverlay: ReviewHeroCoverOverlay.activeTripCard,
              city: tripHeroCity(trip, l10n),
              subtitle: tripHeroDateSubtitle(
                context,
                trip,
                safeTotalDays,
                l10n,
              ),
              cityStyle: ActiveTripHeroTypography.city,
              subtitleStyle: ActiveTripHeroTypography.subtitle,
              budgetLabel: '',
              coverImageUrl: tripHeroCoverImageUrl(trip),
              onBack: widget.onBack,
              statusBadge: ActiveTripHeroStatus(
                currentDay: state.currentDay,
                totalDays: safeTotalDays,
                weather: state.weatherData,
                destinationTimezone: trip.destinationTimezone,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: ColorName.surfaceLight,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.cornerRadius24),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space16,
                  AppSpacing.space16,
                  bottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.activeHomeProgrammeTitle,
                      style: const TextStyle(
                        fontFamily: FontFamily.dMSerifDisplay,
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: ColorName.primaryTrueDark,
                        height: 1.05,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    ActiveTripDayNavigator(
                      totalDays: safeTotalDays,
                      selectedDayIndex0: selectedDayIndex0,
                      tripStartDate: tripStartDate,
                      calendarTodayIndex0: calendarToday,
                      onDaySelected: (index) =>
                          setState(() => _selectedDayIndex0 = index),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    if (timeline.isEmpty)
                      Container(
                        decoration: const BoxDecoration(
                          color: ColorName.surfaceLight,
                          borderRadius: AppRadius.large24,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.space16),
                        child: Text(
                          l10n.activeHomeNoActivitiesDay,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...timeline.asMap().entries.map((entry) {
                        final index = entry.key;
                        final activity = entry.value;
                        final isCurrent =
                            schedule.currentActivity?.id == activity.id;
                        final isNext = schedule.nextActivity?.id == activity.id;
                        final isLast = index == timeline.length - 1;

                        return Column(
                          key: ValueKey(activity.id),
                          children: [
                            if (schedule.dayKind == SelectedDayKind.today &&
                                schedule.nowIndicatorIndex != null &&
                                schedule.nowIndicatorIndex == index)
                              const NowIndicatorRow(),
                            TimelineActivityRow(
                              activity: activity,
                              isCurrent: isCurrent,
                              isNext: isNext,
                              isLast: isLast,
                              isPast:
                                  schedule.dayKind ==
                                  SelectedDayKind.beforeToday,
                              useProgrammeCapsuleColors: true,
                            ),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
