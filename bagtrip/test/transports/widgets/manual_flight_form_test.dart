import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/manual_flight.dart';
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
    ManualFlight? existing,
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
              existing: existing,
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

    testWidgets('edit mode shows Edit flight title and Save button', (
      tester,
    ) async {
      const existing = ManualFlight(
        id: 'fl-1',
        tripId: 'trip-1',
        flightNumber: 'AF1234',
        airline: 'Air France',
        departureAirport: 'CDG',
        arrivalAirport: 'NRT',
        price: 450.0,
      );

      await tester.pumpWidget(buildApp(existing: existing));
      await tester.pumpAndSettle();

      // Title should be "Edit flight"
      expect(find.text('Edit flight'), findsOneWidget);

      // Pre-filled controllers
      final flightField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(2),
      );
      expect(flightField.controller?.text, 'AF1234');

      final depField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(0),
      );
      expect(depField.controller?.text, 'CDG');

      final arrField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      expect(arrField.controller?.text, 'NRT');

      // Scroll to submit button — should say "Save" not "Add a flight"
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Add a flight'), findsNothing);
    });

    testWidgets('edit mode dispatches UpdateManualFlight on submit', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => SingleChildScrollView(
                  child: BlocProvider<TransportBloc>.value(
                    value: mockTransportBloc,
                    child: const ManualFlightForm(
                      tripId: 'trip-1',
                      existing: ManualFlight(
                        id: 'fl-1',
                        tripId: 'trip-1',
                        flightNumber: 'AF1234',
                        departureAirport: 'CDG',
                        arrivalAirport: 'NRT',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to submit button
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final captured = verify(
        () => mockTransportBloc.add(captureAny()),
      ).captured;
      expect(captured.any((e) => e is UpdateManualFlight), isTrue);
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

  group('ManualFlightForm — panel mode (onSave callback)', () {
    testWidgets('renders without a TransportBloc in scope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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
              child: ManualFlightForm(tripId: 'trip-1', onSave: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ManualFlightForm), findsOneWidget);
    });

    testWidgets('does not touch TransportBloc when typing flight number', (
      tester,
    ) async {
      // Guard against the regression that caused ProviderNotFoundException:
      // typing 4+ chars used to fire a `context.read<TransportBloc>()` even
      // when the form was driven from a panel without TransportBloc in scope.
      await tester.pumpWidget(
        MaterialApp(
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
              child: ManualFlightForm(tripId: 'trip-1', onSave: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'AF1234');
      await tester.pump(const Duration(seconds: 1));
      // If the debounced lookup had fired, the test would throw a
      // ProviderNotFoundException. Reaching this assertion means we correctly
      // skipped the bloc read in panel mode.
      expect(find.byType(ManualFlightForm), findsOneWidget);
    });
  });
}
