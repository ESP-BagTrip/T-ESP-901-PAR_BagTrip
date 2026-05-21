import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper over `flutter_local_notifications`.
///
/// Scope (SMP-326): the backend owns every *scheduled* notification — they
/// ship as FCM push. This service only renders FCM messages that arrive while
/// the app is in the foreground (Android/iOS suppress FCM's own banner then)
/// and forwards the deep-link payload to the tap handler.
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap?.call(response.payload);
      },
    );
  }

  /// Display a notification immediately (foreground FCM relay).
  ///
  /// [payload] is JSON-encoded and surfaced verbatim to the tap handler so it
  /// can deep-link — pass the FCM message `data` map here.
  static Future<void> show({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bagtrip_notifications',
      'BagTrip Notifications',
      channelDescription: 'Notifications pour BagTrip',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    final payloadString = payload != null ? jsonEncode(payload) : null;
    await _plugin.show(id, title, body, details, payload: payloadString);
  }
}
