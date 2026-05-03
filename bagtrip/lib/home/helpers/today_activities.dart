import 'package:bagtrip/models/activity.dart';

class TodayActivitiesResult {
  final List<Activity> allDayActivities;
  final List<Activity> timedActivities;
  final Activity? nextActivity;
  final List<Activity> tomorrowActivities;
  final Activity? currentActivity;
  final int? nowIndicatorIndex;
  final int? minutesUntilNext;
  final bool isTomorrowLastDay;

  const TodayActivitiesResult({
    this.allDayActivities = const [],
    this.timedActivities = const [],
    this.nextActivity,
    this.tomorrowActivities = const [],
    this.currentActivity,
    this.nowIndicatorIndex,
    this.minutesUntilNext,
    this.isTomorrowLastDay = false,
  });

  bool get isEmpty => allDayActivities.isEmpty && timedActivities.isEmpty;
}

TodayActivitiesResult classifyTodayActivities({
  required List<Activity> allActivities,
  DateTime? now,
  DateTime? tripEndDate,
}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final tomorrow = today.add(const Duration(days: 1));
  final nowTime =
      '${ref.hour.toString().padLeft(2, '0')}:${ref.minute.toString().padLeft(2, '0')}';

  final todayActivities = allActivities.where((a) {
    // Undated AI recommendations (FOOD / TRANSPORT) never match a
    // specific calendar day.
    if (a.date == null) return false;
    final activityDate = a.date!;
    final d = DateTime(
      activityDate.year,
      activityDate.month,
      activityDate.day,
    );
    return d == today;
  }).toList();

  final allDay = todayActivities.where((a) => a.startTime == null).toList();
  final timed = todayActivities.where((a) => a.startTime != null).toList()
    ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

  // Find next activity (first with startTime > now)
  Activity? next;
  for (final a in timed) {
    if (a.startTime!.compareTo(nowTime) > 0) {
      next = a;
      break;
    }
  }

  // Find current activity (startTime <= now && endTime > now)
  Activity? current;
  for (final a in timed) {
    if (a.startTime!.compareTo(nowTime) <= 0) {
      if (a.endTime != null && a.endTime!.compareTo(nowTime) > 0) {
        current = a;
      } else if (a.endTime == null) {
        // No end time — consider current if it's the latest started before now
        // and there's no subsequent started activity
        final nextStarted = timed.where(
          (b) =>
              b.startTime!.compareTo(a.startTime!) > 0 &&
              b.startTime!.compareTo(nowTime) <= 0,
        );
        if (nextStarted.isEmpty) {
          current = a;
        }
      }
    }
  }

  // Compute nowIndicatorIndex: position in timed list where now falls
  int? nowIdx;
  for (int i = 0; i < timed.length; i++) {
    if (timed[i].startTime!.compareTo(nowTime) > 0) {
      nowIdx = i;
      break;
    }
  }
  // If all activities are before now, put indicator at the end
  if (nowIdx == null && timed.isNotEmpty) {
    final lastTime = timed.last.endTime ?? timed.last.startTime!;
    if (lastTime.compareTo(nowTime) <= 0) {
      nowIdx = timed.length;
    }
  }
  // If all activities are after now, put indicator at the beginning
  if (nowIdx == null && timed.isNotEmpty) {
    if (timed.first.startTime!.compareTo(nowTime) > 0) {
      nowIdx = 0;
    }
  }

  // Minutes until next activity
  int? minsUntilNext;
  if (next != null && next.startTime != null) {
    final parts = next.startTime!.split(':');
    if (parts.length == 2) {
      final nextHour = int.tryParse(parts[0]);
      final nextMinute = int.tryParse(parts[1]);
      if (nextHour != null && nextMinute != null) {
        final nextMinutes = nextHour * 60 + nextMinute;
        final nowMinutes = ref.hour * 60 + ref.minute;
        minsUntilNext = nextMinutes - nowMinutes;
        if (minsUntilNext < 0) minsUntilNext = null;
      }
    }
  }

  // Tomorrow activities
  final tomorrowList =
      allActivities.where((a) {
        if (a.date == null) return false;
        final activityDate = a.date!;
        final d = DateTime(
          activityDate.year,
          activityDate.month,
          activityDate.day,
        );
        return d == tomorrow;
      }).toList()..sort((a, b) {
        final aTime = a.startTime ?? '';
        final bTime = b.startTime ?? '';
        return aTime.compareTo(bTime);
      });

  // Check if tomorrow is the last day
  bool isTomorrowLast = false;
  if (tripEndDate != null) {
    final endDay = DateTime(
      tripEndDate.year,
      tripEndDate.month,
      tripEndDate.day,
    );
    isTomorrowLast = tomorrow == endDay;
  }

  return TodayActivitiesResult(
    allDayActivities: allDay,
    timedActivities: timed,
    nextActivity: next,
    tomorrowActivities: tomorrowList,
    currentActivity: current,
    nowIndicatorIndex: nowIdx,
    minutesUntilNext: minsUntilNext,
    isTomorrowLastDay: isTomorrowLast,
  );
}
