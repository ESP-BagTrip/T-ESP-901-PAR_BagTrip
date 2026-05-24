import 'package:bagtrip/components/snack_bar_scope.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trips/bloc/trip_share_bloc.dart';
import 'package:bagtrip/trips/widgets/share_invite_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

  group('ShareInviteSheet — email validation', () {
    testWidgets('shows "required" error for empty email', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

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

    testWidgets('onSubmit callback receives email / role / message', (
      tester,
    ) async {
      String? capturedEmail;
      String? capturedRole;
      String? capturedMessage;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: SnackBarScope(
            child: Scaffold(
              body: ShareInviteSheet(
                tripId: 'trip-1',
                onSubmit: ({required email, required role, message}) {
                  capturedEmail = email;
                  capturedRole = role;
                  capturedMessage = message;
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'friend@example.com',
      );
      await tester.tap(find.text('Send invite'));
      await tester.pumpAndSettle();

      expect(capturedEmail, 'friend@example.com');
      expect(capturedRole, 'VIEWER');
      expect(capturedMessage, isNull);
    });
  });
}
