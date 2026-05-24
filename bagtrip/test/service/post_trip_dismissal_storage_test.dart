import 'dart:convert';

import 'package:bagtrip/service/post_trip_dismissal_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PostTripDismissalStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = PostTripDismissalStorage();
  });

  group('PostTripDismissalStorage', () {
    test('wasDismissedRecently is false for an unknown trip', () async {
      expect(await storage.wasDismissedRecently('trip-1'), isFalse);
    });

    test('recordDismissal + wasDismissedRecently returns true', () async {
      await storage.recordDismissal('trip-1');
      expect(await storage.wasDismissedRecently('trip-1'), isTrue);
    });

    test(
      'wasDismissedRecently is false for dismissals older than 24h',
      () async {
        final old = DateTime.now().subtract(const Duration(hours: 25));
        SharedPreferences.setMockInitialValues({
          'post_trip_dismissals': jsonEncode({'trip-1': old.toIso8601String()}),
        });

        expect(
          await PostTripDismissalStorage().wasDismissedRecently('trip-1'),
          isFalse,
        );
      },
    );

    test('wasDismissedRecently is true for dismissals within 24h', () async {
      final recent = DateTime.now().subtract(const Duration(hours: 3));
      SharedPreferences.setMockInitialValues({
        'post_trip_dismissals': jsonEncode({
          'trip-1': recent.toIso8601String(),
        }),
      });

      expect(
        await PostTripDismissalStorage().wasDismissedRecently('trip-1'),
        isTrue,
      );
    });

    test('wasDismissedRecently ignores unparseable timestamps', () async {
      SharedPreferences.setMockInitialValues({
        'post_trip_dismissals': jsonEncode({'trip-1': 'not-a-date'}),
      });

      expect(
        await PostTripDismissalStorage().wasDismissedRecently('trip-1'),
        isFalse,
      );
    });

    test('clearDismissal removes the entry', () async {
      await storage.recordDismissal('trip-1');
      expect(await storage.wasDismissedRecently('trip-1'), isTrue);
      await storage.clearDismissal('trip-1');
      expect(await storage.wasDismissedRecently('trip-1'), isFalse);
    });

    test('dismissals are scoped per trip', () async {
      await storage.recordDismissal('trip-1');
      expect(await storage.wasDismissedRecently('trip-1'), isTrue);
      expect(await storage.wasDismissedRecently('trip-2'), isFalse);
    });
  });
}
