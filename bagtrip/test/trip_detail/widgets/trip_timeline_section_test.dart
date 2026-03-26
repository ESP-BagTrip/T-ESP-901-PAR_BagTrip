import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/widgets/trip_timeline_section.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class MockTripDetailBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

Widget _buildApp({required Widget child, required TripDetailBloc bloc}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: BlocProvider<TripDetailBloc>.value(
      value: bloc,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

TripDetailLoaded _defaultLoadedState({Trip? trip}) => TripDetailLoaded(
  trip: trip ?? makeTrip(),
  activities: const [],
  flights: const [],
  accommodations: const [],
  baggageItems: const [],
  shares: const [],
  completionResult: const CompletionResult(percentage: 0, segments: {}),
);

void main() {
  late MockTripDetailBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(SelectDay(dayIndex: 0));
    registerFallbackValue(ValidateActivity(activityId: ''));
    registerFallbackValue(RejectActivity(activityId: ''));
    registerFallbackValue(RefreshTripDetail());
  });

  setUp(() {
    mockBloc = MockTripDetailBloc();
    when(() => mockBloc.state).thenReturn(_defaultLoadedState());
  });

  Trip buildTrip({DateTime? start, DateTime? end}) => makeTrip(
    startDate: start ?? DateTime(2024, 6),
    endDate: end ?? DateTime(2024, 6, 3),
  );

  group('TripTimelineSection', () {
    testWidgets('renders correct number of day chips', (tester) async {
      final trip = buildTrip();

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripTimelineSection(
            trip: trip,
            activities: const [],
            selectedDayIndex: 0,
            totalDays: 3,
            isOwner: true,
            isCompleted: false,
            tripId: trip.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('J1'), findsOneWidget);
      expect(find.text('J2'), findsOneWidget);
      expect(find.text('J3'), findsOneWidget);
    });

    testWidgets('tapping chip fires SelectDay event', (tester) async {
      final trip = buildTrip();

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripTimelineSection(
            trip: trip,
            activities: const [],
            selectedDayIndex: 0,
            totalDays: 3,
            isOwner: true,
            isCompleted: false,
            tripId: trip.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('J2'));
      verify(() => mockBloc.add(any(that: isA<SelectDay>()))).called(1);
    });

    testWidgets('activities grouped into correct time blocks', (tester) async {
      final trip = buildTrip();
      final activities = [
        makeActivity(id: 'a1', date: DateTime(2024, 6)),
        makeActivity(id: 'a2', date: DateTime(2024, 6), startTime: '14:00'),
        makeActivity(id: 'a3', date: DateTime(2024, 6), startTime: '20:00'),
      ];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripTimelineSection(
            trip: trip,
            activities: activities,
            selectedDayIndex: 0,
            totalDays: 3,
            isOwner: true,
            isCompleted: false,
            tripId: trip.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);
    });

    testWidgets('empty day shows ElegantEmptyState', (tester) async {
      final trip = buildTrip();

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripTimelineSection(
            trip: trip,
            activities: const [],
            selectedDayIndex: 0,
            totalDays: 3,
            isOwner: true,
            isCompleted: false,
            tripId: trip.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No activities yet'), findsOneWidget);
      expect(
        find.text('Add some or ask the AI to suggest ideas'),
        findsOneWidget,
      );
    });

    testWidgets('owner sees Add activity CTA; viewer does not', (tester) async {
      final trip = buildTrip();

      // Owner
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripTimelineSection(
            trip: trip,
            activities: const [],
            selectedDayIndex: 0,
            totalDays: 3,
            isOwner: true,
            isCompleted: false,
            tripId: trip.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add manually'), findsOneWidget);

      // Viewer
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripTimelineSection(
            trip: trip,
            activities: const [],
            selectedDayIndex: 0,
            totalDays: 3,
            isOwner: false,
            isCompleted: false,
            tripId: trip.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add manually'), findsNothing);
    });

    testWidgets('stagger animation renders without crash', (tester) async {
      final trip = buildTrip();
      final activities = [
        makeActivity(id: 'a1', date: DateTime(2024, 6)),
        makeActivity(id: 'a2', date: DateTime(2024, 6), startTime: '10:00'),
      ];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripTimelineSection(
            trip: trip,
            activities: activities,
            selectedDayIndex: 0,
            totalDays: 3,
            isOwner: true,
            isCompleted: false,
            tripId: trip.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TripTimelineSection), findsOneWidget);
    });

    testWidgets('section header shows itinerary title', (tester) async {
      final trip = buildTrip();

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripTimelineSection(
            trip: trip,
            activities: const [],
            selectedDayIndex: 0,
            totalDays: 3,
            isOwner: true,
            isCompleted: false,
            tripId: trip.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Itinerary'), findsOneWidget);
      expect(find.byIcon(Icons.hiking_rounded), findsOneWidget);
    });
  });
}
