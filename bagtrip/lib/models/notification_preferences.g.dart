// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationPreferences _$NotificationPreferencesFromJson(
  Map<String, dynamic> json,
) => _NotificationPreferences(
  pushEnabled: json['push_enabled'] as bool? ?? true,
  flightReminders: json['flight_reminders'] as bool? ?? true,
  activityReminders: json['activity_reminders'] as bool? ?? true,
  tripUpdates: json['trip_updates'] as bool? ?? true,
  budgetAlerts: json['budget_alerts'] as bool? ?? true,
  social: json['social'] as bool? ?? true,
);

Map<String, dynamic> _$NotificationPreferencesToJson(
  _NotificationPreferences instance,
) => <String, dynamic>{
  'push_enabled': instance.pushEnabled,
  'flight_reminders': instance.flightReminders,
  'activity_reminders': instance.activityReminders,
  'trip_updates': instance.tripUpdates,
  'budget_alerts': instance.budgetAlerts,
  'social': instance.social,
};
