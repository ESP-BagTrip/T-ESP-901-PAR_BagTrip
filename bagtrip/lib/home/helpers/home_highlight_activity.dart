import 'package:bagtrip/home/helpers/today_activities.dart';
import 'package:bagtrip/models/activity.dart';

/// Highlighted activity for the active-trip home hero bottom panel.
class HomeHighlightActivity {
  const HomeHighlightActivity({
    required this.activity,
    required this.isNow,
    required this.isTomorrow,
    required this.isToday,
  });

  final Activity activity;
  final bool isNow;
  final bool isTomorrow;
  final bool isToday;
}

/// Resolves the activity to surface on the home hero: in progress now, next
/// today, or nearest future day.
HomeHighlightActivity? resolveHomeHighlightActivity(
  List<Activity> allActivities, {
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final tomorrow = today.add(const Duration(days: 1));

  final classified = classifyTodayActivities(
    allActivities: allActivities,
    now: ref,
  );

  if (classified.currentActivity != null) {
    return HomeHighlightActivity(
      activity: classified.currentActivity!,
      isNow: true,
      isTomorrow: false,
      isToday: true,
    );
  }

  if (classified.nextActivity != null) {
    return HomeHighlightActivity(
      activity: classified.nextActivity!,
      isNow: false,
      isTomorrow: false,
      isToday: true,
    );
  }

  final future =
      allActivities.where((a) {
        final ad = a.date;
        if (ad == null) return false;
        final day = DateTime(ad.year, ad.month, ad.day);
        return day.isAfter(today);
      }).toList()..sort((a, b) {
        final ad = a.date!;
        final bd = b.date!;
        final dayCmp = DateTime(
          ad.year,
          ad.month,
          ad.day,
        ).compareTo(DateTime(bd.year, bd.month, bd.day));
        if (dayCmp != 0) return dayCmp;
        final aTime = a.startTime ?? '99:99';
        final bTime = b.startTime ?? '99:99';
        return aTime.compareTo(bTime);
      });

  if (future.isEmpty) return null;

  final activity = future.first;
  final ad = activity.date!;
  final day = DateTime(ad.year, ad.month, ad.day);

  return HomeHighlightActivity(
    activity: activity,
    isNow: false,
    isTomorrow: day == tomorrow,
    isToday: false,
  );
}
