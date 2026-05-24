// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/models/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPreferences', () {
    test('fromJson parses snake_case keys', () {
      final json = {
        'push_enabled': true,
        'flight_reminders': false,
        'activity_reminders': true,
        'trip_updates': false,
        'budget_alerts': true,
        'social': false,
      };

      final prefs = NotificationPreferences.fromJson(json);

      expect(prefs.pushEnabled, true);
      expect(prefs.flightReminders, false);
      expect(prefs.activityReminders, true);
      expect(prefs.tripUpdates, false);
      expect(prefs.budgetAlerts, true);
      expect(prefs.social, false);
    });

    test('fromJson applies defaults (true) for missing keys', () {
      final prefs = NotificationPreferences.fromJson(<String, dynamic>{});

      expect(prefs.pushEnabled, true);
      expect(prefs.flightReminders, true);
      expect(prefs.activityReminders, true);
      expect(prefs.tripUpdates, true);
      expect(prefs.budgetAlerts, true);
      expect(prefs.social, true);
    });

    test('toJson emits snake_case keys', () {
      const prefs = NotificationPreferences(
        pushEnabled: false,
        flightReminders: true,
        activityReminders: false,
        tripUpdates: true,
        budgetAlerts: false,
        social: true,
      );

      final json = prefs.toJson();

      expect(json['push_enabled'], false);
      expect(json['flight_reminders'], true);
      expect(json['activity_reminders'], false);
      expect(json['trip_updates'], true);
      expect(json['budget_alerts'], false);
      expect(json['social'], true);
      // No camelCase leakage.
      expect(json.containsKey('pushEnabled'), false);
    });

    test('toJson/fromJson roundtrip preserves values', () {
      const prefs = NotificationPreferences(
        pushEnabled: true,
        flightReminders: false,
        activityReminders: false,
        tripUpdates: true,
        budgetAlerts: true,
        social: false,
      );

      final restored = NotificationPreferences.fromJson(prefs.toJson());

      expect(restored, prefs);
    });
  });
}
