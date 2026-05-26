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
import 'package:bagtrip/trip_detail/helpers/trip_hero_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Full-day schedule for the active trip. Reads live [HomeActiveTrip] from
/// [HomeBloc] when [state] is omitted (production navigation).
class ActiveTripProgrammeView extends StatelessWidget {
  const ActiveTripProgrammeView({super.key, this.state});

  /// Test-only override; production passes null and listens to [HomeBloc].
  final HomeActiveTrip? state;

  @override
  Widget build(BuildContext context) {
    if (state != null) {
      return _ActiveTripProgrammeBody(state: state!);
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        return _ActiveTripProgrammeBody(state: homeState);
      },
    );
  }
}

class _ActiveTripProgrammeBody extends StatefulWidget {
  const _ActiveTripProgrammeBody({required this.state});

  final HomeActiveTrip state;

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
    final selectedCalDate = DateTime(
      tripStartDate.year,
      tripStartDate.month,
      tripStartDate.day,
    ).add(Duration(days: selectedDayIndex0));
    final schedule = buildScheduleForSelectedDay(
      allActivities: state.allActivities,
      trip: trip,
      selectedDayIndex0: selectedDayIndex0,
      totalDays: safeTotalDays,
      now: now,
    );
    final timeline = schedule.allTimeline;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final selectedDayLabel = DateFormat(
      'EEEE d MMMM y',
      locale,
    ).format(selectedCalDate);

    return Scaffold(
      backgroundColor: ColorName.surfaceLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReviewHero(
            coverOverlay: ReviewHeroCoverOverlay.activeTripCard,
            city: tripHeroCity(trip, l10n),
            subtitle: tripHeroDateSubtitle(context, trip, safeTotalDays, l10n),
            cityStyle: ActiveTripHeroTypography.city,
            subtitleStyle: ActiveTripHeroTypography.subtitle,
            budgetLabel: '',
            coverImageUrl: tripHeroCoverImageUrl(trip),
            onBack: () => Navigator.of(context).pop(),
            statusBadge: ActiveTripHeroStatus(
              currentDay: state.currentDay,
              totalDays: safeTotalDays,
              weather: state.weatherData,
              destinationTimezone: trip.destinationTimezone,
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: ColorName.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.cornerRadius24),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.cornerRadius24),
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    AppSpacing.space16,
                    AppSpacing.space16,
                    MediaQuery.paddingOf(context).bottom + AppSpacing.space24,
                  ),
                  children: [
                    Text(
                      l10n.activeHomeProgrammeTitle,
                      style: const TextStyle(
                        fontFamily: FontFamily.dMSerifDisplay,
                        fontSize: 38,
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space12,
                            vertical: AppSpacing.space8,
                          ),
                          decoration: const BoxDecoration(
                            color: ColorName.secondaryLight,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            l10n.timelineNow.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ColorName.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        Expanded(
                          child: Text(
                            selectedDayLabel,
                            style: const TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    if (timeline.isEmpty)
                      Container(
                        decoration: const BoxDecoration(
                          color: ColorName.surface,
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
                            ),
                          ],
                        );
                      }),
                    const SizedBox(height: AppSpacing.space24),
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
