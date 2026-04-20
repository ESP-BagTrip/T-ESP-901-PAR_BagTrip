import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/view/trip_detail_view.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class _MockTripDetailBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

class _MockHomeBloc extends MockBloc<HomeEvent, HomeState>
    implements HomeBloc {}

class _MockTripManagementBloc
    extends MockBloc<TripManagementEvent, TripManagementState>
    implements TripManagementBloc {}

void main() {
  late _MockTripDetailBloc tripBloc;
  late _MockHomeBloc homeBloc;
  late _MockTripManagementBloc managementBloc;

  setUp(() {
    tripBloc = _MockTripDetailBloc();
    homeBloc = _MockHomeBloc();
    managementBloc = _MockTripManagementBloc();
    when(() => homeBloc.state).thenReturn(HomeInitial());
    when(() => managementBloc.state).thenReturn(TripManagementInitial());
  });

  TripDetailLoaded makeLoaded({String role = 'OWNER'}) {
    return TripDetailLoaded(
      trip: makeTrip(
        status: TripStatus.planned,
        startDate: DateTime(2026, 9),
        endDate: DateTime(2026, 9, 5),
      ),
      activities: const [],
      flights: const [],
      accommodations: const [],
      baggageItems: const [],
      shares: const [],
      userRole: role,
      completionResult: makeCompletionResult(),
    );
  }

  Widget buildApp({required TripDetailLoaded state}) {
    when(() => tripBloc.state).thenReturn(state);
    whenListen(
      tripBloc,
      const Stream<TripDetailState>.empty(),
      initialState: state,
    );
    return MediaQuery(
      data: const MediaQueryData(size: Size(900, 2400)),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<TripDetailBloc>.value(value: tripBloc),
            BlocProvider<HomeBloc>.value(value: homeBloc),
            BlocProvider<TripManagementBloc>.value(value: managementBloc),
          ],
          child: const TripDetailView(tripId: 'trip-1'),
        ),
      ),
    );
  }

  group('Viewer read-only state', () {
    testWidgets('renders "READ ONLY" status pill for VIEWER', (tester) async {
      await tester.pumpWidget(buildApp(state: makeLoaded(role: 'VIEWER')));
      await tester.pump();
      expect(find.text('READ ONLY'), findsOneWidget);
    });

    testWidgets('does not render status pill for OWNER of a planned trip', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(state: makeLoaded()));
      await tester.pump();
      expect(find.text('READ ONLY'), findsNothing);
    });

    testWidgets('hides footer add CTA for VIEWER', (tester) async {
      await tester.pumpWidget(buildApp(state: makeLoaded(role: 'VIEWER')));
      await tester.pump();
      // Viewer cannot edit → footer hidden, so no add-flight label present
      expect(find.text('Add a flight'), findsNothing);
      expect(find.text('Add an activity'), findsNothing);
    });
  });
}
