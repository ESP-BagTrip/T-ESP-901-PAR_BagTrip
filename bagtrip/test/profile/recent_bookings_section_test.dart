import 'package:bagtrip/models/recent_booking.dart';
import 'package:bagtrip/profile/widgets/recent_bookings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

RecentBooking _booking({String status = 'CAPTURED', String id = 'b-1'}) =>
    RecentBooking(
      id: id,
      details: status,
      date: DateTime(2026, 4, 25),
      priceTotal: 289,
      currency: 'EUR',
      status: status,
    );

void main() {
  group('RecentBookingsSection', () {
    testWidgets('shows "no bookings" copy when list is empty', (tester) async {
      await pumpLocalized(
        tester,
        const RecentBookingsSection(recentBookings: []),
      );
      expect(find.text('No recent bookings'), findsOneWidget);
    });

    testWidgets('renders one row per booking', (tester) async {
      await pumpLocalized(
        tester,
        RecentBookingsSection(
          recentBookings: [
            _booking(),
            _booking(id: 'b-2'),
          ],
        ),
      );
      // 2 booking rows → 2 calendar icons (one per row).
      expect(find.byIcon(Icons.calendar_today_outlined), findsNWidgets(2));
    });

    testWidgets('long-press on a row invokes the callback with that booking', (
      tester,
    ) async {
      RecentBooking? tapped;
      await pumpLocalized(
        tester,
        RecentBookingsSection(
          recentBookings: [_booking(id: 'captured-1')],
          onLongPressBooking: (b) => tapped = b,
        ),
      );

      // Long-press anywhere on the row.
      await tester.longPress(find.byIcon(Icons.flight));
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.id, 'captured-1');
    });

    testWidgets('without callback long-press is a no-op', (tester) async {
      // No assertion beyond "doesn't crash" — the absence of a callback
      // means the GestureDetector should silently ignore the gesture.
      await pumpLocalized(
        tester,
        RecentBookingsSection(recentBookings: [_booking()]),
      );
      await tester.longPress(find.byIcon(Icons.flight));
      await tester.pump();
    });
  });
}
