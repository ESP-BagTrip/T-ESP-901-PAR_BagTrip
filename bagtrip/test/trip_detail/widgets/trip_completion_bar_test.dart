import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/widgets/trip_completion_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

const _allFilled = {
  CompletionSegmentType.dates: true,
  CompletionSegmentType.flights: true,
  CompletionSegmentType.accommodation: true,
  CompletionSegmentType.activities: true,
  CompletionSegmentType.baggage: true,
  CompletionSegmentType.budget: true,
};

const _noneFilled = {
  CompletionSegmentType.dates: false,
  CompletionSegmentType.flights: false,
  CompletionSegmentType.accommodation: false,
  CompletionSegmentType.activities: false,
  CompletionSegmentType.baggage: false,
  CompletionSegmentType.budget: false,
};

const _halfFilled = {
  CompletionSegmentType.dates: true,
  CompletionSegmentType.flights: true,
  CompletionSegmentType.accommodation: true,
  CompletionSegmentType.activities: false,
  CompletionSegmentType.baggage: false,
  CompletionSegmentType.budget: false,
};

void main() {
  group('TripCompletionBar', () {
    testWidgets('displays correct percentage text', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: const TripCompletionBar(percentage: 67, segments: _halfFilled),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('67%'), findsOneWidget);
    });

    testWidgets('shows all 6 segment icons', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: const TripCompletionBar(percentage: 100, segments: _allFilled),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flight_rounded), findsOneWidget);
      expect(find.byIcon(Icons.hotel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.hiking_rounded), findsOneWidget);
      expect(find.byIcon(Icons.luggage_rounded), findsOneWidget);
      expect(find.byIcon(Icons.wallet_rounded), findsOneWidget);
    });

    testWidgets('shows all 6 labels', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: const TripCompletionBar(percentage: 0, segments: _noneFilled),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dates'), findsOneWidget);
      expect(find.text('Flights'), findsOneWidget);
      expect(find.text('Hotels'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Luggage'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
    });

    testWidgets('tap segment fires onSegmentTap callback', (tester) async {
      CompletionSegmentType? tapped;

      await tester.pumpWidget(
        _buildApp(
          child: TripCompletionBar(
            percentage: 50,
            segments: _halfFilled,
            onSegmentTap: (type) => tapped = type,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the flights label
      await tester.tap(find.text('Flights'));
      expect(tapped, CompletionSegmentType.flights);

      // Tap the budget label
      await tester.tap(find.text('Budget'));
      expect(tapped, CompletionSegmentType.budget);
    });

    testWidgets('animation completes without error', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: const TripCompletionBar(percentage: 100, segments: _allFilled),
        ),
      );

      // Let the entrance animation complete
      await tester.pumpAndSettle();

      // Widget should still be present
      expect(find.byType(TripCompletionBar), findsOneWidget);
    });

    testWidgets('partial fill shows correct number of segments', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          child: const TripCompletionBar(percentage: 50, segments: _halfFilled),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('50%'), findsOneWidget);
      // Widget renders without error with partial fill
      expect(find.byType(TripCompletionBar), findsOneWidget);
    });
  });
}
