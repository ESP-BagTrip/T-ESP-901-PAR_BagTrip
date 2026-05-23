import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';
part 'notification_preferences.g.dart';

/// User-configurable notification preferences.
///
/// Mirrors the backend contract `GET/PATCH /notifications/preferences`
/// which exchanges **snake_case** keys.
@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    @JsonKey(name: 'push_enabled') @Default(true) bool pushEnabled,
    @JsonKey(name: 'flight_reminders') @Default(true) bool flightReminders,
    @JsonKey(name: 'activity_reminders') @Default(true) bool activityReminders,
    @JsonKey(name: 'trip_updates') @Default(true) bool tripUpdates,
    @JsonKey(name: 'budget_alerts') @Default(true) bool budgetAlerts,
    @Default(true) bool social,
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);
}
