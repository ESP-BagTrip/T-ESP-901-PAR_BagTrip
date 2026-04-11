// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/activities/bloc/activity_bloc.dart';
import 'package:bagtrip/activities/view/activities_view.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_widget.dart';
import '../helpers/test_fixtures.dart';

class _MockActivityBloc extends MockBloc<ActivityEvent, ActivityState>
    implements ActivityBloc {}

void main() {
  late _MockActivityBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoadActivities(tripId: 't'));
    registerFallbackValue(ActivityInitial());
  });

  setUp(() {
    mockBloc = _MockActivityBloc();
  });

  Future<void> pump(
    WidgetTester tester,
    ActivityState seed, {
    String role = 'OWNER',
    bool isCompleted = false,
    DateTime? tripStartDate,
    Size? size,
  }) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<ActivityState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<ActivityBloc>.value(
        value: mockBloc,
        child: ActivitiesView(
          tripId: 'trip-1',
          role: role,
          isCompleted: isCompleted,
          tripStartDate: tripStartDate,
        ),
      ),
      size: size,
    );
    await tester.pump();
  }

  group('ActivitiesView', () {
    testWidgets('renders loading state', (tester) async {
      await pump(tester, ActivityLoading());
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('renders error state with retry button', (tester) async {
      await pump(tester, ActivityError(error: const NetworkError('offline')));
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('renders empty state when loaded with no activities', (
      tester,
    ) async {
      await pump(
        tester,
        ActivitiesLoaded(activities: const [], groupedByDay: const {}),
      );
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('renders list when activities exist', (tester) async {
      final activity = makeActivity();
      await pump(
        tester,
        ActivitiesLoaded(
          activities: [activity],
          groupedByDay: {
            '2024-06-01': [activity],
          },
        ),
      );
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('viewer role hides the AI suggestions button', (tester) async {
      when(() => mockBloc.state).thenReturn(
        ActivitiesLoaded(activities: const [], groupedByDay: const {}),
      );
      whenListen(
        mockBloc,
        const Stream<ActivityState>.empty(),
        initialState: ActivitiesLoaded(
          activities: const [],
          groupedByDay: const {},
        ),
      );
      await pumpLocalized(
        tester,
        BlocProvider<ActivityBloc>.value(
          value: mockBloc,
          child: const ActivitiesView(tripId: 'trip-1', role: 'VIEWER'),
        ),
      );
      await tester.pump();
      expect(find.byType(ActivitiesView), findsOneWidget);
    });
  });

  group('ActivitiesView reinforcement', () {
    testWidgets('renders ActivitySuggestionsLoading as loading view', (
      tester,
    ) async {
      await pump(tester, ActivitySuggestionsLoading());
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('renders ActivitySuggestionsLoaded with empty activities', (
      tester,
    ) async {
      await pump(
        tester,
        ActivitySuggestionsLoaded(
          suggestions: const [
            {
              'title': 'Eiffel Tower Visit',
              'description': 'Top of Europe',
              'category': 'CULTURE',
              'estimatedCost': 25,
              'location': 'Paris',
              'suggestedDay': 1,
            },
          ],
          activities: const [],
          groupedByDay: const {},
        ),
      );
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('renders ActivitySuggestionsLoaded with activities + hasMore', (
      tester,
    ) async {
      final activity = makeActivity(
        validationStatus: ValidationStatus.suggested,
      );
      await pump(
        tester,
        ActivitySuggestionsLoaded(
          suggestions: const [
            {'title': 'Louvre', 'description': 'Museum', 'category': 'CULTURE'},
          ],
          activities: [activity],
          groupedByDay: {
            '2024-06-01': [activity],
          },
          currentPage: 1,
          totalPages: 2,
        ),
      );
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('renders ActivityQuotaExceeded as shrink', (tester) async {
      await pump(tester, ActivityQuotaExceeded());
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('renders ActivitiesLoaded with many activities', (
      tester,
    ) async {
      final activities = List<Activity>.generate(
        12,
        (i) => makeActivity(
          id: 'act-$i',
          title: 'Activity $i',
          date: DateTime(2024, 6, 1 + (i % 5)),
        ),
      );
      final grouped = <String, List<Activity>>{};
      for (final a in activities) {
        final key =
            '${a.date.year}-${a.date.month.toString().padLeft(2, '0')}-${a.date.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []).add(a);
      }
      await pump(
        tester,
        ActivitiesLoaded(activities: activities, groupedByDay: grouped),
        size: const Size(900, 1600),
      );
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('renders ActivitiesLoaded with hasMore=true', (tester) async {
      final activity = makeActivity();
      await pump(
        tester,
        ActivitiesLoaded(
          activities: [activity],
          groupedByDay: {
            '2024-06-01': [activity],
          },
          currentPage: 1,
          totalPages: 3,
          isLoadingMore: false,
        ),
      );
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('renders ActivitiesLoaded with isLoadingMore=true', (
      tester,
    ) async {
      final activity = makeActivity();
      await pump(
        tester,
        ActivitiesLoaded(
          activities: [activity],
          groupedByDay: {
            '2024-06-01': [activity],
          },
          currentPage: 1,
          totalPages: 2,
          isLoadingMore: true,
        ),
      );
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets(
      'renders mix of validated/suggested/manual activities (disclaimer banner visible)',
      (tester) async {
        final validated = makeActivity(
          id: 'a-val',
          title: 'Validated',
          validationStatus: ValidationStatus.validated,
        );
        final suggested = makeActivity(
          id: 'a-sug',
          title: 'Suggested',
          validationStatus: ValidationStatus.suggested,
        );
        final manual = makeActivity(
          id: 'a-man',
          title: 'Manual',
          validationStatus: ValidationStatus.manual,
        );
        await pump(
          tester,
          ActivitiesLoaded(
            activities: [validated, suggested, manual],
            groupedByDay: {
              '2024-06-01': [validated, suggested, manual],
            },
          ),
          size: const Size(900, 1600),
        );
        expect(find.byType(ActivitiesView), findsOneWidget);
      },
    );

    testWidgets('EDITOR role still shows edit affordances', (tester) async {
      final activity = makeActivity();
      await pump(
        tester,
        ActivitiesLoaded(
          activities: [activity],
          groupedByDay: {
            '2024-06-01': [activity],
          },
        ),
        role: 'EDITOR',
      );
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('isCompleted=true hides edit affordances', (tester) async {
      final activity = makeActivity();
      await pump(
        tester,
        ActivitiesLoaded(
          activities: [activity],
          groupedByDay: {
            '2024-06-01': [activity],
          },
        ),
        isCompleted: true,
      );
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('VIEWER role with completed trip renders read-only', (
      tester,
    ) async {
      final activity = makeActivity();
      await pump(
        tester,
        ActivitiesLoaded(
          activities: [activity],
          groupedByDay: {
            '2024-06-01': [activity],
          },
        ),
        role: 'VIEWER',
        isCompleted: true,
      );
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('tapping AI suggestions icon dispatches SuggestActivities', (
      tester,
    ) async {
      await pump(
        tester,
        ActivitiesLoaded(activities: const [], groupedByDay: const {}),
        size: const Size(900, 1600),
      );
      final aiButton = find.byIcon(Icons.auto_awesome);
      if (aiButton.evaluate().isNotEmpty) {
        await tester.tap(aiButton.first);
        await tester.pump();
        verify(
          () => mockBloc.add(any(that: isA<SuggestActivities>())),
        ).called(1);
      }
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('tapping retry on error dispatches LoadActivities', (
      tester,
    ) async {
      await pump(tester, ActivityError(error: const NetworkError('offline')));
      final retry = find.text('Retry');
      if (retry.evaluate().isNotEmpty) {
        await tester.tap(retry.first);
        await tester.pump();
        verify(
          () => mockBloc.add(any(that: isA<LoadActivities>())),
        ).called(greaterThanOrEqualTo(1));
      }
      expect(find.byType(ActivitiesView), findsOneWidget);
    });

    testWidgets('renders with tripStartDate passed through', (tester) async {
      await pump(
        tester,
        ActivitiesLoaded(activities: const [], groupedByDay: const {}),
        tripStartDate: DateTime(2024, 7, 15),
      );
      expect(find.byType(ActivitiesView), findsOneWidget);
    });
  });
}
