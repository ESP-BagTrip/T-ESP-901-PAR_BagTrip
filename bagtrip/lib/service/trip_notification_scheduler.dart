import 'dart:convert';
import 'dart:developer' as dev;

import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/repositories/baggage_repository.dart';
import 'package:bagtrip/service/local_notification_service.dart';
import 'package:bagtrip/service/notification_strings.dart';
import 'package:timezone/timezone.dart' as tz;

/// Thin abstraction over notification scheduling for testability.
abstract class NotificationScheduleService {
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  });
  Future<void> cancel(int id);
}

/// Default implementation that delegates to [LocalNotificationService].
class DefaultNotificationScheduleService
    implements NotificationScheduleService {
  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) => LocalNotificationService.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: scheduledDate,
    payload: payload,
  );

  @override
  Future<void> cancel(int id) => LocalNotificationService.cancel(id);
}

class TripNotificationScheduler {
  final ActivityRepository _activityRepository;
  final AccommodationRepository _accommodationRepository;
  final BaggageRepository _baggageRepository;
  final NotificationScheduleService _notificationService;

  TripNotificationScheduler({
    required ActivityRepository activityRepository,
    required AccommodationRepository accommodationRepository,
    required BaggageRepository baggageRepository,
    NotificationScheduleService? notificationService,
  }) : _activityRepository = activityRepository,
       _accommodationRepository = accommodationRepository,
       _baggageRepository = baggageRepository,
       _notificationService =
           notificationService ?? DefaultNotificationScheduleService();

  // ── Public API ───────────────────────────────────────────────

  /// Schedule all notifications for an ONGOING trip.
  /// Idempotent: cancels existing ones first, then reschedules.
  Future<void> scheduleOngoingNotifications(Trip trip) async {
    try {
      await cancelTripNotifications(trip);

      final now = DateTime.now();
      final startDate = trip.startDate;
      final endDate = trip.endDate;
      if (startDate == null || endDate == null) return;

      final destination = trip.destinationName ?? trip.title ?? '';

      // ── Daily summaries ──
      final firstDay = now.isAfter(startDate) ? now : startDate;
      final today = DateTime(firstDay.year, firstDay.month, firstDay.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      for (
        var day = today;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))
      ) {
        final dayOffset =
            day
                .difference(
                  DateTime(startDate.year, startDate.month, startDate.day),
                )
                .inDays +
            1;
        final scheduledDate = tz.TZDateTime.local(
          day.year,
          day.month,
          day.day,
          8, // 08:00
        );
        if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) continue;

        await _notificationService.zonedSchedule(
          id: stableId('daily_${trip.id}_$dayOffset'),
          title: NotificationStrings.dailySummaryTitle(),
          body: NotificationStrings.dailySummaryBody(dayOffset, destination),
          scheduledDate: scheduledDate,
          payload: _tripPayload(trip.id, 'tripHome'),
        );
      }

