import 'package:bagtrip/models/trip_share.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TripShare JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'id': 'share-1',
        'trip_id': 'trip-1',
        'user_id': 'user-42',
        'role': 'EDITOR',
        'invited_at': '2024-06-10T16:00:00.000',
        'user_email': 'bob@example.com',
        'user_full_name': 'Bob Martin',
      };

      final first = TripShare.fromJson(json);
      final serialized = first.toJson();
      final second = TripShare.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'share-1');
      expect(second.tripId, 'trip-1');
      expect(second.userId, 'user-42');
      expect(second.role, 'EDITOR');
      expect(second.invitedAt, DateTime.parse('2024-06-10T16:00:00.000'));
      expect(second.userEmail, 'bob@example.com');
      expect(second.userFullName, 'Bob Martin');
    });

    test('fromJson with minimal fields applies defaults', () {
      final json = <String, dynamic>{
        'id': 'share-min',
        'trip_id': 'trip-min',
        'user_id': 'user-min',
        'user_email': 'min@example.com',
      };

      final model = TripShare.fromJson(json);

      expect(model.id, 'share-min');
      expect(model.tripId, 'trip-min');
      expect(model.userId, 'user-min');
      expect(model.userEmail, 'min@example.com');
      expect(model.role, 'VIEWER');
      expect(model.invitedAt, isNull);
      expect(model.userFullName, isNull);
    });

    test('handles nullable fields set to null', () {
      final json = <String, dynamic>{
        'id': 'share-nulls',
        'trip_id': 'trip-nulls',
        'user_id': 'user-nulls',
        'user_email': 'nulls@example.com',
        'invited_at': null,
        'user_full_name': null,
      };

      final first = TripShare.fromJson(json);
      final serialized = first.toJson();
      final second = TripShare.fromJson(serialized);

      expect(second, first);
      expect(second.role, 'VIEWER');
      expect(second.invitedAt, isNull);
      expect(second.userFullName, isNull);
    });

    test('fromJson with status and inviteToken fields', () {
      final json = <String, dynamic>{
        'id': 'share-pending',
        'trip_id': 'trip-1',
        'user_email': 'pending@example.com',
        'status': 'pending',
        'invite_token': 'abc-123-token',
      };

      final model = TripShare.fromJson(json);

      expect(model.id, 'share-pending');
      expect(model.status, 'pending');
      expect(model.inviteToken, 'abc-123-token');
      expect(model.userId, isNull);
    });

    test('fromJson defaults status to active and inviteToken to null', () {
      final json = <String, dynamic>{
        'id': 'share-active',
        'trip_id': 'trip-1',
        'user_id': 'user-1',
        'user_email': 'active@example.com',
      };

      final model = TripShare.fromJson(json);

      expect(model.status, 'active');
      expect(model.inviteToken, isNull);
    });
  });
}
