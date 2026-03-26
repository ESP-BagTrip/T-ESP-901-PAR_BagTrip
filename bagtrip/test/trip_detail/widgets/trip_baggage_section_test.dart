import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/widgets/baggage_checklist_card.dart';
import 'package:bagtrip/trip_detail/widgets/trip_baggage_section.dart';
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
    registerFallbackValue(ToggleBaggagePackedFromDetail(baggageItemId: ''));
    registerFallbackValue(DeleteBaggageItemFromDetail(baggageItemId: ''));
    registerFallbackValue(RefreshTripDetail());
  });

  setUp(() {
    mockBloc = MockTripDetailBloc();
  });

  group('TripBaggageSection', () {
    testWidgets('header shows "Luggage" + icon + progress bar', (tester) async {
      final items = [
        makeBaggageItem(id: 'b1', name: 'Shirt', isPacked: true),
        makeBaggageItem(id: 'b2', name: 'Pants'),
      ];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBaggageSection(
            baggageItems: items,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Luggage'), findsOneWidget);
      expect(find.byIcon(Icons.luggage_rounded), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('with 2 items → 2 BaggageChecklistCard rendered', (
      tester,
    ) async {
      final items = [
        makeBaggageItem(id: 'b1'),
        makeBaggageItem(id: 'b2', name: 'Sunscreen'),
      ];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBaggageSection(
            baggageItems: items,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BaggageChecklistCard), findsNWidgets(2));
      expect(find.text('Passport'), findsOneWidget);
      expect(find.text('Sunscreen'), findsOneWidget);
    });

    testWidgets('with 4+ items → only 3 cards + "See all" button', (
      tester,
    ) async {
      final items = List.generate(
        4,
        (i) => makeBaggageItem(id: 'b$i', name: 'Item $i'),
      );

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBaggageSection(
            baggageItems: items,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BaggageChecklistCard), findsNWidgets(3));
      expect(find.text('See all items (4)'), findsOneWidget);
    });

    testWidgets('empty OWNER → empty state title + 2 CTA tiles', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBaggageSection(
            baggageItems: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('What do you need to pack?'), findsOneWidget);
      expect(find.text('Add an item'), findsOneWidget);
      expect(find.text('Get AI suggestions'), findsOneWidget);
    });

    testWidgets('empty VIEWER → title shown, no CTAs', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBaggageSection(
            baggageItems: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('What do you need to pack?'), findsOneWidget);
      expect(find.text('Add an item'), findsNothing);
      expect(find.text('Get AI suggestions'), findsNothing);
    });

    testWidgets('empty COMPLETED → title shown, no CTAs', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBaggageSection(
            baggageItems: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('What do you need to pack?'), findsOneWidget);
      expect(find.text('Add an item'), findsNothing);
      expect(find.text('Get AI suggestions'), findsNothing);
    });

    testWidgets('checkbox tap → fires ToggleBaggagePackedFromDetail', (
      tester,
    ) async {
      final items = [makeBaggageItem(id: 'b-toggle', name: 'Toothbrush')];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBaggageSection(
            baggageItems: items,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the checkbox (AnimatedContainer with 28px width)
      final checkbox = find.byWidgetPredicate(
        (w) => w is AnimatedContainer && w.constraints?.maxWidth == 28,
      );
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      verify(
        () => mockBloc.add(any(that: isA<ToggleBaggagePackedFromDetail>())),
      ).called(1);
    });

    testWidgets('swipe-to-delete → fires DeleteBaggageItemFromDetail', (
      tester,
    ) async {
      final items = [makeBaggageItem(id: 'b-del', name: 'Shorts')];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBaggageSection(
            baggageItems: items,
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
        () => mockBloc.add(any(that: isA<DeleteBaggageItemFromDetail>())),
      ).called(1);
    });
  });
}
