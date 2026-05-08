// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/view/panels/activities_panel.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

Activity _datedActivity({
  String id = 'a1',
  ValidationStatus status = ValidationStatus.manual,
}) {
  return Activity(
    id: id,
    tripId: 'trip-1',
    title: 'Senso-ji visit',
    category: ActivityCategory.culture,
    date: DateTime(2026, 6, 2),
    validationStatus: status,
  );
}

Activity _foodReco({String id = 'f1'}) => Activity(
  id: id,
  tripId: 'trip-1',
  title: 'Sushi Saito',
  category: ActivityCategory.food,
  validationStatus: ValidationStatus.suggested,
);

Activity _transportReco({String id = 't1'}) => Activity(
  id: id,
  tripId: 'trip-1',
  title: 'JR Pass 7 days',
  category: ActivityCategory.transport,
  validationStatus: ValidationStatus.suggested,
);

void main() {
  setUpAll(() {
    registerFallbackValue(ValidateActivity(activityId: 'x'));
  });

  Widget pump({required List<Activity> activities, _MockBloc? bloc}) {
    final mock = bloc ?? _MockBloc();
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: BlocProvider<TripDetailBloc>.value(
          value: mock,
          child: ActivitiesPanel(
            tripId: 'trip-1',
            tripStartDate: DateTime(2026, 6, 1),
            activities: activities,
            totalDays: 3,
            selectedDayIndex: 1,
            canEdit: true,
            isCompleted: false,
            role: 'OWNER',
          ),
        ),
      ),
    );
  }

  group('ActivitiesPanel', () {
    testWidgets('renders Planning + Recos segmented control', (tester) async {
      await tester.pumpWidget(pump(activities: const []));
      await tester.pump();

      expect(find.text('Planning'), findsOneWidget);
      expect(find.text('Recos'), findsOneWidget);
    });

    testWidgets('Planning mode renders day selector chips', (tester) async {
      await tester.pumpWidget(pump(activities: [_datedActivity()]));
      await tester.pump();

      // 3 day chips (J1, J2, J3) are rendered when totalDays > 1.
      expect(find.text('J1'), findsOneWidget);
      expect(find.text('J2'), findsOneWidget);
      expect(find.text('J3'), findsOneWidget);
    });

    testWidgets('Recos mode surfaces undated FOOD + TRANSPORT', (tester) async {
      await tester.pumpWidget(
        pump(activities: [_datedActivity(), _foodReco(), _transportReco()]),
      );
      await tester.pump();

      // Switch to Recos.
      await tester.tap(find.text('Recos'));
      await tester.pumpAndSettle();

      // Both AI recommendations are now visible — they were filtered
      // out of the legacy timeline by parent code (friction #5).
      expect(find.text('Sushi Saito'), findsOneWidget);
      expect(find.text('JR Pass 7 days'), findsOneWidget);
      // Section headers explain why each row is grouped where it is.
      expect(find.text('RESTAURANTS'), findsOneWidget);
      expect(find.text('TRANSPORTS'), findsOneWidget);
    });

    testWidgets('Recos empty state when no undated recommendations', (
      tester,
    ) async {
      await tester.pumpWidget(pump(activities: [_datedActivity()]));
      await tester.pump();

      await tester.tap(find.text('Recos'));
      await tester.pumpAndSettle();

      expect(
        find.text('No restaurant or transport recommendations for this trip.'),
        findsOneWidget,
      );
    });
  });
}
