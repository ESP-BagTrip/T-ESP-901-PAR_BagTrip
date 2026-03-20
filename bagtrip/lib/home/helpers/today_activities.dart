import 'package:bagtrip/models/activity.dart';

class TodayActivitiesResult {
  final List<Activity> allDayActivities;
  final List<Activity> timedActivities;
  final Activity? nextActivity;
  final List<Activity> tomorrowActivities;

  const TodayActivitiesResult({
    this.allDayActivities = const [],
    this.timedActivities = const [],
    this.nextActivity,
    this.tomorrowActivities = const [],
  });

  bool get isEmpty => allDayActivities.isEmpty && timedActivities.isEmpty;
}

TodayActivitiesResult classifyTodayActivities({
  required List<Activity> allActivities,
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final tomorrow = today.add(const Duration(days: 1));
  final nowTime =
      '${ref.hour.toString().padLeft(2, '0')}:${ref.minute.toString().padLeft(2, '0')}';

  final todayActivities = allActivities.where((a) {
    final d = DateTime(a.date.year, a.date.month, a.date.day);
    return d == today;
  }).toList();

  final allDay = todayActivities.where((a) => a.startTime == null).toList();
  final timed = todayActivities.where((a) => a.startTime != null).toList()
    ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

  Activity? next;
  for (final a in timed) {
    if (a.startTime!.compareTo(nowTime) > 0) {
      next = a;
      break;
    }
  }

  final tomorrowList =
      allActivities.where((a) {
        final d = DateTime(a.date.year, a.date.month, a.date.day);
        return d == tomorrow;
      }).toList()..sort((a, b) {
        final aTime = a.startTime ?? '';
        final bTime = b.startTime ?? '';
        return aTime.compareTo(bTime);
      });

  return TodayActivitiesResult(
    allDayActivities: allDay,
    timedActivities: timed,
    nextActivity: next,
    tomorrowActivities: tomorrowList,
  );
}
