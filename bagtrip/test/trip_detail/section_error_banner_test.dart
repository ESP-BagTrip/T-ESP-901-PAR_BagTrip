// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/widgets/section_error_banner.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class _MockTripDetailBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

TripDetailLoaded _loaded({Map<String, AppError> sectionErrors = const {}}) {
  return TripDetailLoaded(
    trip: makeTrip(),
    activities: const [],
    flights: const [],
    accommodations: const [],
    baggageItems: const [],
    shares: const [],
    userRole: 'OWNER',
    selectedDayIndex: 0,
    deferredLoaded: true,
    sectionErrors: sectionErrors,
    completionResult: const CompletionResult(percentage: 0, segments: {}),
  );
}

void main() {
  late _MockTripDetailBloc bloc;

  setUpAll(() {
    registerFallbackValue(RetryDeferredSection(section: 'flights'));
  });

  setUp(() {
    bloc = _MockTripDetailBloc();
  });

  Future<void> pump(WidgetTester tester, {required String section}) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider<TripDetailBloc>.value(
            value: bloc,
            child: SectionErrorBanner(section: section),
          ),
        ),
      ),
    );
  }

  testWidgets('hides (SizedBox.shrink) when the section has no error', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(_loaded());
    await pump(tester, section: 'flights');
    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('hides when another section errored but not the one watched', (
    tester,
  ) async {
    when(
      () => bloc.state,
    ).thenReturn(_loaded(sectionErrors: const {'budget': ServerError('boom')}));
    await pump(tester, section: 'flights');
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('shows the friendly message + retry when the section errored', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    when(() => bloc.state).thenReturn(
      _loaded(sectionErrors: const {'flights': ServerError('boom')}),
    );
    await pump(tester, section: 'flights');

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text(l10n.errorServer), findsOneWidget);
    expect(find.text(l10n.retryButton), findsOneWidget);
  });

  testWidgets('tapping Retry dispatches RetryDeferredSection for the section', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    when(() => bloc.state).thenReturn(
      _loaded(sectionErrors: const {'budget': NetworkError('offline')}),
    );
    await pump(tester, section: 'budget');

    await tester.tap(find.text(l10n.retryButton));
    await tester.pump();

    final captured = verify(() => bloc.add(captureAny())).captured;
    expect(captured, hasLength(1));
    final event = captured.single;
    expect(event, isA<RetryDeferredSection>());
    expect((event as RetryDeferredSection).section, 'budget');
  });
}
