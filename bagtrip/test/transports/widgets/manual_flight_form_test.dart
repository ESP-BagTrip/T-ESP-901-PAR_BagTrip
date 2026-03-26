import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/transports/bloc/transport_bloc.dart';
import 'package:bagtrip/transports/widgets/manual_flight_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransportBloc extends Mock implements TransportBloc {
  @override
  Future<void> close() async {}
}

class FakeTransportEvent extends Fake implements TransportEvent {}

void main() {
  late MockTransportBloc mockTransportBloc;

  setUpAll(() {
    registerFallbackValue(FakeTransportEvent());
  });

  setUp(() {
    mockTransportBloc = MockTransportBloc();
    when(() => mockTransportBloc.state).thenReturn(TransportInitial());
    when(
      () => mockTransportBloc.stream,
    ).thenAnswer((_) => const Stream<TransportState>.empty());
  });

  Widget buildApp({
    String? initialDepartureAirport,
    String? initialArrivalAirport,
    DateTime? initialDepartureDate,
    DateTime? initialArrivalDate,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: BlocProvider<TransportBloc>.value(
            value: mockTransportBloc,
            child: ManualFlightForm(
              tripId: 'trip-1',
              initialDepartureAirport: initialDepartureAirport,
              initialArrivalAirport: initialArrivalAirport,
              initialDepartureDate: initialDepartureDate,
              initialArrivalDate: initialArrivalDate,
            ),
          ),
        ),
      ),
    );
  }

  group('ManualFlightForm', () {
    testWidgets('shows error when flight number is empty on submit', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Scroll to the submit button
      await tester.scrollUntilVisible(
        find.text('Add a flight'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add a flight'));
      await tester.pumpAndSettle();

      expect(find.text('Flight number is required'), findsOneWidget);
    });

    testWidgets('shows error when airports are the same on submit', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Fields order: Dep airport (0), Arr airport (1), Flight number (2)
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'CDG');
      await tester.enterText(fields.at(1), 'CDG');
      await tester.enterText(fields.at(2), 'AF1234');

      // Scroll to the submit button
      await tester.scrollUntilVisible(
        find.text('Add a flight'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add a flight'));
      await tester.pumpAndSettle();

      expect(
        find.text('Departure and arrival airports must be different'),
        findsOneWidget,
      );
    });

    testWidgets('pre-fill values appear in fields on init', (tester) async {
      await tester.pumpWidget(
        buildApp(initialDepartureAirport: 'CDG', initialArrivalAirport: 'NRT'),
      );
      await tester.pumpAndSettle();

      // Find TextFormFields with pre-filled text
      final depField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(0),
      );
      final arrField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );

      expect(depField.controller?.text, 'CDG');
      expect(arrField.controller?.text, 'NRT');
    });

    testWidgets('section labels are displayed', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Route'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);

      // Details may be below fold, scroll to it
      await tester.scrollUntilVisible(
        find.text('Details'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
    });
  });
}
