import 'package:bagtrip/utils/destination_time.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('nowInDestination', () {
    test('returns a DateTime for a valid timezone', () {
      final now = nowInDestination('Europe/Paris');
      expect(now, isA<DateTime>());
    });

    test('returns a DateTime for another valid timezone', () {
      final now = nowInDestination('Asia/Tokyo');
      expect(now, isA<DateTime>());
    });

    test('falls back to device local time when timezone is null', () {
      final now = nowInDestination(null);
      final local = DateTime.now();
      expect(now.difference(local).inSeconds.abs(), lessThan(2));
    });

    test('falls back to device local time when timezone is empty', () {
      final now = nowInDestination('');
      final local = DateTime.now();
      expect(now.difference(local).inSeconds.abs(), lessThan(2));
    });

    test('falls back to device local time for invalid timezone', () {
      final now = nowInDestination('Invalid/Timezone');
      final local = DateTime.now();
      expect(now.difference(local).inSeconds.abs(), lessThan(2));
    });

    test('Paris and Tokyo return different times', () {
      final paris = nowInDestination('Europe/Paris');
      final tokyo = nowInDestination('Asia/Tokyo');
      // Tokyo is always ahead of Paris by 7-8 hours
      // We just verify they are different (unless run at midnight boundary)
      expect(paris.hour != tokyo.hour || paris.day != tokyo.day, isTrue);
    });
  });
}
