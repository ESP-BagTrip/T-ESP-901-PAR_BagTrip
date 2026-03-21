import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/widgets/trip_sharing_section.dart';
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
    registerFallbackValue(DeleteShareFromDetail(shareId: ''));
    registerFallbackValue(RefreshTripDetail());
  });

  setUp(() {
    mockBloc = MockTripDetailBloc();
  });

  group('TripSharingSection', () {
    testWidgets('header shows "Sharing" + people icon + count badge', (
      tester,
    ) async {
      final shares = [
        makeTripShare(id: 's1', userFullName: 'Alice'),
        makeTripShare(id: 's2', userFullName: 'Bob'),
      ];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripSharingSection(
            shares: shares,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sharing'), findsOneWidget);
      expect(find.byIcon(Icons.people_rounded), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('with 2 shares → 2 participant tiles + owner row', (
      tester,
    ) async {
      final shares = [
        makeTripShare(id: 's1', userFullName: 'Alice'),
        makeTripShare(id: 's2', userFullName: 'Bob'),
      ];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripSharingSection(
            shares: shares,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('You'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('with 4+ shares → only 3 viewer tiles + "See all" button', (
      tester,
    ) async {
      final shares = List.generate(
        4,
        (i) => makeTripShare(id: 's$i', userFullName: 'User $i'),
      );

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripSharingSection(
            shares: shares,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Owner row + 3 viewer tiles = 4 CircleAvatars
      expect(find.byType(CircleAvatar), findsNWidgets(4));
      expect(find.text('See all members (4)'), findsOneWidget);
    });

    testWidgets('owner row is always shown and has no remove button', (
      tester,
    ) async {
      final shares = [makeTripShare(id: 's1', userFullName: 'Alice')];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripSharingSection(
            shares: shares,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Owner row is visible
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);

      // Only one remove button (for Alice), not for owner
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });

    testWidgets('empty OWNER → empty state title + CTA tile', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripSharingSection(
            shares: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share your trip'), findsOneWidget);
      expect(find.text('Invite someone'), findsOneWidget);
    });

    testWidgets('empty VIEWER → title shown, no CTA', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripSharingSection(
            shares: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share your trip'), findsOneWidget);
      expect(find.text('Invite someone'), findsNothing);
    });

    testWidgets('empty COMPLETED → title shown, no CTA', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripSharingSection(
            shares: const [],
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share your trip'), findsOneWidget);
      expect(find.text('Invite someone'), findsNothing);
    });

    testWidgets('remove button tap → fires DeleteShareFromDetail', (
      tester,
    ) async {
      final shares = [makeTripShare(id: 's-del', userFullName: 'Alice')];

      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripSharingSection(
            shares: shares,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      verify(
        () => mockBloc.add(any(that: isA<DeleteShareFromDetail>())),
      ).called(1);
    });
  });
}
