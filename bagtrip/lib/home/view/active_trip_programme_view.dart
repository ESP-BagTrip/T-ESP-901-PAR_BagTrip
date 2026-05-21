import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/helpers/selected_day_schedule.dart';
import 'package:bagtrip/home/widgets/active_trip_day_navigator.dart';
import 'package:bagtrip/home/widgets/active_trip_hero.dart';
import 'package:bagtrip/home/widgets/active_trip_nav_pill.dart';
import 'package:bagtrip/home/widgets/now_indicator_row.dart';
import 'package:bagtrip/home/widgets/timeline_activity_row.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActiveTripProgrammeView extends StatefulWidget {
  final HomeActiveTrip state;

  const ActiveTripProgrammeView({super.key, required this.state});

  @override
  State<ActiveTripProgrammeView> createState() =>
      _ActiveTripProgrammeViewState();
}

class _ActiveTripProgrammeViewState extends State<ActiveTripProgrammeView> {
  late int _selectedDayIndex0;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex0 = defaultSelectedDayIndex0(
      trip: widget.state.activeTrip,
      totalDays: widget.state.totalDays,
      now: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;
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

    return ColoredBox(
      color: const Color(0xFFF5F7FA),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.space16,
          MediaQuery.paddingOf(context).top + AppSpacing.space16,
          AppSpacing.space16,
          MediaQuery.paddingOf(context).bottom + AppSpacing.space24,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          ActiveTripHero(
            trip: trip,
            currentDay: state.currentDay,
            totalDays: totalDays,
            weather: state.weatherData,
          ),
          const SizedBox(height: AppSpacing.space16),
          ActiveTripNavPill(
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.space24),
          Text(
            l10n.activeHomeProgrammeTitle,
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 38,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1D2330),
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
                  color: Color(0xFFCDEDEE),
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  l10n.timelineNow.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF34B7A4),
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
                    color: Color(0xFF545A67),
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
                color: Colors.white,
                borderRadius: AppRadius.large24,
              ),
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Text(
                l10n.activeHomeNoActivitiesDay,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF545A67),
                ),
              ),
            )
          else
            ...timeline.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              final isCurrent = schedule.currentActivity?.id == activity.id;
              final isNext = schedule.nextActivity?.id == activity.id;
              final isLast = index == timeline.length - 1;

              return Column(
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
                    isPast: schedule.dayKind == SelectedDayKind.beforeToday,
                  ),
                ],
              );
            }),
          const SizedBox(height: AppSpacing.space24),
        ],
      ),
    );
  }
}