      // ── Activity reminders (30 min before) ──
      final activitiesResult = await _activityRepository.getActivities(trip.id);
      if (activitiesResult is Success<List<Activity>>) {
        for (final activity in activitiesResult.data) {
          if (activity.startTime == null) continue;
          final time = _parseTime(activity.startTime!);
          if (time == null) continue;

          final actDate = activity.date;
          final actDateTime = DateTime(
            actDate.year,
            actDate.month,
            actDate.day,
            time.$1,
            time.$2,
          );

          // 30 minutes before
          final reminderTime = actDateTime.subtract(
            const Duration(minutes: 30),
          );
          final scheduledDate = tz.TZDateTime.local(
            reminderTime.year,
            reminderTime.month,
            reminderTime.day,
            reminderTime.hour,
            reminderTime.minute,
          );
          if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) continue;

          await _notificationService.zonedSchedule(
            id: stableId('activity_${activity.id}'),
            title: NotificationStrings.activityReminderTitle(activity.title),
            body: NotificationStrings.activityReminderBody(activity.location),
            scheduledDate: scheduledDate,
            payload: _tripPayload(trip.id, 'activities'),
          );
        }
      }

      // ── Checkout reminders (09:00 on checkout day) ──
      final accommodationsResult = await _accommodationRepository.getByTrip(
        trip.id,
      );
      if (accommodationsResult is Success<List<Accommodation>>) {
        for (final acc in accommodationsResult.data) {
          if (acc.checkOut == null) continue;
          final co = acc.checkOut!;
          final scheduledDate = tz.TZDateTime.local(
            co.year,
            co.month,
            co.day,
            9, // 09:00
          );
          if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) continue;

          await _notificationService.zonedSchedule(
            id: stableId('checkout_${acc.id}'),
            title: NotificationStrings.checkoutReminderTitle(),
            body: NotificationStrings.checkoutReminderBody(acc.name),
            scheduledDate: scheduledDate,
            payload: _tripPayload(trip.id, 'tripHome'),
          );
        }
      }
    } catch (e) {
      dev.log('TripNotificationScheduler.scheduleOngoing error: $e');
    }
  }

  /// Schedule packing reminder 2 days before a PLANNED trip at 18:00.
  Future<void> schedulePackingReminder(Trip trip) async {
    try {
      final startDate = trip.startDate;
      if (startDate == null) return;

      final reminderDate = tz.TZDateTime.local(
        startDate.year,
        startDate.month,
        startDate.day - 2,
        18, // 18:00
      );
      if (reminderDate.isBefore(tz.TZDateTime.now(tz.local))) return;

      final destination = trip.destinationName ?? trip.title ?? '';

      // Fetch baggage to count unpacked items
      int unpackedCount = 0;
      final baggageResult = await _baggageRepository.getByTrip(trip.id);
      if (baggageResult is Success<List<BaggageItem>>) {
        unpackedCount = baggageResult.data
            .where((item) => !item.isPacked)
            .length;
      }
      if (unpackedCount == 0) return;

      await _notificationService.zonedSchedule(
        id: stableId('packing_${trip.id}'),
        title: NotificationStrings.packingReminderTitle(),
        body: NotificationStrings.packingReminderBody(
          unpackedCount,
          destination,
        ),
        scheduledDate: reminderDate,
        payload: _tripPayload(trip.id, 'baggage'),
      );
    } catch (e) {
      dev.log('TripNotificationScheduler.schedulePackingReminder error: $e');
    }
  }

  /// Schedule a completion reminder notification 24h from now.
  Future<void> scheduleCompletionReminder(Trip trip) async {
    try {
      final scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(hours: 24));
      final destination = trip.destinationName ?? trip.title ?? '';

      await _notificationService.zonedSchedule(
        id: stableId('completion_${trip.id}'),
        title: NotificationStrings.completionReminderTitle(),
        body: NotificationStrings.completionReminderBody(destination),
        scheduledDate: scheduledDate,
        payload: _tripPayload(trip.id, 'tripHome'),
      );
    } catch (e) {
      dev.log('TripNotificationScheduler.scheduleCompletionReminder error: $e');
    }
  }

  /// Cancel all local notifications for a specific trip.
  /// Recomputes all possible IDs to avoid persisting ID lists.
  Future<void> cancelTripNotifications(Trip trip) async {
    try {
      final startDate = trip.startDate;
      final endDate = trip.endDate;

      // Cancel packing reminder
      await _notificationService.cancel(stableId('packing_${trip.id}'));

      // Cancel completion reminder
      await _notificationService.cancel(stableId('completion_${trip.id}'));

      // Cancel daily summaries
      if (startDate != null && endDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day);
        final totalDays = end.difference(start).inDays + 1;
        for (var i = 1; i <= totalDays; i++) {
          await _notificationService.cancel(stableId('daily_${trip.id}_$i'));
        }
      }

      // Cancel activity reminders
      final activitiesResult = await _activityRepository.getActivities(trip.id);
      if (activitiesResult is Success<List<Activity>>) {
        for (final activity in activitiesResult.data) {
          await _notificationService.cancel(
            stableId('activity_${activity.id}'),
          );
        }
      }

      // Cancel checkout reminders
      final accommodationsResult = await _accommodationRepository.getByTrip(
        trip.id,
      );
      if (accommodationsResult is Success<List<Accommodation>>) {
        for (final acc in accommodationsResult.data) {
          await _notificationService.cancel(stableId('checkout_${acc.id}'));
        }
      }
    } catch (e) {
      dev.log('TripNotificationScheduler.cancelTripNotifications error: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────

  /// Deterministic positive 31-bit int via djb2 hash.
  static int stableId(String key) {
    var hash = 5381;
    for (var i = 0; i < key.length; i++) {
      hash = ((hash << 5) + hash) + key.codeUnitAt(i);
    }
    return hash & 0x7FFFFFFF; // positive 31-bit
  }

  static (int, int)? _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour, minute);
  }

  static String _tripPayload(String tripId, String screen) {
    return jsonEncode({'screen': screen, 'tripId': tripId});
  }
}
