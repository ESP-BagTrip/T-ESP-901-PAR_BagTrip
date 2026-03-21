import 'package:intl/intl.dart';

/// Static helper for notification text — no BuildContext needed.
/// Scheduled notifications are pre-computed, so we resolve locale
/// from [Intl.defaultLocale] at scheduling time.
class NotificationStrings {
  NotificationStrings._();

  static bool get _isFrench => (Intl.defaultLocale ?? 'en').startsWith('fr');

  // ── Daily summary ──────────────────────────────────────────────

  static String dailySummaryTitle() =>
      _isFrench ? 'Bonjour !' : 'Good morning!';

  static String dailySummaryBody(int day, String destination) => _isFrench
      ? 'Jour $day à $destination — consultez le programme du jour'
      : 'Day $day in $destination — check today\'s schedule';

  // ── Activity reminder ──────────────────────────────────────────

  static String activityReminderTitle(String title) =>
      _isFrench ? 'Bientôt : $title' : 'Coming up: $title';

  static String activityReminderBody(String? location) {
    if (location != null && location.isNotEmpty) {
      return _isFrench
          ? 'Dans 30 minutes à $location'
          : 'Starting in 30 minutes at $location';
    }
    return _isFrench ? 'Dans 30 minutes' : 'Starting in 30 minutes';
  }

  // ── Checkout reminder ──────────────────────────────────────────

  static String checkoutReminderTitle() =>
      _isFrench ? 'Rappel check-out' : 'Checkout reminder';

  static String checkoutReminderBody(String name) => _isFrench
      ? 'N\'oubliez pas de quitter $name'
      : 'Don\'t forget to check out from $name';

  // ── Packing reminder ──────────────────────────────────────────

  static String packingReminderTitle() =>
      _isFrench ? 'C\'est l\'heure de faire les valises !' : 'Time to pack!';

  static String packingReminderBody(int count, String destination) => _isFrench
      ? '$count articles restants à emballer pour $destination'
      : '$count items left to pack for $destination';
}
