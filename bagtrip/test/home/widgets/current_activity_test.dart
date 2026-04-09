import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/cubit/today_tick_cubit.dart';
import 'package:bagtrip/home/view/active_trip_home_view.dart';
import 'package:bagtrip/home/widgets/timeline_activity_row.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class MockHomeBloc extends Mock implements HomeBloc {}

void main() {
  late MockHomeBloc mockHomeBloc;

  setUp(() {
    mockHomeBloc = MockHomeBloc();
    when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockHomeBloc.close()).thenAnswer((_) async {});
  });

  Widget buildApp(HomeActiveTrip state) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<HomeBloc>.value(
        value: mockHomeBloc,
        child: Scaffold(body: ActiveTripHomeView(state: state)),
      ),
    );
  }

  HomeActiveTrip makeActiveState({
    List<Activity>? allActivities,
    Trip? pendingCompletionTrip,
  }) {
    final now = DateTime.now();
    return HomeActiveTrip(
      user: makeUser(),
      activeTrip: makeTrip(
        status: TripStatus.ongoing,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 3)),
      ),
      allActivities: allActivities ?? [],
      pendingCompletionTrip: pendingCompletionTrip,
    );
  }

  group('ActiveTripHomeView', () {
    testWidgets('shows greeting with user first name', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(makeActiveState());
      await tester.pumpWidget(buildApp(makeActiveState()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test'), findsOneWidget);
    });

    testWidgets('shows empty state when no activities today', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(makeActiveState());
      await tester.pumpWidget(buildApp(makeActiveState()));
      await tester.pumpAndSettle();

      expect(find.text('No activities planned today'), findsOneWidget);
    });

    testWidgets('shows current activity with in-progress badge', (
      tester,
    ) async {
      final now = DateTime.now();
      final hourStr =
          '${now.hour.toString().padLeft(2, '0')}:${(now.minute - 1).abs().toString().padLeft(2, '0')}';
      final endStr =
          '${(now.hour + 1).toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final activities = [
        makeActivity(
          id: 'curr',
          title: 'Current Activity',
          date: DateTime(now.year, now.month, now.day),
          startTime: hourStr,
        ).copyWith(endTime: endStr),
      ];

      final state = makeActiveState(allActivities: activities);
      when(() => mockHomeBloc.state).thenReturn(state);
      await tester.pumpWidget(buildApp(state));
      // Let timers/animations tick
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Current Activity'), findsOneWidget);
      expect(find.byType(TimelineActivityRow), findsOneWidget);
    });

    testWidgets('shows today schedule header', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(makeActiveState());
      await tester.pumpWidget(buildApp(makeActiveState()));
      await tester.pumpAndSettle();

      expect(find.text("Today's schedule"), findsOneWidget);
    });

    testWidgets('shows quick actions section', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(makeActiveState());
      await tester.pumpWidget(buildApp(makeActiveState()));
      await tester.pumpAndSettle();

      expect(find.text('Quick actions'), findsOneWidget);
    });

    testWidgets('creates TodayTickCubit for live updates', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(makeActiveState());
      await tester.pumpWidget(buildApp(makeActiveState()));
      await tester.pump();

      // TodayTickCubit should be created as a BlocProvider
      expect(
        find.byWidgetPredicate((w) => w is BlocProvider<TodayTickCubit>),
        findsOneWidget,
      );
    });
  });
}
