// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/models/user_role.dart';
import 'package:bagtrip/trip_detail/view/panels/trip_panel_empty_state.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/validation_status.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/view/panels/hotel_panel.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_fixtures.dart';

class _MockTripDetailBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

void main() {
  late _MockTripDetailBloc bloc;

  setUpAll(() {
    registerFallbackValue(
      CreateAccommodationFromDetail(data: <String, dynamic>{}),
    );
    registerFallbackValue(DeleteAccommodationFromDetail(accommodationId: 'x'));
    registerFallbackValue(
      ValidateAccommodationFromDetail(accommodationId: 'x'),
    );
  });

  setUp(() {
    bloc = _MockTripDetailBloc();
    when(() => bloc.state).thenReturn(
      TripDetailLoaded(
        trip: makeTrip(),
        activities: const [],
        flights: const [],
        accommodations: const [],
        baggageItems: const [],
        shares: const [],
        userRole: UserRole.owner,
        selectedDayIndex: 0,
        deferredLoaded: true,
        sectionErrors: const {},
        completionResult: const CompletionResult(percentage: 0, segments: {}),
      ),
    );
  });

  Future<void> pump(WidgetTester tester, Widget panel) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider<TripDetailBloc>.value(value: bloc, child: panel),
        ),
      ),
    );
  }

  testWidgets('empty state shows CTA when canEdit is true', (tester) async {
    await pump(
      tester,
      HotelPanel(
        tripId: 'trip-1',
        trip: makeTrip(),
        accommodations: const [],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(TripPanelEmptyState), findsOneWidget);
    expect(find.text('Add now'), findsOneWidget);
  });

  testWidgets('renders each accommodation', (tester) async {
    final accs = [
      makeAccommodation(id: 'a1', name: 'Hotel Kyoto'),
      makeAccommodation(id: 'a2', name: 'Ryokan Arashiyama'),
    ];
    await pump(
      tester,
      HotelPanel(
        tripId: 'trip-1',
        trip: makeTrip(),
        accommodations: accs,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.text('Hotel Kyoto'), findsOneWidget);
    expect(find.text('Ryokan Arashiyama'), findsOneWidget);
  });

  testWidgets('renders redesigned hotel card sections', (tester) async {
    final acc = makeAccommodation(
      id: 'a1',
      name: 'Garden Court Nelson Mandela Boulevard',
      address: 'Stockholm, Sweden',
      checkIn: DateTime(2026, 5, 28),
      checkOut: DateTime(2026, 5, 31),
      pricePerNight: 2150,
    );
    await pump(
      tester,
      HotelPanel(
        tripId: 'trip-1',
        trip: makeTrip(),
        accommodations: [acc],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );

    expect(find.text('CHECK-IN'), findsOneWidget);
    expect(find.text('CHECK-OUT'), findsOneWidget);
    expect(find.text('TOTAL STAY'), findsOneWidget);
    expect(find.textContaining('28'), findsWidgets);
    expect(find.textContaining('31'), findsWidgets);
    expect(find.textContaining('/ per night'), findsOneWidget);
  });

  testWidgets('PanelFab visible in edit mode', (tester) async {
    await pump(
      tester,
      HotelPanel(
        tripId: 'trip-1',
        trip: makeTrip(),
        accommodations: [makeAccommodation()],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(PanelFab), findsOneWidget);
  });

  testWidgets('PanelFab hidden in viewer mode', (tester) async {
    await pump(
      tester,
      HotelPanel(
        tripId: 'trip-1',
        trip: makeTrip(),
        accommodations: [makeAccommodation()],
        canEdit: false,
        isCompleted: false,
        role: 'VIEWER',
      ),
    );
    expect(find.byType(PanelFab), findsNothing);
  });

  testWidgets(
    'suggested accommodation uses horizontal dismissible and validates on right swipe',
    (tester) async {
      final suggested = makeAccommodation(
        id: 's1',
        validationStatus: ValidationStatus.suggested,
      );
      await pump(
        tester,
        HotelPanel(
          tripId: 'trip-1',
          trip: makeTrip(),
          accommodations: [suggested],
          canEdit: true,
          isCompleted: false,
          role: 'OWNER',
        ),
      );

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.direction, DismissDirection.horizontal);
      expect(dismissible.background, isNotNull);
      expect(dismissible.secondaryBackground, isNotNull);

      await tester.drag(find.text('Hotel Paris'), const Offset(400, 0));
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(any(that: isA<ValidateAccommodationFromDetail>())),
      ).called(1);
    },
  );

  testWidgets('manual accommodation only allows delete swipe direction', (
    tester,
  ) async {
    final manual = makeAccommodation(
      id: 'm1',
      validationStatus: ValidationStatus.manual,
    );
    await pump(
      tester,
      HotelPanel(
        tripId: 'trip-1',
        trip: makeTrip(),
        accommodations: [manual],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );

    final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    expect(dismissible.direction, DismissDirection.endToStart);
  });
}
