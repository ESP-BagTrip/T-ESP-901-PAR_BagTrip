import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/widgets/home_trip_list_card.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/test_fixtures.dart';

class MockTripManagementBloc
    extends MockBloc<TripManagementEvent, TripManagementState>
    implements TripManagementBloc {}

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

void main() {
  late MockTripManagementBloc mockTripBloc;
  late MockHomeBloc mockHomeBloc;

  setUpAll(() {
    registerFallbackValue(LoadTrips());
    registerFallbackValue(RemoveUpcomingTrip(tripId: ''));
  });

  setUp(() {
    mockTripBloc = MockTripManagementBloc();
    mockHomeBloc = MockHomeBloc();
    when(() => mockTripBloc.state).thenReturn(TripManagementInitial());
    when(() => mockHomeBloc.state).thenReturn(HomeInitial());
  });

  Widget buildApp(List<Trip> trips) {
    return localizedRouterApp(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<TripManagementBloc>.value(value: mockTripBloc),
          BlocProvider<HomeBloc>.value(value: mockHomeBloc),
        ],
        child: Scaffold(
          body: HomeTripListSection(
            title: 'Upcoming trips',
            trips: trips,
            compactHeader: true,
          ),
        ),
      ),
    );
  }

  testWidgets('wraps owner trip cards in dismissible swipe-left', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp([makeTrip(id: 'trip-2').copyWith(role: 'OWNER')]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsOneWidget);
    final dismissible = tester.widget<Dismissible>(
      find.byType(Dismissible).first,
    );
    expect(dismissible.direction, DismissDirection.endToStart);
  });

  testWidgets('swipe left asks confirmation then dispatches DeleteTrip', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp([makeTrip(id: 'trip-delete').copyWith(role: 'OWNER')]),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete trip'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => mockTripBloc.add(any(that: isA<DeleteTrip>()))).called(1);
    verify(
      () => mockHomeBloc.add(
        any(
          that: isA<RemoveUpcomingTrip>().having(
            (e) => e.tripId,
            'tripId',
            'trip-delete',
          ),
        ),
      ),
    ).called(1);
  });
}
