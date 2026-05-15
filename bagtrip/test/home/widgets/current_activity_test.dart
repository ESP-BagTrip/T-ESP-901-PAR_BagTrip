import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/active_trip_home_view.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/widgets/completion_ring.dart';
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
    when(() => mockHomeBloc.state).thenReturn(state);
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

  group('ActiveTripHomeView highlight activity', () {
    testWidgets('shows trip in progress eyebrow', (tester) async {
      await tester.pumpWidget(buildApp(makeActiveState()));
      await tester.pumpAndSettle();

      expect(find.text('TRIP IN PROGRESS'), findsOneWidget);
    });

    testWidgets('shows empty state when no activities today', (tester) async {
      await tester.pumpWidget(buildApp(makeActiveState()));
      await tester.pumpAndSettle();

      expect(find.text('No activities planned today'), findsOneWidget);
    });

    testWidgets('shows current activity with Now badge in hero panel', (
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
      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Current Activity'), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);
    });

    testWidgets('shows next activity with Next badge when none in progress', (
      tester,
    ) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final activities = [
        makeActivity(
          id: 'next',
          title: 'Afternoon Museum',
          date: today,
          startTime: '23:50',
        ),
      ];

      final state = makeActiveState(allActivities: activities);
      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Afternoon Museum'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('shows completion ring on hero card', (tester) async {
      final state = makeActiveState();
      await tester.pumpWidget(
        buildApp(
          HomeActiveTrip(
            user: state.user,
            activeTrip: state.activeTrip.copyWith(completionPercentage: 25),
            allActivities: state.allActivities,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CompletionRing), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });
  });
}
