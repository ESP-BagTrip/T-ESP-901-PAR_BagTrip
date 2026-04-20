// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/widgets/review/activity_tile.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/view/panels/itinerary_panel.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
      const ItineraryPanel(
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
    expect(find.byType(ElegantEmptyState), findsOneWidget);
    expect(find.text('Add activity'), findsOneWidget);
  });

  testWidgets('renders ActivityTile rows for the selected day', (tester) async {
    final activity = makeActivity(id: 'a1', title: 'Temple visit');
    await pump(
      tester,
      ItineraryPanel(
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
    expect(find.byType(ActivityTile), findsOneWidget);
    expect(find.text('Temple visit'), findsOneWidget);
  });

  testWidgets('PanelFab visible in edit mode', (tester) async {
    final activity = makeActivity(id: 'a1');
    await pump(
      tester,
      ItineraryPanel(
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
      ItineraryPanel(
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

  testWidgets('tapping a day chip dispatches SelectDay', (tester) async {
    final activity = makeActivity(id: 'a1');
    await pump(
      tester,
      ItineraryPanel(
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
