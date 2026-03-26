import 'package:bagtrip/accommodations/widgets/accommodation_card.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    required Accommodation accommodation,
    bool isViewer = false,
    VoidCallback? onDelete,
    VoidCallback? onEdit,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: AccommodationCard(
          accommodation: accommodation,
          isViewer: isViewer,
          onDelete: onDelete,
          onEdit: onEdit,
        ),
      ),
    );
  }

  group('AccommodationCard', () {
    testWidgets('displays accommodation name', (tester) async {
      await tester.pumpWidget(
        buildApp(
          accommodation: const Accommodation(
            id: 'acc-1',
            tripId: 'trip-1',
            name: 'Hotel Luxe',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hotel Luxe'), findsOneWidget);
    });

    testWidgets('tap calls onEdit when provided', (tester) async {
      var editCalled = false;
      await tester.pumpWidget(
        buildApp(
          accommodation: const Accommodation(
            id: 'acc-1',
            tripId: 'trip-1',
            name: 'Hotel Test',
          ),
          onEdit: () => editCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hotel Test'));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });

    testWidgets('long press calls onDelete when provided', (tester) async {
      var deleteCalled = false;
      await tester.pumpWidget(
        buildApp(
          accommodation: const Accommodation(
            id: 'acc-1',
            tripId: 'trip-1',
            name: 'Hotel Delete',
          ),
          onDelete: () => deleteCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Hotel Delete'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    testWidgets('address is tappable with location icon', (tester) async {
      await tester.pumpWidget(
        buildApp(
          accommodation: const Accommodation(
            id: 'acc-1',
            tripId: 'trip-1',
            name: 'Hotel Address',
            address: '10 Rue de Rivoli, Paris',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('10 Rue de Rivoli, Paris'), findsOneWidget);
      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    });

    testWidgets('viewer mode: no delete button', (tester) async {
      await tester.pumpWidget(
        buildApp(
          accommodation: const Accommodation(
            id: 'acc-1',
            tripId: 'trip-1',
            name: 'Hotel Viewer',
            pricePerNight: 100,
            bookingReference: 'REF-123',
          ),
          isViewer: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
      // Price hidden for viewer
      expect(find.textContaining('100'), findsNothing);
      // Booking reference hidden for viewer
      expect(find.text('REF-123'), findsNothing);
    });

    testWidgets('shows booking reference badge when not viewer', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          accommodation: const Accommodation(
            id: 'acc-1',
            tripId: 'trip-1',
            name: 'Hotel Ref',
            bookingReference: 'BK-456',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BK-456'), findsOneWidget);
    });

    testWidgets('shows dates and nights', (tester) async {
      await tester.pumpWidget(
        buildApp(
          accommodation: Accommodation(
            id: 'acc-1',
            tripId: 'trip-1',
            name: 'Hotel Dates',
            checkIn: DateTime(2026, 6),
            checkOut: DateTime(2026, 6, 4),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('3 night(s)'), findsOneWidget);
    });
  });
}
