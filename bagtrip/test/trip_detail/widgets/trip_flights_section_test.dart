import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/widgets/flight_boarding_pass_card.dart';
import 'package:bagtrip/trip_detail/widgets/trip_flights_section.dart';
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

void main() {
  late MockTripDetailBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(DeleteFlightFromDetail(flightId: ''));
    registerFallbackValue(RefreshTripDetail());
  });

  setUp(() {
    mockBloc = MockTripDetailBloc();
  });

  group('TripFlightsSection', () {
    testWidgets('header shows "Flights" + icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripFlightsSection(
            flights: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flights'), findsOneWidget);
      expect(find.byIcon(Icons.flight_rounded), findsOneWidget);
    });

    testWidgets('with flights → FlightBoardingPassCard widgets rendered', (
      tester,
    ) async {
      final flights = [
        makeManualFlight(id: 'f1', flightNumber: 'AF100'),
        makeManualFlight(id: 'f2', flightNumber: 'LH200'),
      ];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripFlightsSection(
            flights: flights,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FlightBoardingPassCard), findsNWidgets(2));
      expect(find.text('AF100'), findsOneWidget);
      expect(find.text('LH200'), findsOneWidget);
    });

    testWidgets('with 4+ flights → "See all" button present', (tester) async {
      final flights = List.generate(
        4,
        (i) => makeManualFlight(id: 'f$i', flightNumber: 'FL$i'),
      );

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripFlightsSection(
            flights: flights,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only 3 cards shown as preview
      expect(find.byType(FlightBoardingPassCard), findsNWidgets(3));
      // "See all flights (4)" button
      expect(find.text('See all flights (4)'), findsOneWidget);
    });

    testWidgets('empty OWNER → 2 CTA option tiles visible', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripFlightsSection(
            flights: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Where are you flying?'), findsOneWidget);
      expect(find.text('Search a flight'), findsOneWidget);
      expect(find.text('Add manually'), findsOneWidget);
    });

    testWidgets('empty VIEWER → no CTA tiles', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripFlightsSection(
            flights: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Where are you flying?'), findsOneWidget);
      expect(find.text('Search a flight'), findsNothing);
      expect(find.text('Add manually'), findsNothing);
    });

    testWidgets('empty COMPLETED → no CTA tiles', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripFlightsSection(
            flights: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Where are you flying?'), findsOneWidget);
      expect(find.text('Search a flight'), findsNothing);
      expect(find.text('Add manually'), findsNothing);
    });

    testWidgets('delete swipe → fires DeleteFlightFromDetail on bloc', (
      tester,
    ) async {
      final flights = [makeManualFlight(id: 'f-del')];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripFlightsSection(
            flights: flights,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(find.byType(Dismissible), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      verify(
        () => mockBloc.add(any(that: isA<DeleteFlightFromDetail>())),
      ).called(1);
    });
  });
}
