import 'package:bagtrip/components/snack_bar_scope.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trips/bloc/trip_share_bloc.dart';
import 'package:bagtrip/trips/view/trip_shares_view.dart';
import 'package:bagtrip/trips/widgets/share_invite_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class MockTripShareBloc extends MockBloc<TripShareEvent, TripShareState>
    implements TripShareBloc {}

void main() {
  late MockTripShareBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(CreateShare(tripId: '', email: ''));
  });

  setUp(() {
    mockBloc = MockTripShareBloc();
  });

  /// Builds the invite sheet directly (not via FAB) for form validation tests.
  Widget buildSheet() {
    when(() => mockBloc.state).thenReturn(TripShareLoaded(shares: []));
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: SnackBarScope(
        child: Scaffold(
          body: BlocProvider<TripShareBloc>.value(
            value: mockBloc,
            child: const ShareInviteSheet(tripId: 'trip-1'),
          ),
        ),
      ),
    );
  }

  /// Builds the full shares view for FAB/role/revoke tests.
  Widget buildView({String role = 'OWNER', TripShareState? state}) {
    when(() => mockBloc.state).thenReturn(state ?? TripShareLoaded(shares: []));
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: SnackBarScope(
        child: BlocProvider<TripShareBloc>.value(
          value: mockBloc,
          child: TripSharesView(tripId: 'trip-1', role: role),
        ),
      ),
    );
  }

  group('ShareInviteSheet — email validation', () {
    testWidgets('shows "required" error for empty email', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      // Tap send without entering email
      await tester.tap(find.text('Send invite'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows "invalid format" error for bad email', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.text('Send invite'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email format'), findsOneWidget);
    });

    testWidgets('valid email submits CreateShare event', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.tap(find.text('Send invite'));
      await tester.pumpAndSettle();

      verify(
        () => mockBloc.add(
          any(
            that: isA<CreateShare>().having(
              (e) => e.email,
              'email',
              'test@example.com',
            ),
          ),
        ),
      ).called(1);
    });
  });

  group('ShareInviteSheet — error messages', () {
    testWidgets('user not found shows specific message', (tester) async {
      final errorState = TripShareError(
        error: const NotFoundError('User not found'),
      );
      whenListen(
        mockBloc,
        Stream.fromIterable([errorState]),
        initialState: TripShareLoaded(shares: []),
      );
      await tester.pumpWidget(buildView(state: errorState));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('This person must create an account first'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('already shared shows specific message', (tester) async {
      final errorState = TripShareError(
        error: const ValidationError('Trip already shared with this user'),
      );
      whenListen(
        mockBloc,
        Stream.fromIterable([errorState]),
        initialState: TripShareLoaded(shares: []),
      );
      await tester.pumpWidget(buildView(state: errorState));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Already shared with this person'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Swipe to revoke', () {
    testWidgets('dismissible exists for owner', (tester) async {
      final shares = [makeTripShare()];
      await tester.pumpWidget(
        buildView(state: TripShareLoaded(shares: shares)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('remove button triggers confirmation dialog', (tester) async {
      final shares = [makeTripShare()];
      await tester.pumpWidget(
        buildView(state: TripShareLoaded(shares: shares)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      // Dialog title
      expect(find.text('Remove access'), findsOneWidget);
    });
  });

  group('Viewer role', () {
    testWidgets('hides FAB when role is VIEWER', (tester) async {
      await tester.pumpWidget(buildView(role: 'VIEWER'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('hides remove button when role is VIEWER', (tester) async {
      final shares = [makeTripShare()];
      await tester.pumpWidget(
        buildView(
          role: 'VIEWER',
          state: TripShareLoaded(shares: shares),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
      expect(find.byType(Dismissible), findsNothing);
    });
  });
}
