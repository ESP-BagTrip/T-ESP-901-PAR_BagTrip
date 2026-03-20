import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/active_trip_home_view.dart';
import 'package:bagtrip/home/view/home_view.dart';
import 'package:bagtrip/home/view/onboarding_home_view.dart';
import 'package:bagtrip/home/view/trip_manager_home_view.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockTripManagementBloc
    extends MockBloc<TripManagementEvent, TripManagementState>
    implements TripManagementBloc {}

void main() {
  late MockHomeBloc mockHomeBloc;
  late MockTripManagementBloc mockTripBloc;

  setUp(() {
    mockHomeBloc = MockHomeBloc();
    mockTripBloc = MockTripManagementBloc();
    when(() => mockTripBloc.state).thenReturn(TripManagementInitial());
  });

  Widget buildApp(HomeState state) {
    when(() => mockHomeBloc.state).thenReturn(state);
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>.value(value: mockHomeBloc),
          BlocProvider<TripManagementBloc>.value(value: mockTripBloc),
        ],
        child: const HomeView(),
      ),
    );
  }

  group('HomeView orchestrator', () {
    testWidgets('Loading renders LoadingView', (tester) async {
      await tester.pumpWidget(buildApp(HomeLoading()));
      await tester.pump();

      expect(find.byType(LoadingView), findsOneWidget);
    });

    testWidgets('Error renders ErrorView with retry', (tester) async {
      await tester.pumpWidget(
        buildApp(HomeError(error: const NetworkError('No connection'))),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('NewUser renders OnboardingHomeView', (tester) async {
      await tester.pumpWidget(buildApp(HomeNewUser(user: makeUser())));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OnboardingHomeView), findsOneWidget);
    });

    testWidgets('ActiveTrip renders ActiveTripHomeView', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        buildApp(
          HomeActiveTrip(
            user: makeUser(),
            activeTrip: makeTrip(
              status: TripStatus.ongoing,
              startDate: now.subtract(const Duration(days: 1)),
              endDate: now.add(const Duration(days: 3)),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ActiveTripHomeView), findsOneWidget);
    });

    testWidgets('TripManager renders TripManagerHomeView', (tester) async {
      await tester.pumpWidget(
        buildApp(
          HomeTripManager(
            user: makeUser(),
            upcomingTrips: [makeTrip(status: TripStatus.planned)],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TripManagerHomeView), findsOneWidget);
    });

    testWidgets('AnimatedSwitcher is in widget tree', (tester) async {
      await tester.pumpWidget(buildApp(HomeNewUser(user: makeUser())));
      await tester.pump();

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });
  });
}
