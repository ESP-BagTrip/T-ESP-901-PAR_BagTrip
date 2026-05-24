// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/flight_search/widgets/manual_flight_trip_details_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

class _MockFlightSearchBloc
    extends MockBloc<FlightSearchEvent, FlightSearchState>
    implements FlightSearchBloc {}

void main() {
  late _MockFlightSearchBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(SetTripType(0));
    registerFallbackValue(FlightSearchInitial());
  });

  setUp(() {
    mockBloc = _MockFlightSearchBloc();
    when(() => mockBloc.state).thenReturn(FlightSearchLoaded());
    whenListen(
      mockBloc,
      const Stream<FlightSearchState>.empty(),
      initialState: FlightSearchLoaded(),
    );
  });

  Future<void> pump(WidgetTester tester, FlightSearchLoaded state) async {
    await pumpLocalized(
      tester,
      BlocProvider<FlightSearchBloc>.value(
        value: mockBloc,
        child: SizedBox(
          width: 400,
          child: ManualFlightTripDetailsCard(state: state),
        ),
      ),
      size: const Size(400, 1000),
    );
    await tester.pump();
  }

  group('ManualFlightTripDetailsCard', () {
    testWidgets('renders default state with 1 adult and no budget', (
      tester,
    ) async {
      await pump(tester, FlightSearchLoaded());
      expect(find.byType(ManualFlightTripDetailsCard), findsOneWidget);
    });

    testWidgets('renders with multiple adults only', (tester) async {
      await pump(tester, FlightSearchLoaded(adults: 3));
      expect(find.byType(ManualFlightTripDetailsCard), findsOneWidget);
    });

    testWidgets('renders with adults, children and infants', (tester) async {
      await pump(
        tester,
        FlightSearchLoaded(adults: 2, children: 2, infants: 1),
      );
      expect(find.byType(ManualFlightTripDetailsCard), findsOneWidget);
    });

    testWidgets('renders with a max budget value set', (tester) async {
      await pump(tester, FlightSearchLoaded(maxPrice: 1200));
      expect(find.byType(ManualFlightTripDetailsCard), findsOneWidget);
    });

    testWidgets('renders with out-of-range budget that gets clamped', (
      tester,
    ) async {
      await pump(tester, FlightSearchLoaded(maxPrice: 5000));
      expect(find.byType(ManualFlightTripDetailsCard), findsOneWidget);
    });
  });
}
