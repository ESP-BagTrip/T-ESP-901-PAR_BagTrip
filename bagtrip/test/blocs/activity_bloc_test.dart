import 'package:bagtrip/activities/bloc/activity_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockActivityRepository mockActivityRepo;

  setUp(() {
    mockActivityRepo = MockActivityRepository();
  });

  group('ActivityBloc', () {
    // ── LoadActivities ──────────────────────────────────────────────────

    blocTest<ActivityBloc, ActivityState>(
      'emits [ActivityLoading, ActivitiesLoaded] with grouped activities sorted by startTime',
      build: () {
        final activities = [
          makeActivity(
            title: 'Lunch',
            date: DateTime(2024, 6),
            startTime: '12:00',
          ),
          makeActivity(id: 'act-2', title: 'Museum', date: DateTime(2024, 6)),
        ];
        when(
          () => mockActivityRepo.getActivitiesPaginated(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async =>
              Success(makePaginatedResponse(items: activities, total: 2)),
        );
        return ActivityBloc(activityRepository: mockActivityRepo);
      },
      act: (bloc) => bloc.add(LoadActivities(tripId: 'trip-1')),
      expect: () => [isA<ActivityLoading>(), isA<ActivitiesLoaded>()],
      verify: (bloc) {
        final state = bloc.state as ActivitiesLoaded;
        expect(state.activities.length, 2);
        // Both activities share 2024-06-01, should be grouped under one key
        expect(state.groupedByDay.keys.length, 1);
        expect(state.groupedByDay.containsKey('2024-06-01'), isTrue);
        // Sorted by startTime: Museum (09:00) before Lunch (12:00)
        final dayList = state.groupedByDay['2024-06-01']!;
        expect(dayList[0].title, 'Museum');
        expect(dayList[1].title, 'Lunch');
        expect(state.currentPage, 1);
        expect(state.totalPages, 1);
      },
    );

    blocTest<ActivityBloc, ActivityState>(
      'emits [ActivityLoading, ActivityError] when LoadActivities fails',
      build: () {
        when(
          () => mockActivityRepo.getActivitiesPaginated(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return ActivityBloc(activityRepository: mockActivityRepo);
      },
      act: (bloc) => bloc.add(LoadActivities(tripId: 'trip-1')),
      expect: () => [isA<ActivityLoading>(), isA<ActivityError>()],
    );

    // ── LoadMoreActivities ────────────────────────────────────────────

    blocTest<ActivityBloc, ActivityState>(
      'LoadMoreActivities appends items and regroups',
      build: () {
        when(
          () => mockActivityRepo.getActivitiesPaginated(
            any(),
            page: 2,
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => Success(
            PaginatedResponse<Activity>(
              items: [
                makeActivity(
                  id: 'act-3',
                  title: 'Dinner',
                  date: DateTime(2024, 6, 2),
                ),
              ],
              total: 3,
              page: 2,
              totalPages: 2,
            ),
          ),
        );
        return ActivityBloc(activityRepository: mockActivityRepo);
      },
      seed: () => ActivitiesLoaded(
        activities: [
          makeActivity(title: 'Lunch', date: DateTime(2024, 6)),
          makeActivity(id: 'act-2', title: 'Museum', date: DateTime(2024, 6)),
        ],
        groupedByDay: {
          '2024-06-01': [
            makeActivity(title: 'Museum', date: DateTime(2024, 6)),
            makeActivity(
              title: 'Lunch',
              date: DateTime(2024, 6),
              startTime: '12:00',
            ),
          ],
        },
        totalPages: 2,
      ),
      act: (bloc) => bloc.add(LoadMoreActivities(tripId: 'trip-1')),
      expect: () => [
        isA<ActivitiesLoaded>().having(
          (s) => s.isLoadingMore,
          'isLoadingMore',
          true,
        ),
        isA<ActivitiesLoaded>().having(
          (s) => s.activities.length,
          'activities.length',
          3,
        ),
      ],
      verify: (bloc) {
        final state = bloc.state as ActivitiesLoaded;
        expect(state.currentPage, 2);
        // Two days now
        expect(state.groupedByDay.keys.length, 2);
        expect(state.isLoadingMore, false);
      },
    );

    blocTest<ActivityBloc, ActivityState>(
      'LoadMoreActivities does nothing when hasMore is false',
      build: () => ActivityBloc(activityRepository: mockActivityRepo),
      seed: () => ActivitiesLoaded(
        activities: [makeActivity()],
        groupedByDay: {
          '2024-06-01': [makeActivity()],
        },
      ),
      act: (bloc) => bloc.add(LoadMoreActivities(tripId: 'trip-1')),
      expect: () => <ActivityState>[],
    );

    blocTest<ActivityBloc, ActivityState>(
      'LoadMoreActivities does nothing when already loading',
      build: () => ActivityBloc(activityRepository: mockActivityRepo),
      seed: () => ActivitiesLoaded(
        activities: [makeActivity()],
        groupedByDay: {
          '2024-06-01': [makeActivity()],
        },
        totalPages: 2,
        isLoadingMore: true,
      ),
      act: (bloc) => bloc.add(LoadMoreActivities(tripId: 'trip-1')),
      expect: () => <ActivityState>[],
    );

    // ── CreateActivity ──────────────────────────────────────────────────

    blocTest<ActivityBloc, ActivityState>(
      'triggers LoadActivities internally after CreateActivity succeeds',
      build: () {
        when(
          () => mockActivityRepo.createActivity(any(), any()),
        ).thenAnswer((_) async => Success(makeActivity()));
        when(
          () => mockActivityRepo.getActivitiesPaginated(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => Success(makePaginatedResponse(items: [makeActivity()])),
        );
        return ActivityBloc(activityRepository: mockActivityRepo);
      },
      act: (bloc) => bloc.add(
        CreateActivity(tripId: 'trip-1', data: {'title': 'New Activity'}),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // CreateActivity success triggers add(LoadActivities)
        isA<ActivityLoading>(),
        isA<ActivitiesLoaded>(),
      ],
      verify: (_) {
        verify(
          () => mockActivityRepo.createActivity('trip-1', any()),
        ).called(1);
      },
    );

    // ── DeleteActivity ──────────────────────────────────────────────────

    blocTest<ActivityBloc, ActivityState>(
      'triggers LoadActivities internally after DeleteActivity succeeds',
      build: () {
        when(
          () => mockActivityRepo.deleteActivity(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => mockActivityRepo.getActivitiesPaginated(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => Success(
            makePaginatedResponse(items: <Activity>[], total: 0, totalPages: 0),
          ),
        );
        return ActivityBloc(activityRepository: mockActivityRepo);
      },
      act: (bloc) =>
          bloc.add(DeleteActivity(tripId: 'trip-1', activityId: 'act-1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<ActivityLoading>(), isA<ActivitiesLoaded>()],
      verify: (_) {
        verify(
          () => mockActivityRepo.deleteActivity('trip-1', 'act-1'),
        ).called(1);
      },
    );

    // ── SuggestActivities ───────────────────────────────────────────────

    blocTest<ActivityBloc, ActivityState>(
      'emits [ActivitySuggestionsLoading, ActivitySuggestionsLoaded] when SuggestActivities succeeds',
      build: () {
        when(() => mockActivityRepo.suggestActivities(any())).thenAnswer(
          (_) async => const Success([
            {'title': 'Suggested Activity', 'category': 'visit'},
          ]),
        );
        return ActivityBloc(activityRepository: mockActivityRepo);
      },
      act: (bloc) => bloc.add(SuggestActivities(tripId: 'trip-1')),
      expect: () => [
        isA<ActivitySuggestionsLoading>(),
        isA<ActivitySuggestionsLoaded>(),
      ],
      verify: (bloc) {
        final state = bloc.state as ActivitySuggestionsLoaded;
        expect(state.suggestions.length, 1);
        expect(state.suggestions.first['title'], 'Suggested Activity');
      },
    );

    blocTest<ActivityBloc, ActivityState>(
      'emits [ActivitySuggestionsLoading, ActivitiesLoaded, ActivityQuotaExceeded] on QuotaExceededError',
      build: () {
        when(() => mockActivityRepo.suggestActivities(any())).thenAnswer(
          (_) async => const Failure(QuotaExceededError('quota exceeded')),
        );
        return ActivityBloc(activityRepository: mockActivityRepo);
      },
      act: (bloc) => bloc.add(SuggestActivities(tripId: 'trip-1')),
      expect: () => [
        isA<ActivitySuggestionsLoading>(),
        isA<ActivitiesLoaded>(),
        isA<ActivityQuotaExceeded>(),
      ],
    );
  });
}
