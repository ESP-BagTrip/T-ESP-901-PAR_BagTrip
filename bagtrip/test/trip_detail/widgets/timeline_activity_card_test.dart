import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/trip_detail/widgets/timeline_activity_card.dart';
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
  group('TimelineActivityCard', () {
    testWidgets('renders title, time, and category icon', (tester) async {
      final activity = makeActivity(title: 'Visit Louvre', startTime: '09:30');

      await tester.pumpWidget(
        _buildApp(
          child: TimelineActivityCard(
            activity: activity,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visit Louvre'), findsOneWidget);
      expect(find.text('09:30'), findsOneWidget);
      expect(find.byIcon(Icons.museum_outlined), findsOneWidget);
    });

    testWidgets('SUGGESTED shows AI badge', (tester) async {
      final activity = Activity(
        id: 'a1',
        tripId: 'trip-1',
        title: 'Suggested Activity',
        date: DateTime(2024, 6),
        startTime: '10:00',
        validationStatus: ValidationStatus.suggested,
      );

      await tester.pumpWidget(
        _buildApp(
          child: TimelineActivityCard(
            activity: activity,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI'), findsOneWidget);
    });

    testWidgets('VALIDATED does not show AI badge', (tester) async {
      final activity = Activity(
        id: 'a1',
        tripId: 'trip-1',
        title: 'Validated Activity',
        date: DateTime(2024, 6),
        startTime: '10:00',
        validationStatus: ValidationStatus.validated,
      );

      await tester.pumpWidget(
        _buildApp(
          child: TimelineActivityCard(
            activity: activity,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI'), findsNothing);
    });

    testWidgets('MANUAL does not show AI badge', (tester) async {
      final activity = makeActivity();

      await tester.pumpWidget(
        _buildApp(
          child: TimelineActivityCard(
            activity: activity,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI'), findsNothing);
    });

    testWidgets('SUGGESTED + owner shows validate/reject buttons', (
      tester,
    ) async {
      final activity = Activity(
        id: 'a1',
        tripId: 'trip-1',
        title: 'Suggested',
        date: DateTime(2024, 6),
        startTime: '10:00',
        validationStatus: ValidationStatus.suggested,
      );

      await tester.pumpWidget(
        _buildApp(
          child: TimelineActivityCard(
            activity: activity,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Validate'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('SUGGESTED + viewer hides validate/reject buttons', (
      tester,
    ) async {
      final activity = Activity(
        id: 'a1',
        tripId: 'trip-1',
        title: 'Suggested',
        date: DateTime(2024, 6),
        startTime: '10:00',
        validationStatus: ValidationStatus.suggested,
      );

      await tester.pumpWidget(
        _buildApp(
          child: TimelineActivityCard(
            activity: activity,
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Validate'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets('completed trip hides validate/reject buttons', (tester) async {
      final activity = Activity(
        id: 'a1',
        tripId: 'trip-1',
        title: 'Suggested',
        date: DateTime(2024, 6),
        startTime: '10:00',
        validationStatus: ValidationStatus.suggested,
      );

      await tester.pumpWidget(
        _buildApp(
          child: TimelineActivityCard(
            activity: activity,
            isOwner: true,
            isCompleted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Validate'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets('swipe-to-delete fires onDelete for owner', (tester) async {
      var deleted = false;
      final activity = makeActivity(id: 'del-1');

      await tester.pumpWidget(
        _buildApp(
          child: TimelineActivityCard(
            activity: activity,
            isOwner: true,
            isCompleted: false,
            onDelete: () => deleted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fling to dismiss (needs enough velocity)
      await tester.fling(find.byType(Dismissible), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      expect(deleted, true);
    });

    testWidgets('no startTime shows "All day"', (tester) async {
      final activity = makeActivity(startTime: null);

      await tester.pumpWidget(
        _buildApp(
          child: TimelineActivityCard(
            activity: activity,
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All day'), findsOneWidget);
    });

    testWidgets('location shown when present', (tester) async {
      final activity = Activity(
        id: 'a1',
        tripId: 'trip-1',
        title: 'Dinner',
        date: DateTime(2024, 6),
        startTime: '19:00',
        location: 'Le Jules Verne',
        category: ActivityCategory.food,
      );

      await tester.pumpWidget(
        _buildApp(
          child: TimelineActivityCard(
            activity: activity,
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Le Jules Verne'), findsOneWidget);
      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    });

    testWidgets('non-owner cannot swipe to delete', (tester) async {
      final activity = makeActivity();

      await tester.pumpWidget(
        _buildApp(
          child: TimelineActivityCard(
            activity: activity,
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNothing);
    });
  });
}
