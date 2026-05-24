import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/helpers/day_grouping.dart';

/// Whether the selected calendar day is before, equal to, or after "today"
/// in the destination (using [now] wall clock).
enum SelectedDayKind { beforeToday, today, afterToday }

class SelectedDayScheduleResult {
  final List<Activity> allDayActivities;
  final List<Activity> timedActivities;
  final Activity? nextActivity;
  final Activity? currentActivity;
  final int? nowIndicatorIndex;
  final int? minutesUntilNext;
  final SelectedDayKind dayKind;

  const SelectedDayScheduleResult({
    this.allDayActivities = const [],
    this.timedActivities = const [],
    this.nextActivity,
    this.currentActivity,
    this.nowIndicatorIndex,
    this.minutesUntilNext,
    required this.dayKind,
  });

  bool get isEmpty => allDayActivities.isEmpty && timedActivities.isEmpty;

  List<Activity> get allTimeline => [...allDayActivities, ...timedActivities];
}

/// Calendar date for trip day index 0-based (J1 → index 0).
DateTime calendarDateForTripDay(Trip trip, int dayIndex0) {
  final s = trip.startDate!;
  final start = DateTime(s.year, s.month, s.day);
  return start.add(Duration(days: dayIndex0));
}

SelectedDayKind _compareDayToNow(DateTime selectedDay, DateTime now) {
  final sd = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
  final nd = DateTime(now.year, now.month, now.day);
  final c = sd.compareTo(nd);
  if (c < 0) return SelectedDayKind.beforeToday;
  if (c > 0) return SelectedDayKind.afterToday;
  return SelectedDayKind.today;
}

/// Builds schedule state for [selectedDayIndex0] (0 = J1), using destination [now].
SelectedDayScheduleResult buildScheduleForSelectedDay({
  required List<Activity> allActivities,
  required Trip trip,
  required int selectedDayIndex0,
  required int totalDays,
  required DateTime now,
}) {
  if (trip.startDate == null ||
      selectedDayIndex0 < 0 ||
      selectedDayIndex0 >= totalDays) {
    return const SelectedDayScheduleResult(dayKind: SelectedDayKind.today);
  }

  final grouped = groupActivitiesByDay(
    activities: allActivities,
    tripStartDate: trip.startDate!,
    totalDays: totalDays,
  );
  final dayNumber = selectedDayIndex0 + 1;
  final dayData = grouped[dayNumber] ?? const DayActivities();
  final allDay = List<Activity>.from(dayData.allDay);
  final timed = <Activity>[
    ...dayData.morning,
    ...dayData.afternoon,
    ...dayData.evening,
  ]..sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));

  final selectedCal = calendarDateForTripDay(trip, selectedDayIndex0);
  final dayKind = _compareDayToNow(selectedCal, now);

  if (dayKind == SelectedDayKind.beforeToday) {
    return SelectedDayScheduleResult(
      allDayActivities: allDay,
      timedActivities: timed,
      dayKind: dayKind,
    );
  }

  if (dayKind == SelectedDayKind.afterToday) {
    return SelectedDayScheduleResult(
      allDayActivities: allDay,
      timedActivities: timed,
      dayKind: dayKind,
    );
  }

  // Today in destination — same logic as [classifyTodayActivities] for this day only.
  final nowTime =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  Activity? next;
  for (final a in timed) {
    if (a.startTime != null && a.startTime!.compareTo(nowTime) > 0) {
      next = a;
      break;
    }
  }

  Activity? current;
  for (final a in timed) {
    if (a.startTime == null) continue;
    if (a.startTime!.compareTo(nowTime) <= 0) {
      if (a.endTime != null && a.endTime!.compareTo(nowTime) > 0) {
        current = a;
      } else if (a.endTime == null) {
        final nextStarted = timed.where(
          (b) =>
              b.startTime != null &&
              b.startTime!.compareTo(a.startTime!) > 0 &&
              b.startTime!.compareTo(nowTime) <= 0,
        );
        if (nextStarted.isEmpty) {
          current = a;
        }
      }
    }
  }

  int? nowIdx;
  for (int i = 0; i < timed.length; i++) {
    if (timed[i].startTime!.compareTo(nowTime) > 0) {
      nowIdx = i;
      break;
    }
  }
  if (nowIdx == null && timed.isNotEmpty) {
    final lastTime = timed.last.endTime ?? timed.last.startTime!;
    if (lastTime.compareTo(nowTime) <= 0) {
      nowIdx = timed.length;
    }
  }
  if (nowIdx == null && timed.isNotEmpty) {
    if (timed.first.startTime!.compareTo(nowTime) > 0) {
      nowIdx = 0;
    }
  }

  int? minsUntilNext;
  if (next != null && next.startTime != null) {
    final parts = next.startTime!.split(':');
    if (parts.length == 2) {
      final nh = int.tryParse(parts[0]);
      final nm = int.tryParse(parts[1]);
      if (nh != null && nm != null) {
        final nextM = nh * 60 + nm;
        final nowM = now.hour * 60 + now.minute;
        minsUntilNext = nextM - nowM;
        if (minsUntilNext < 0) minsUntilNext = null;
      }
    }
  }

  return SelectedDayScheduleResult(
    allDayActivities: allDay,
    timedActivities: timed,
    nextActivity: next,
    currentActivity: current,
    nowIndicatorIndex: nowIdx,
    minutesUntilNext: minsUntilNext,
    dayKind: SelectedDayKind.today,
  );
}

/// Default selected day index 0-based: calendar "today" within trip, else 0 or last day.
int defaultSelectedDayIndex0({
  required Trip trip,
  required int totalDays,
  required DateTime now,
}) {
  if (trip.startDate == null || totalDays < 1) return 0;
  final start = DateTime(
    trip.startDate!.year,
    trip.startDate!.month,
    trip.startDate!.day,
  );
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(start).inDays;
  if (diff < 0) return 0;
  if (diff >= totalDays) return totalDays - 1;
  return diff;
}
