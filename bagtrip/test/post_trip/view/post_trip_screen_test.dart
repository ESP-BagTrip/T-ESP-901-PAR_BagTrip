import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/post_trip/bloc/post_trip_bloc.dart';
import 'package:bagtrip/post_trip/view/post_trip_view.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class MockPostTripBloc extends Mock implements PostTripBloc {}

void main() {
  late MockPostTripBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoadPostTripStats(tripId: 'fallback'));
  });

  setUp(() {
    mockBloc = MockPostTripBloc();
    when(() => mockBloc.close()).thenAnswer((_) async {});
    when(() => mockBloc.add(any())).thenReturn(null);
  });

  Widget buildApp(PostTripState state) {
    when(() => mockBloc.state).thenReturn(state);
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<PostTripBloc>.value(
        value: mockBloc,
        child: const PostTripView(tripId: 'trip-1'),
      ),
    );
  }

  PostTripLoaded makeLoadedState({
    int totalDays = 7,
    int activitiesCompleted = 5,
    int totalActivities = 8,
    double budgetSpent = 500,
    double budgetTotal = 1000,
    String destinationName = 'Paris',
    Set<ActivityCategory> categoriesExplored = const {
      ActivityCategory.culture,
      ActivityCategory.food,
      ActivityCategory.nature,
    },
    bool hasAiActivities = false,
  }) {
    return PostTripLoaded(
      trip: makeTrip(
        status: TripStatus.completed,
        destinationName: destinationName,
        startDate: DateTime(2024, 6),
        endDate: DateTime(2024, 6, 7),
      ),
      totalDays: totalDays,
      activitiesCompleted: activitiesCompleted,
      totalActivities: totalActivities,
      budgetSpent: budgetSpent,
      budgetTotal: budgetTotal,
      destinationName: destinationName,
      categoriesExplored: categoriesExplored,
      hasAiActivities: hasAiActivities,
    );
  }

  group('PostTripView', () {
    testWidgets('shows loading view in initial/loading state', (tester) async {
      await tester.pumpWidget(buildApp(PostTripLoading()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error view with retry on error state', (tester) async {
      await tester.pumpWidget(
        buildApp(PostTripError(error: const NetworkError('fail'))),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Retry'), findsOneWidget);
    });

    testWidgets('shows "Souvenirs" title in app bar', (tester) async {
      await tester.pumpWidget(buildApp(makeLoadedState()));
      await tester.pumpAndSettle();

      expect(find.text('Souvenirs'), findsOneWidget);
    });

    testWidgets('shows trip title', (tester) async {
      await tester.pumpWidget(buildApp(makeLoadedState()));
      await tester.pumpAndSettle();

      expect(find.text('Paris Trip'), findsOneWidget);
    });

    testWidgets('shows destination name', (tester) async {
      await tester.pumpWidget(buildApp(makeLoadedState()));
      await tester.pumpAndSettle();

      expect(find.text('Paris'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows stats grid with days count', (tester) async {
      await tester.pumpWidget(buildApp(makeLoadedState()));
      await tester.pumpAndSettle();

      expect(find.text('7 days of adventure'), findsOneWidget);
    });

    testWidgets('shows stats grid with activities completed', (tester) async {
      await tester.pumpWidget(buildApp(makeLoadedState()));
      await tester.pumpAndSettle();

      expect(find.text('5 of 8 activities'), findsOneWidget);
    });

    testWidgets('shows stats grid with budget spent', (tester) async {
      await tester.pumpWidget(buildApp(makeLoadedState()));
      await tester.pumpAndSettle();

      expect(find.textContaining('500'), findsOneWidget);
    });

    testWidgets('shows stats grid with categories explored', (tester) async {
      await tester.pumpWidget(
        buildApp(
          makeLoadedState(
            categoriesExplored: {
              ActivityCategory.culture,
              ActivityCategory.food,
              ActivityCategory.nature,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3 categories (excluding "other")
      expect(find.text('3 categories explored'), findsOneWidget);
    });

    testWidgets('shows "Share your experience" CTA', (tester) async {
      await tester.pumpWidget(buildApp(makeLoadedState()));
      await tester.pumpAndSettle();

      // Scroll down to reveal CTAs below the stats grid
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Share your experience'), findsOneWidget);
    });

    testWidgets('shows "Plan your next trip" CTA', (tester) async {
      await tester.pumpWidget(buildApp(makeLoadedState()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Plan your next trip'), findsOneWidget);
    });

    testWidgets('shows 4 stat cards with correct icons', (tester) async {
      await tester.pumpWidget(buildApp(makeLoadedState()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.wallet_rounded), findsOneWidget);
      expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
    });

    testWidgets('retry button sends LoadPostTripStats event', (tester) async {
      await tester.pumpWidget(
        buildApp(PostTripError(error: const NetworkError('fail'))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Retry'));
      await tester.pump();
      verify(() => mockBloc.add(any(that: isA<LoadPostTripStats>()))).called(1);
    });
  });
}
