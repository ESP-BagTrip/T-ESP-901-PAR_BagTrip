// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/view/panels/shares_panel.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_fixtures.dart';

class _MockTripDetailBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

TripShare _share({
  String id = 'share-1',
  String userEmail = 'friend@example.com',
  String? userFullName,
  String role = 'VIEWER',
}) {
  return TripShare(
    id: id,
    tripId: 'trip-1',
    userId: 'user-$id',
    userEmail: userEmail,
    userFullName: userFullName,
    role: role,
    invitedAt: DateTime(2026, 4, 1),
  );
}

void main() {
  late _MockTripDetailBloc bloc;

  setUpAll(() {
    registerFallbackValue(
      CreateShareFromDetail(email: 'x@y.com', role: 'VIEWER'),
    );
    registerFallbackValue(DeleteShareFromDetail(shareId: 'x'));
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

  testWidgets('empty state shows invite CTA', (tester) async {
    await pump(
      tester,
      const SharesPanel(tripId: 'trip-1', shares: [], role: 'OWNER'),
    );
    expect(find.byType(ElegantEmptyState), findsOneWidget);
    expect(find.text('Invite'), findsOneWidget);
  });

  testWidgets('renders invite button above share list', (tester) async {
    await pump(
      tester,
      SharesPanel(
        tripId: 'trip-1',
        shares: [
          _share(id: 's1'),
          _share(id: 's2', role: 'EDITOR'),
        ],
        role: 'OWNER',
      ),
    );
    expect(find.text('Invite'), findsOneWidget);
    expect(find.text('VIEWER'), findsOneWidget);
    expect(find.text('EDITOR'), findsOneWidget);
  });

  testWidgets('renders one row per share', (tester) async {
    final shares = [
      _share(id: 's1', userEmail: 'a@example.com'),
      _share(id: 's2', userEmail: 'b@example.com'),
      _share(id: 's3', userEmail: 'c@example.com'),
    ];
    await pump(
      tester,
      SharesPanel(tripId: 'trip-1', shares: shares, role: 'OWNER'),
    );
    expect(find.text('a@example.com'), findsOneWidget);
    expect(find.text('b@example.com'), findsOneWidget);
    expect(find.text('c@example.com'), findsOneWidget);
  });
}
