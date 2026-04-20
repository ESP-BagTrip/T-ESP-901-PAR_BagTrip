// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
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
        userRole: 'OWNER',
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
    expect(find.byType(ElegantEmptyState), findsOneWidget);
    expect(find.text('Add stay'), findsOneWidget);
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
}
