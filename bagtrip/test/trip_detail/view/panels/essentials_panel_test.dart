// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/widgets/review/pack_item.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/view/panels/essentials_panel.dart';
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
      ToggleBaggagePackedFromDetail(baggageItemId: 'bag-1'),
    );
    registerFallbackValue(DeleteBaggageItemFromDetail(baggageItemId: 'bag-1'));
    registerFallbackValue(
      CreateBaggageItemFromDetail(data: <String, dynamic>{}),
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
        userRole: 'OWNER',
        selectedDayIndex: 0,
        deferredLoaded: true,
        sectionErrors: const {},
        completionResult: const CompletionResult(percentage: 0, segments: {}),
      ),
    );
  });

  Future<void> pump(WidgetTester tester, EssentialsPanel panel) {
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

  testWidgets('empty state renders CTA label when canEdit is true', (
    tester,
  ) async {
    await pump(
      tester,
      const EssentialsPanel(
        tripId: 'trip-1',
        items: [],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(ElegantEmptyState), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);
  });

  testWidgets('empty state hides CTA in viewer mode', (tester) async {
    await pump(
      tester,
      const EssentialsPanel(
        tripId: 'trip-1',
        items: [],
        canEdit: false,
        isCompleted: false,
        role: 'VIEWER',
      ),
    );
    expect(find.byType(ElegantEmptyState), findsOneWidget);
    expect(find.text('Add item'), findsNothing);
  });

  testWidgets('tapping a PackItem dispatches ToggleBaggagePackedFromDetail', (
    tester,
  ) async {
    final item = makeBaggageItem(id: 'bag-42', name: 'Passport');
    await pump(
      tester,
      EssentialsPanel(
        tripId: 'trip-1',
        items: [item],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );

    await tester.tap(find.byType(PackItem).first);
    await tester.pump();

    verify(
      () => bloc.add(
        any(
          that: isA<ToggleBaggagePackedFromDetail>().having(
            (e) => e.baggageItemId,
            'baggageItemId',
            'bag-42',
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('PanelFab is visible when canEdit is true', (tester) async {
    final item = makeBaggageItem(id: 'bag-42');
    await pump(
      tester,
      EssentialsPanel(
        tripId: 'trip-1',
        items: [item],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(PanelFab), findsOneWidget);
  });

  testWidgets('PanelFab is hidden when canEdit is false', (tester) async {
    final item = makeBaggageItem(id: 'bag-42');
    await pump(
      tester,
      EssentialsPanel(
        tripId: 'trip-1',
        items: [item],
        canEdit: false,
        isCompleted: false,
        role: 'VIEWER',
      ),
    );
    expect(find.byType(PanelFab), findsNothing);
  });

  testWidgets('tapping "See full checklist" navigates out', (tester) async {
    final item = makeBaggageItem(id: 'bag-42');
    await pump(
      tester,
      EssentialsPanel(
        tripId: 'trip-1',
        items: [item],
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.text('See full checklist'), findsOneWidget);
  });
}
