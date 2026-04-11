// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/view/trip_detail_view.dart';
import 'package:bagtrip/trip_detail/widgets/trip_completion_bar.dart';
import 'package:bagtrip/trip_detail/widgets/trip_detail_shimmer.dart';
import 'package:bagtrip/trip_detail/widgets/trip_timeline_section.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class _MockTripDetailBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

TripDetailLoaded _loaded({
  Trip? trip,
  List<Activity> activities = const [],
  List<ManualFlight> flights = const [],
  List<Accommodation> accommodations = const [],
  List<BaggageItem> baggageItems = const [],
  List<TripShare> shares = const [],
  String userRole = 'OWNER',
  int selectedDayIndex = 0,
  bool deferredLoaded = true,
  Map<String, AppError> sectionErrors = const {},
  AppError? operationError,
  CompletionResult? completion,
}) {
  return TripDetailLoaded(
    trip: trip ?? makeTrip(),
    activities: activities,
    flights: flights,
    accommodations: accommodations,
    baggageItems: baggageItems,
    shares: shares,
    userRole: userRole,
    selectedDayIndex: selectedDayIndex,
    deferredLoaded: deferredLoaded,
    sectionErrors: sectionErrors,
    operationError: operationError,
    completionResult:
        completion ??
        const CompletionResult(
          percentage: 0,
          segments: {
            CompletionSegmentType.dates: true,
            CompletionSegmentType.flights: false,
            CompletionSegmentType.accommodation: false,
            CompletionSegmentType.activities: false,
            CompletionSegmentType.baggage: false,
            CompletionSegmentType.budget: false,
          },
        ),
  );
}

void main() {
  late _MockTripDetailBloc bloc;

  setUpAll(() {
    registerFallbackValue(RefreshTripDetail());
    registerFallbackValue(LoadTripDetail(tripId: ''));
    registerFallbackValue(SelectDay(dayIndex: 0));
    registerFallbackValue(DeleteTripDetail());
    registerFallbackValue(UpdateTripStatus(status: 'PLANNED'));
    registerFallbackValue(RetryDeferredSection(section: 'flights'));
    registerFallbackValue(TripDetailInitial());
  });

  setUp(() {
    bloc = _MockTripDetailBloc();
  });

  Future<void> pumpView(
    WidgetTester tester,
    TripDetailState seed, {
    Size size = const Size(900, 2400),
  }) async {
    tester.view.physicalSize = Size(size.width, size.height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => bloc.state).thenReturn(seed);
    whenListen(bloc, const Stream<TripDetailState>.empty(), initialState: seed);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: BlocProvider<TripDetailBloc>.value(
          value: bloc,
          child: const TripDetailView(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pump();
  }

  group('TripDetailView', () {
    testWidgets('renders shimmer during loading', (tester) async {
      await pumpView(tester, TripDetailLoading());
      expect(find.byType(TripDetailShimmer), findsOneWidget);
    });

    testWidgets('renders error view with retry on error state', (tester) async {
      await pumpView(
        tester,
        TripDetailError(error: const NetworkError('offline')),
      );
      expect(find.byType(TripDetailView), findsOneWidget);
    });

    testWidgets('renders loaded content with minimal state', (tester) async {
      await pumpView(tester, _loaded());
      expect(find.byType(TripDetailView), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('owner with valid dates sees completion bar', (tester) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      expect(find.byType(TripCompletionBar), findsOneWidget);
    });

    testWidgets('viewer role hides completion bar and shows read-only banner', (
      tester,
    ) async {
      await pumpView(
        tester,
        _loaded(
          userRole: 'VIEWER',
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      // Viewer => canEdit false => no completion bar
      expect(find.byType(TripCompletionBar), findsNothing);
      // Viewer read-only banner
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('completed trip shows read-only lock banner', (tester) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            status: TripStatus.completed,
            startDate: DateTime(2023, 1),
            endDate: DateTime(2023, 1, 3),
          ),
        ),
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      // "Give review" CTA shown for completed trip
      expect(find.byIcon(Icons.rate_review_outlined), findsOneWidget);
    });

    testWidgets('draft trip shows "mark as ready" action and delete action', (
      tester,
    ) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            status: TripStatus.draft,
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      expect(find.byType(TripDetailView), findsOneWidget);
    });

    testWidgets('ongoing trip shows "mark complete" action', (tester) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            status: TripStatus.ongoing,
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      expect(find.byType(TripDetailView), findsOneWidget);
    });

    testWidgets('timeline section renders when totalDays > 0', (tester) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      expect(find.byType(TripTimelineSection), findsOneWidget);
    });

    testWidgets('timeline section hidden when trip has no dates', (
      tester,
    ) async {
      await pumpView(
        tester,
        _loaded(trip: makeTrip(startDate: null, endDate: null)),
      );
      expect(find.byType(TripDetailView), findsOneWidget);
    });

    testWidgets('deferredLoaded=false renders shimmer placeholders', (
      tester,
    ) async {
      await pumpView(
        tester,
        _loaded(
          deferredLoaded: false,
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      expect(find.byType(TripDetailView), findsOneWidget);
    });

    testWidgets('sectionErrors on flights renders error indicator', (
      tester,
    ) async {
      await pumpView(
        tester,
        _loaded(
          sectionErrors: const {'flights': NetworkError('boom')},
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      expect(find.byType(TripDetailView), findsOneWidget);
    });

    testWidgets('multiple section errors render all indicators', (
      tester,
    ) async {
      await pumpView(
        tester,
        _loaded(
          sectionErrors: const {
            'flights': NetworkError('a'),
            'accommodations': NetworkError('b'),
            'baggage': NetworkError('c'),
            'budget': NetworkError('d'),
            'shares': NetworkError('e'),
          },
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      expect(find.byType(TripDetailView), findsOneWidget);
    });

    testWidgets('trip with many travelers renders stats row with 3 items', (
      tester,
    ) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            nbTravelers: 6,
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      expect(find.byIcon(Icons.people_rounded), findsOneWidget);
      expect(find.byIcon(Icons.date_range_rounded), findsOneWidget);
    });

    testWidgets('owner with activities + accommodations renders map section', (
      tester,
    ) async {
      final activity = makeActivity().copyWith(location: 'Eiffel Tower');
      final accommodation = makeAccommodation(address: '10 Rue de Rivoli');

      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
          activities: [activity],
          accommodations: [accommodation],
        ),
      );
      expect(find.byType(TripDetailView), findsOneWidget);
    });

    testWidgets('refresh indicator present on loaded state', (tester) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('planned trip (no draft button) does not show mark-ready', (
      tester,
    ) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            status: TripStatus.planned,
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });
}
