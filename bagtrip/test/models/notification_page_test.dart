import 'package:bagtrip/models/notification_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPage', () {
    test('fromJson parses the snake_case API envelope', () {
      final page = NotificationPage.fromJson({
        'items': [
          {
            'id': 'n-1',
            'type': 'TRIP_STARTED',
            'title': 'Bon voyage',
            'body': 'Profitez bien',
            'data': <String, dynamic>{},
            'is_read': false,
            'trip_id': 't-1',
            'sent_at': null,
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        ],
        'total': 1,
        'page': 1,
        'limit': 20,
        'total_pages': 3,
        'unread_count': 5,
      });

      expect(page.items.length, 1);
      expect(page.items.first.id, 'n-1');
      expect(page.total, 1);
      expect(page.totalPages, 3);
      expect(page.unreadCount, 5);
    });

    test('fromJson applies defaults for missing fields', () {
      final page = NotificationPage.fromJson(<String, dynamic>{});

      expect(page.items, isEmpty);
      expect(page.total, 0);
      expect(page.page, 1);
      expect(page.totalPages, 0);
      expect(page.unreadCount, 0);
    });

    test('hasMore is true only while the current page is below totalPages', () {
      expect(const NotificationPage(totalPages: 3).hasMore, isTrue);
      expect(const NotificationPage(page: 3, totalPages: 3).hasMore, isFalse);
    });
  });
}
