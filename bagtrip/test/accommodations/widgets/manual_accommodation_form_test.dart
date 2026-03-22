import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/widgets/manual_accommodation_form.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccommodationBloc extends Mock implements AccommodationBloc {
  @override
  Future<void> close() async {}
}

class FakeAccommodationEvent extends Fake implements AccommodationEvent {}

void main() {
  late MockAccommodationBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(FakeAccommodationEvent());
  });

  setUp(() {
    mockBloc = MockAccommodationBloc();
    when(() => mockBloc.state).thenReturn(AccommodationInitial());
    when(
      () => mockBloc.stream,
    ).thenAnswer((_) => const Stream<AccommodationState>.empty());
  });

  Widget buildApp({Accommodation? existing}) {
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
          child: BlocProvider<AccommodationBloc>.value(
            value: mockBloc,
            child: ManualAccommodationForm(
              tripId: 'trip-1',
              existing: existing,
            ),
          ),
        ),
      ),
    );
  }

  group('ManualAccommodationForm — create mode', () {
    testWidgets('renders with create title and add button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Add manually'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('all fields are empty in create mode', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(nameField.controller?.text, isEmpty);
    });

    testWidgets('validation: empty name shows error on submit', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Add'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('submit fires CreateAccommodation event', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Hotel Test');

      await tester.scrollUntilVisible(
        find.text('Add'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final captured = verify(() => mockBloc.add(captureAny())).captured;
      expect(captured.length, 1);
      expect(captured.first, isA<CreateAccommodation>());
      final event = captured.first as CreateAccommodation;
      expect(event.tripId, 'trip-1');
      expect(event.data['name'], 'Hotel Test');
    });
  });

  group('ManualAccommodationForm — edit mode', () {
    final existing = const Accommodation(
      id: 'acc-1',
      tripId: 'trip-1',
      name: 'Hotel Paris',
      address: '10 Rue de Rivoli',
      pricePerNight: 120.0,
      currency: 'EUR',
      bookingReference: 'REF-123',
      notes: 'Nice view',
    );

    testWidgets('renders with edit title and save button', (tester) async {
      await tester.pumpWidget(buildApp(existing: existing));
      await tester.pumpAndSettle();

      expect(find.text('Edit Accommodation'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('pre-fills all fields from existing accommodation', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(existing: existing));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final nameField = tester.widget<TextFormField>(fields.at(0));
      expect(nameField.controller?.text, 'Hotel Paris');

      final addressField = tester.widget<TextFormField>(fields.at(1));
      expect(addressField.controller?.text, '10 Rue de Rivoli');
    });

    testWidgets('submit fires UpdateAccommodation event', (tester) async {
      await tester.pumpWidget(buildApp(existing: existing));
      await tester.pumpAndSettle();

      // Change name
      await tester.enterText(find.byType(TextFormField).first, 'Hotel Updated');

      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final captured = verify(() => mockBloc.add(captureAny())).captured;
      expect(captured.length, 1);
      expect(captured.first, isA<UpdateAccommodation>());
      final event = captured.first as UpdateAccommodation;
      expect(event.tripId, 'trip-1');
      expect(event.accommodationId, 'acc-1');
      expect(event.data['name'], 'Hotel Updated');
    });
  });

  group('ManualAccommodationForm — time pickers', () {
    testWidgets('displays check-in and check-out time labels', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Check-in time'), findsOneWidget);
      expect(find.text('Check-out time'), findsOneWidget);
    });

    testWidgets('time tiles show placeholder when no time set', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('--:--'), findsNWidgets(2));
    });
  });

  group('ManualAccommodationForm — i18n labels', () {
    testWidgets('address field uses l10n label', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Address'), findsOneWidget);
    });

    testWidgets('reference field uses l10n label', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Booking reference'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Booking reference'), findsOneWidget);
    });
  });
}
