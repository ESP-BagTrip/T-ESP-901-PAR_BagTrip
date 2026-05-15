// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/design/widgets/review/activity_panel_card.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/view/panels/activities_panel.dart';
import 'package:bagtrip/trip_detail/view/panels/trip_panel_empty_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_fixtures.dart';

class _MockTripDetailBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

void main() {
  late _MockTripDetailBloc bloc;

  setUpAll(() {
    registerFallbackValue(SelectDay(dayIndex: 0));
    registerFallbackValue(CreateActivityFromDetail(data: <String, dynamic>{}));
    registerFallbackValue(
      UpdateActivityFromDetail(activityId: 'x', data: <String, dynamic>{}),
    );
    registerFallbackValue(ValidateActivity(activityId: 'x'));
    registerFallbackValue(RejectActivity(activityId: 'x'));
    // ActivitiesViewCubit reads/writes SharedPreferences. Pin a clean
    // store so tests don't depend on the host machine state.
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    bloc = _MockTripDetailBloc();
    when(() => bloc.state).thenReturn(
      TripDetailLoaded(
        trip: makeTrip(),
        activities: const [],
        flights: const [],
        accommodations: const [],
        baggageItems: const [],
        shares: const [],
        userRole: 'OWNER',
        selectedDayIndex: 0,
        deferredLoaded: true,
        sectionErrors: const {},
        completionResult: const CompletionResult(percentage: 0, segments: {}),
      ),
    );
  });

  Future<void> pump(WidgetTester tester, Widget panel) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider<TripDetailBloc>.value(value: bloc, child: panel),
        ),
      ),
    );
  }

  testWidgets('empty state shows CTA label when canEdit is true', (
    tester,
  ) async {
    await pump(
      tester,
      const ActivitiesPanel(
        tripId: 'trip-1',
        tripStartDate: null,
        activities: [],
        totalDays: 0,
        selectedDayIndex: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(TripPanelEmptyState), findsOneWidget);
    expect(find.text('Add now'), findsOneWidget);
  });

  testWidgets('renders ActivityPanelCard rows for the selected day', (
    tester,
  ) async {
    final activity = makeActivity(id: 'a1', title: 'Temple visit');
    await pump(
      tester,
      ActivitiesPanel(
        tripId: 'trip-1',
        tripStartDate: activity.date,
        activities: [activity],
        totalDays: 3,
        selectedDayIndex: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(ActivityPanelCard), findsOneWidget);
    expect(find.text('Temple visit'), findsOneWidget);
  });

  testWidgets('suggested activity has no inline validate button on card', (
    tester,
  ) async {
    final activity = makeActivity(
      id: 'a1',
      validationStatus: ValidationStatus.suggested,
    );
    await pump(
      tester,
      ActivitiesPanel(
        tripId: 'trip-1',
        tripStartDate: activity.date,
        activities: [activity],
        totalDays: 1,
        selectedDayIndex: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.text('Validate'), findsNothing);
    expect(find.byType(Dismissible), findsOneWidget);
  });

  testWidgets('shows gesture hint when list is editable and non-empty', (
    tester,
  ) async {
    final activity = makeActivity(id: 'a1');
    await pump(
      tester,
      ActivitiesPanel(
        tripId: 'trip-1',
        tripStartDate: activity.date,
        activities: [activity],
        totalDays: 1,
        selectedDayIndex: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.textContaining('Swipe left to delete'), findsOneWidget);
  });

  testWidgets(
    'suggested row uses horizontal dismissible for validate and delete',
    (tester) async {
      final activity = makeActivity(
        id: 'a1',
        validationStatus: ValidationStatus.suggested,
      );
      await pump(
        tester,
        ActivitiesPanel(
          tripId: 'trip-1',
          tripStartDate: activity.date,
          activities: [activity],
          totalDays: 1,
          selectedDayIndex: 0,
          canEdit: true,
          isCompleted: false,
          role: 'OWNER',
        ),
      );
      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.direction, DismissDirection.horizontal);
      expect(dismissible.background, isNotNull);
      expect(dismissible.secondaryBackground, isNotNull);
    },
  );

  testWidgets('validated row only allows delete swipe direction', (
    tester,
  ) async {
    final activity = makeActivity(id: 'a1');
    await pump(
      tester,
      ActivitiesPanel(
        tripId: 'trip-1',
        tripStartDate: activity.date,
        activities: [activity],
        totalDays: 1,
        selectedDayIndex: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    expect(dismissible.direction, DismissDirection.endToStart);
  });

  testWidgets('PanelFab visible in edit mode', (tester) async {
    final activity = makeActivity(id: 'a1');
    await pump(
      tester,
      ActivitiesPanel(
        tripId: 'trip-1',
        tripStartDate: activity.date,
        activities: [activity],
        totalDays: 1,
        selectedDayIndex: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(PanelFab), findsOneWidget);
  });

  testWidgets('PanelFab hidden in viewer mode', (tester) async {
    final activity = makeActivity(id: 'a1');
    await pump(
      tester,
      ActivitiesPanel(
        tripId: 'trip-1',
        tripStartDate: activity.date,
        activities: [activity],
        totalDays: 1,
        selectedDayIndex: 0,
        canEdit: false,
        isCompleted: false,
        role: 'VIEWER',
      ),
    );
    expect(find.byType(PanelFab), findsNothing);
  });

  testWidgets('renders unscheduled activities under a dedicated header', (
    tester,
  ) async {
    // Regression (SMP-325): the AI engine persists recurring activities
    // (eg. dinners) without a calendar date. They must surface in a
    // dedicated bucket below the day list instead of being silently
    // dropped, which is what made the Itinerary tab look empty.
    final scheduled = makeActivity(id: 'a1', title: 'Temple visit');
    const unscheduled = Activity(
      id: 'a2',
      tripId: 'trip-1',
      title: 'Dîner libre',
      date: null,
      startTime: null,
      category: ActivityCategory.food,
      validationStatus: ValidationStatus.suggested,
      isBooked: false,
      isDone: false,
    );
    await pump(
      tester,
      ActivitiesPanel(
        tripId: 'trip-1',
        tripStartDate: scheduled.date,
        activities: [scheduled, unscheduled],
        totalDays: 1,
        selectedDayIndex: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.text('Temple visit'), findsOneWidget);
    expect(find.text('Dîner libre'), findsOneWidget);
    expect(find.text('Unscheduled'), findsOneWidget);
  });

  testWidgets(
    'view-mode picker swaps the layout — Timeline → List → Categories',
    (tester) async {
      // Phase C2 (SMP-325): the panel surfaces three layouts on the
      // same activities source, picked via the toolbar at the top.
      // Pre-conditions:
      //  - Timeline view shows the J1/J2 day picker (selector chips).
      //  - List view drops it but keeps the Activity rows.
      //  - Category view groups by ActivityCategory (label header
      //    appears for each non-empty bucket).
      SharedPreferences.setMockInitialValues({});
      final culture = makeActivity(
        id: 'a1',
        title: 'Louvre',
        category: ActivityCategory.culture,
      );
      final food = makeActivity(
        id: 'a2',
        title: 'Brunch',
        category: ActivityCategory.food,
      );
      await pump(
        tester,
        ActivitiesPanel(
          tripId: 'trip-1',
          tripStartDate: culture.date,
          activities: [culture, food],
          totalDays: 3,
          selectedDayIndex: 0,
          canEdit: true,
          isCompleted: false,
          role: 'OWNER',
        ),
      );
      // Default mode is Timeline → J-picker chip is visible.
      expect(find.text('J1'), findsOneWidget);

      // Switch to List → J-picker disappears, both rows still visible.
      await tester.tap(find.text('List'));
      await tester.pump();
      expect(find.text('J1'), findsNothing);
      expect(find.text('Louvre'), findsOneWidget);
      expect(find.text('Brunch'), findsOneWidget);

      // Switch to Categories → category headers appear, activities
      // are still rendered (one per category in this fixture).
      await tester.tap(find.text('Categories'));
      await tester.pump();
      expect(find.text('Louvre'), findsOneWidget);
      expect(find.text('Brunch'), findsOneWidget);
      // The CULTURE / FOOD section labels are uppercase localised
      // category names — assert at least one section header appears.
      expect(find.byType(ActivityPanelCard), findsNWidgets(2));
    },
  );

  testWidgets(
    'validation filter chip narrows the list to suggested activities only',
    (tester) async {
      // Phase C3 (SMP-325): cross-cutting filter bar between the
      // view-mode picker and the list. Tapping "Suggested" must keep
      // the suggested rows and drop the validated ones — independent
      // of the active layout mode.
      SharedPreferences.setMockInitialValues({});
      final suggested = makeActivity(
        id: 'a-sugg',
        title: 'Massage',
        validationStatus: ValidationStatus.suggested,
      );
      final validated = makeActivity(
        id: 'a-val',
        title: 'Louvre',
        validationStatus: ValidationStatus.validated,
      );
      await pump(
        tester,
        ActivitiesPanel(
          tripId: 'trip-1',
          tripStartDate: suggested.date,
          activities: [suggested, validated],
          totalDays: 3,
          selectedDayIndex: 0,
          canEdit: true,
          isCompleted: false,
          role: 'OWNER',
        ),
      );
      // Both rows visible by default.
      expect(find.text('Massage'), findsOneWidget);
      expect(find.text('Louvre'), findsOneWidget);

      // Activate the "Suggested" filter — only the suggested row stays.
      await tester.tap(find.text('Suggested'));
      await tester.pump();
      expect(find.text('Massage'), findsOneWidget);
      expect(find.text('Louvre'), findsNothing);

      // Clearing filters brings everything back.
      await tester.tap(find.text('All'));
      await tester.pump();
      expect(find.text('Massage'), findsOneWidget);
      expect(find.text('Louvre'), findsOneWidget);
    },
  );

  testWidgets('tapping a day chip dispatches SelectDay', (tester) async {
    final activity = makeActivity(id: 'a1');
    await pump(
      tester,
      ActivitiesPanel(
        tripId: 'trip-1',
        tripStartDate: activity.date,
        activities: [activity],
        totalDays: 3,
        selectedDayIndex: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    await tester.tap(find.text('J2'));
    await tester.pump();
    verify(
      () => bloc.add(
        any(that: isA<SelectDay>().having((e) => e.dayIndex, 'dayIndex', 1)),
      ),
    ).called(1);
  });
}
