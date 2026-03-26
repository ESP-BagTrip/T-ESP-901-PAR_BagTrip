import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/widgets/accommodation_booking_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

Widget _buildApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('AccommodationBookingCard', () {
    testWidgets('renders name', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: AccommodationBookingCard(
            accommodation: makeAccommodation(name: 'Grand Hotel'),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grand Hotel'), findsOneWidget);
    });

    testWidgets('renders dates when check-in and check-out are set', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          child: AccommodationBookingCard(
            accommodation: makeAccommodation(
              checkIn: DateTime(2024, 6),
              checkOut: DateTime(2024, 6, 4),
            ),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 Jun'), findsOneWidget);
      expect(find.text('4 Jun'), findsOneWidget);
      expect(find.textContaining('3'), findsWidgets);
    });

    testWidgets('renders total price when pricePerNight and dates set', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          child: AccommodationBookingCard(
            accommodation: makeAccommodation(
              checkIn: DateTime(2024, 6),
              checkOut: DateTime(2024, 6, 3),
              pricePerNight: 100,
              currency: '€',
            ),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2 nights × 100 = 200
      expect(find.text('200 €'), findsOneWidget);
    });

    testWidgets('shows confirmed status badge when bookingReference set', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          child: AccommodationBookingCard(
            accommodation: makeAccommodation(bookingReference: 'BK-1'),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmed'), findsOneWidget);
    });

    testWidgets('shows pending status badge when no bookingReference', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          child: AccommodationBookingCard(
            accommodation: makeAccommodation(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('Dismissible present when owner and not completed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          child: AccommodationBookingCard(
            accommodation: makeAccommodation(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('no Dismissible for viewer', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: AccommodationBookingCard(
            accommodation: makeAccommodation(),
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('no Dismissible when completed', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: AccommodationBookingCard(
            accommodation: makeAccommodation(),
            isOwner: true,
            isCompleted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNothing);
    });
  });
}
