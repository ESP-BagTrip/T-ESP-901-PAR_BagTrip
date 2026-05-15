import 'package:bagtrip/l10n/app_localizations.dart';

enum TripDepartureCountdownMode { days, hoursMinutes }

/// Countdown until trip departure for trip-detail panel empty states.
class TripDepartureCountdown {
  const TripDepartureCountdown._({
    required this.mode,
    this.days,
    this.hours,
    this.minutes,
  });

  final TripDepartureCountdownMode mode;
  final int? days;
  final int? hours;
  final int? minutes;

  static TripDepartureCountdown? fromStartDate(
    DateTime? start, {
    DateTime? now,
  }) {
    if (start == null) return null;
    final clock = now ?? DateTime.now();
    final remaining = start.difference(clock);
    if (remaining.isNegative || remaining == Duration.zero) return null;

    if (remaining.inHours >= 48) {
      final departureDay = DateTime(start.year, start.month, start.day);
      final today = DateTime(clock.year, clock.month, clock.day);
      final days = departureDay.difference(today).inDays;
      if (days <= 0) return null;
      return TripDepartureCountdown._(
        mode: TripDepartureCountdownMode.days,
        days: days,
      );
    }

    return TripDepartureCountdown._(
      mode: TripDepartureCountdownMode.hoursMinutes,
      hours: remaining.inHours,
      minutes: remaining.inMinutes % 60,
    );
  }

  String lineLabel(AppLocalizations l10n) {
    switch (mode) {
      case TripDepartureCountdownMode.days:
        return l10n.flightsPanelEmptyCountdownDays(days!);
      case TripDepartureCountdownMode.hoursMinutes:
        return l10n.flightsPanelEmptyCountdownHm(hours!, minutes!);
    }
  }

  String highlightLabel(AppLocalizations l10n) {
    switch (mode) {
      case TripDepartureCountdownMode.days:
        return l10n.flightsPanelEmptyCountdownDaysHighlight(days!);
      case TripDepartureCountdownMode.hoursMinutes:
        return l10n.flightsPanelEmptyCountdownHmHighlight(hours!, minutes!);
    }
  }
}
