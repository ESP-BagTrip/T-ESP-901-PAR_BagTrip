import 'package:bagtrip/models/activity.dart';

/// Activities grouped by time-of-day for a single day.
class DayActivities {
  final List<Activity> morning;
  final List<Activity> afternoon;
  final List<Activity> evening;
  final List<Activity> allDay;

  const DayActivities({
    this.morning = const [],
    this.afternoon = const [],
    this.evening = const [],
    this.allDay = const [],
  });

  bool get isEmpty =>
      morning.isEmpty && afternoon.isEmpty && evening.isEmpty && allDay.isEmpty;

  int get totalCount =>
      morning.length + afternoon.length + evening.length + allDay.length;
}

/// Groups [activities] into day buckets (1-based) with time-of-day sub-groups.
///
/// Each activity is placed in the day matching
/// `activity.date.difference(tripStartDate).inDays + 1`,
/// then bucketed by [startTime] hour:
///   - `null`  → allDay
///   - `< 12`  → morning
///   - `< 17`  → afternoon
///   - `>= 17` → evening
///
/// Activities outside `[1, totalDays]` are skipped.
Map<int, DayActivities> groupActivitiesByDay({
  required List<Activity> activities,
  required DateTime tripStartDate,
  required int totalDays,
}) {
  final normalizedStart = DateTime(
    tripStartDate.year,
    tripStartDate.month,
    tripStartDate.day,
  );

  // Initialize empty buckets for each day
  final mornings = <int, List<Activity>>{};
  final afternoons = <int, List<Activity>>{};
  final evenings = <int, List<Activity>>{};
  final allDays = <int, List<Activity>>{};

  for (var d = 1; d <= totalDays; d++) {
    mornings[d] = [];
    afternoons[d] = [];
    evenings[d] = [];
    allDays[d] = [];
  }

  for (final activity in activities) {
    final normalizedDate = DateTime(
      activity.date.year,
      activity.date.month,
      activity.date.day,
    );
    final dayNumber = normalizedDate.difference(normalizedStart).inDays + 1;

    if (dayNumber < 1 || dayNumber > totalDays) continue;

    final hour = _parseHour(activity.startTime);
    if (hour == null) {
      allDays[dayNumber]!.add(activity);
    } else if (hour < 12) {
      mornings[dayNumber]!.add(activity);
    } else if (hour < 17) {
      afternoons[dayNumber]!.add(activity);
    } else {
      evenings[dayNumber]!.add(activity);
    }
  }

  // Sort each bucket by startTime ascending (nulls last)
  int compareByStartTime(Activity a, Activity b) {
    final aTime = a.startTime;
    final bTime = b.startTime;
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return aTime.compareTo(bTime);
  }

  final result = <int, DayActivities>{};
  for (var d = 1; d <= totalDays; d++) {
    mornings[d]!.sort(compareByStartTime);
    afternoons[d]!.sort(compareByStartTime);
    evenings[d]!.sort(compareByStartTime);
    allDays[d]!.sort(compareByStartTime);

    result[d] = DayActivities(
      morning: mornings[d]!,
      afternoon: afternoons[d]!,
      evening: evenings[d]!,
      allDay: allDays[d]!,
    );
  }

  return result;
}

int? _parseHour(String? time) {
  if (time == null) return null;
  final parts = time.split(':');
  if (parts.isEmpty) return null;
  return int.tryParse(parts[0]);
}
