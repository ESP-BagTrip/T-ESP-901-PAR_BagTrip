import 'package:bagtrip/notifications/notification_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveNotificationRoute', () {
    test('returns null for null data', () {
      expect(resolveNotificationRoute(null), isNull);
    });

    test('returns null when tripId is missing', () {
      expect(resolveNotificationRoute({'screen': 'tripHome'}), isNull);
    });

    test('returns null when tripId is empty', () {
      expect(
        resolveNotificationRoute({'tripId': '', 'screen': 'tripHome'}),
        isNull,
      );
    });

    test('returns null when tripId is not a string', () {
      expect(resolveNotificationRoute({'tripId': 42}), isNull);
    });

    test('routes the feedback screen to the feedback route', () {
      expect(
        resolveNotificationRoute({'tripId': 't1', 'screen': 'feedback'}),
        '/home/t1/feedback',
      );
    });

    test('routes the baggage screen to the baggage route', () {
      expect(
        resolveNotificationRoute({'tripId': 't1', 'screen': 'baggage'}),
        '/home/t1/baggage',
      );
    });

    test('routes the post-trip screen to the post-trip route', () {
      expect(
        resolveNotificationRoute({'tripId': 't1', 'screen': 'post-trip'}),
        '/home/t1/post-trip',
      );
    });

    test('routes the tripHome screen to the trip home', () {
      expect(
        resolveNotificationRoute({'tripId': 't1', 'screen': 'tripHome'}),
        '/home/t1',
      );
    });

    test('routes activities and budget into the trip detail surface', () {
      expect(
        resolveNotificationRoute({'tripId': 't1', 'screen': 'activities'}),
        '/home/t1',
      );
      expect(
        resolveNotificationRoute({'tripId': 't1', 'screen': 'budget'}),
        '/home/t1',
      );
    });

    test('falls back to the trip home for an unknown or missing screen', () {
      expect(
        resolveNotificationRoute({'tripId': 't1', 'screen': 'mystery'}),
        '/home/t1',
      );
      expect(resolveNotificationRoute({'tripId': 't1'}), '/home/t1');
    });
  });
}
