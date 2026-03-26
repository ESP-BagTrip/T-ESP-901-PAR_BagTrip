import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/widgets/accommodation_booking_card.dart';
import 'package:bagtrip/trip_detail/widgets/trip_accommodation_section.dart';
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
    registerFallbackValue(DeleteAccommodationFromDetail(accommodationId: ''));
    registerFallbackValue(RefreshTripDetail());
  });

  setUp(() {
    mockBloc = MockTripDetailBloc();
  });

  group('TripAccommodationSection', () {
    testWidgets('header shows "Accommodations" + icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripAccommodationSection(
            accommodations: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accommodations'), findsOneWidget);
      expect(find.byIcon(Icons.hotel_rounded), findsOneWidget);
    });

    testWidgets('with accommodations → cards rendered', (tester) async {
      final accommodations = [
        makeAccommodation(id: 'a1', name: 'Hotel Luxe'),
        makeAccommodation(id: 'a2', name: 'Airbnb Central'),
      ];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripAccommodationSection(
            accommodations: accommodations,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccommodationBookingCard), findsNWidgets(2));
      expect(find.text('Hotel Luxe'), findsOneWidget);
      expect(find.text('Airbnb Central'), findsOneWidget);
    });

    testWidgets('with 4+ accommodations → "See all" button present', (
      tester,
    ) async {
      final accommodations = List.generate(
        4,
        (i) => makeAccommodation(id: 'a$i', name: 'Place $i'),
      );

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripAccommodationSection(
            accommodations: accommodations,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only 3 cards shown as preview
      expect(find.byType(AccommodationBookingCard), findsNWidgets(3));
      // "See all accommodations (4)" button
      expect(find.text('See all accommodations (4)'), findsOneWidget);
    });

    testWidgets('empty OWNER → 2 CTA option tiles visible', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripAccommodationSection(
            accommodations: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Where will you stay?'), findsOneWidget);
      expect(find.text('Search a hotel'), findsOneWidget);
      expect(find.text('Add manually'), findsOneWidget);
    });

    testWidgets('empty VIEWER → no CTA tiles', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripAccommodationSection(
            accommodations: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Where will you stay?'), findsOneWidget);
      expect(find.text('Search a hotel'), findsNothing);
      expect(find.text('Add manually'), findsNothing);
    });

    testWidgets('empty COMPLETED → no CTA tiles', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripAccommodationSection(
            accommodations: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Where will you stay?'), findsOneWidget);
      expect(find.text('Search a hotel'), findsNothing);
      expect(find.text('Add manually'), findsNothing);
    });

    testWidgets('delete swipe → fires DeleteAccommodationFromDetail on bloc', (
      tester,
    ) async {
      final accommodations = [makeAccommodation(id: 'a-del')];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripAccommodationSection(
            accommodations: accommodations,
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
        () => mockBloc.add(any(that: isA<DeleteAccommodationFromDetail>())),
      ).called(1);
    });
  });
}
