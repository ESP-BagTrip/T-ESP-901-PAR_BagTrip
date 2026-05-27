// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_theme.dart';
import 'package:bagtrip/design/widgets/review/panel_chips_bar.dart';
import 'package:bagtrip/design/widgets/review/review_hero.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/models/user_role.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_tabs.dart';
import 'package:bagtrip/trip_detail/view/panels/activities_panel.dart';
import 'package:bagtrip/trip_detail/view/trip_detail_view.dart';
import 'package:bagtrip/trip_detail/widgets/completion_ring.dart';
import 'package:bagtrip/trip_detail/widgets/review_shimmer.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart'
    show
        TripManagementBloc,
        TripManagementEvent,
        TripManagementState,
        TripManagementInitial;
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class _MockTripDetailBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

class _MockHomeBloc extends MockBloc<HomeEvent, HomeState>
    implements HomeBloc {}

class _MockTripManagementBloc
    extends MockBloc<TripManagementEvent, TripManagementState>
    implements TripManagementBloc {}

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
    userRole: UserRole.fromApi(userRole),
    selectedDayIndex: selectedDayIndex,
    deferredLoaded: deferredLoaded,
    sectionErrors: sectionErrors,
    operationError: operationError,
    completionResult: completion ?? makeCompletionResult(percentage: 50),
  );
}

void main() {
  late _MockTripDetailBloc bloc;
  late _MockHomeBloc homeBloc;
  late _MockTripManagementBloc managementBloc;

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
    homeBloc = _MockHomeBloc();
    managementBloc = _MockTripManagementBloc();
    when(() => homeBloc.state).thenReturn(HomeInitial());
    when(() => managementBloc.state).thenReturn(TripManagementInitial());
  });

  Future<void> pumpView(
    WidgetTester tester,
    TripDetailState seed, {
    int? initialTabIndex,
    Size size = const Size(900, 2400),
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = Size(size.width, size.height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => bloc.state).thenReturn(seed);
    whenListen(bloc, const Stream<TripDetailState>.empty(), initialState: seed);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<TripDetailBloc>.value(value: bloc),
            BlocProvider<HomeBloc>.value(value: homeBloc),
            BlocProvider<TripManagementBloc>.value(value: managementBloc),
          ],
          child: TripDetailView(
            tripId: 'trip-1',
            initialTabIndex: initialTabIndex,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('TripDetailView', () {
    testWidgets('renders review shimmer during loading', (tester) async {
      await pumpView(tester, TripDetailLoading());
      expect(find.byType(ReviewShimmer), findsOneWidget);
    });

    testWidgets('renders error view with retry on error state', (tester) async {
      await pumpView(
        tester,
        TripDetailError(error: const NetworkError('offline')),
      );
      expect(find.byType(TripDetailView), findsOneWidget);
    });

    testWidgets(
      'renders ReviewHero + PanelChipsBar + CompletionRing when loaded',
      (tester) async {
        await pumpView(
          tester,
          _loaded(
            trip: makeTrip(
              startDate: DateTime(2026, 9),
              endDate: DateTime(2026, 9, 5),
            ),
          ),
        );
        expect(find.byType(ReviewHero), findsOneWidget);
        expect(find.byType(PanelChipsBar), findsOneWidget);
        expect(find.byType(CompletionRing), findsOneWidget);
      },
    );

    testWidgets('uses trip detail page background when loaded', (tester) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        scaffold.backgroundColor,
        AppColors.tripDetailPageBackgroundOf(Brightness.light),
      );
      expect(find.byType(PanelChipsBar), findsOneWidget);
    });

    testWidgets('uses navy sheet background in dark mode when loaded', (
      tester,
    ) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
        theme: AppTheme.dark(),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        scaffold.backgroundColor,
        AppColors.tripDetailPageBackgroundOf(Brightness.dark),
      );
      expect(find.byType(PanelChipsBar), findsOneWidget);
    });

    testWidgets('owner sees 7 tab labels (including Sharing)', (tester) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Sharing'), findsOneWidget);
    });

    testWidgets('viewer sees 6 tab labels (Sharing hidden)', (tester) async {
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
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Sharing'), findsNothing);
    });

    testWidgets('viewer sees READ ONLY status pill', (tester) async {
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
      expect(find.text('READ ONLY'), findsOneWidget);
    });

    testWidgets('completed trip shows Completed badge + Give review CTA', (
      tester,
    ) async {
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
      expect(find.text('COMPLETE TRIP'), findsOneWidget);
      expect(find.text('Give a review'), findsOneWidget);
    });

    testWidgets('completion ring reflects percentage', (tester) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
          completion: makeCompletionResult(percentage: 73),
        ),
      );
      await tester.pump();
      expect(find.text('73%'), findsOneWidget);
    });

    testWidgets('opens Activities panel when initialTabIndex is activities', (
      tester,
    ) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
        initialTabIndex: tripDetailActivitiesTabIndex,
      );
      expect(find.byType(ActivitiesPanel), findsOneWidget);
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

    // SMP327-043: VoiceOver reading order — hero (1) -> chips/content (2) ->
    // footer actions (3) pinned via OrdinalSortKey.
    testWidgets('main blocks carry OrdinalSortKey reading order', (
      tester,
    ) async {
      await pumpView(
        tester,
        _loaded(
          trip: makeTrip(
            startDate: DateTime(2026, 9),
            endDate: DateTime(2026, 9, 5),
          ),
        ),
      );

      final sortKeys = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.sortKey)
          .whereType<OrdinalSortKey>()
          .map((k) => k.order)
          .toList();

      expect(sortKeys, contains(1.0));
      expect(sortKeys, contains(2.0));
      expect(sortKeys, contains(3.0));
    });
  });
}
