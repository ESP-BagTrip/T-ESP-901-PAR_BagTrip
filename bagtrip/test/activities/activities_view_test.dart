import 'package:bagtrip/activities/bloc/activity_bloc.dart';
import 'package:bagtrip/activities/view/activities_view.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bloc_test/bloc_test.dart';
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

  Future<void> pump(WidgetTester tester, ActivityState seed) async {
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
        child: const ActivitiesView(tripId: 'trip-1'),
      ),
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
}
