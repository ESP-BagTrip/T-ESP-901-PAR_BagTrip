import 'package:bagtrip/models/notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotification JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'id': 'notif-1',
        'type': 'TRIP_INVITE',
        'title': 'New trip invitation',
        'body': 'You have been invited to join Summer Vacation',
        'data': {'trip_id': 'trip-42', 'inviter': 'alice@example.com'},
        'is_read': true,
        'trip_id': 'trip-42',
        'sent_at': '2024-06-15T09:00:00.000',
        'created_at': '2024-06-15T08:55:00.000',
      };

      final first = AppNotification.fromJson(json);
      final serialized = first.toJson();
      final second = AppNotification.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'notif-1');
      expect(second.type, 'TRIP_INVITE');
      expect(second.title, 'New trip invitation');
      expect(second.body, 'You have been invited to join Summer Vacation');
      expect(second.data, isNotNull);
      expect(second.data!['trip_id'], 'trip-42');
      expect(second.isRead, true);
      expect(second.tripId, 'trip-42');
      expect(second.sentAt, DateTime.parse('2024-06-15T09:00:00.000'));
      expect(second.createdAt, DateTime.parse('2024-06-15T08:55:00.000'));
    });

    test('fromJson with minimal fields applies defaults', () {
      final json = <String, dynamic>{
        'id': 'notif-min',
        'type': 'INFO',
        'title': 'Welcome',
        'body': 'Welcome to BagTrip!',
      };

      final model = AppNotification.fromJson(json);

      expect(model.id, 'notif-min');
      expect(model.type, 'INFO');
      expect(model.title, 'Welcome');
      expect(model.body, 'Welcome to BagTrip!');
      expect(model.isRead, false);
      expect(model.data, isNull);
      expect(model.tripId, isNull);
      expect(model.sentAt, isNull);
      expect(model.createdAt, isNull);
    });

    test('handles nullable fields set to null', () {
      final json = <String, dynamic>{
        'id': 'notif-nulls',
        'type': 'ALERT',
        'title': 'Alert',
        'body': 'Something happened',
        'data': null,
        'trip_id': null,
        'sent_at': null,
        'created_at': null,
      };

      final first = AppNotification.fromJson(json);
      final serialized = first.toJson();
      final second = AppNotification.fromJson(serialized);

      expect(second, first);
      expect(second.isRead, false);
      expect(second.data, isNull);
      expect(second.tripId, isNull);
      expect(second.sentAt, isNull);
      expect(second.createdAt, isNull);
    });
  });
}
