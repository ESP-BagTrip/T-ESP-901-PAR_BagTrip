// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/design/widgets/premium_step_indicator.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/budget_preset.dart';
import 'package:bagtrip/plan_trip/models/date_mode.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/plan_trip/view/plan_trip_flow_page.dart';
import 'package:bagtrip/plan_trip/view/step_dates_view.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocationService extends Mock implements LocationService {}

class _MockTripRepository extends Mock implements TripRepository {}

class _MockAiRepository extends Mock implements AiRepository {
  @override
  Stream<Map<String, dynamic>> planTripStream({
    String? travelTypes,
    String? budgetRange,
    int? durationDays,
    String? companions,
    String? constraints,
    String? departureDate,
    String? returnDate,
    String? originCity,
    String? destinationCity,
    String? destinationIata,
    String? mode,
    String? locale,
  }) => const Stream<Map<String, dynamic>>.empty();
}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPersonalizationStorage extends Mock
    implements PersonalizationStorage {}

void main() {
  setUp(() {
    // Reset and register mock dependencies for PlanTripBloc
    if (getIt.isRegistered<LocationService>()) {
      getIt.unregister<LocationService>();
    }
    if (getIt.isRegistered<TripRepository>()) {
      getIt.unregister<TripRepository>();
    }
    if (getIt.isRegistered<AiRepository>()) {
      getIt.unregister<AiRepository>();
    }
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    if (getIt.isRegistered<PersonalizationStorage>()) {
      getIt.unregister<PersonalizationStorage>();
    }

    getIt.registerLazySingleton<LocationService>(() => _MockLocationService());
    getIt.registerLazySingleton<TripRepository>(() => _MockTripRepository());
    getIt.registerLazySingleton<AiRepository>(() => _MockAiRepository());
    getIt.registerLazySingleton<AuthRepository>(() => _MockAuthRepository());
    getIt.registerLazySingleton<PersonalizationStorage>(
      () => _MockPersonalizationStorage(),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildApp({LocationResult? initialDestination, Locale? locale}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale ?? const Locale('en'),
      home: PlanTripFlowPage(initialDestination: initialDestination),
    );
  }

  PlanTripBloc blocOf(WidgetTester tester) {
    final ctx = tester.element(find.byType(PageView).first);
    return BlocProvider.of<PlanTripBloc>(ctx);
  }

  group('PlanTripFlowPage', () {
    testWidgets('renders PremiumStepIndicator', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(PremiumStepIndicator), findsOneWidget);
    });

    testWidgets('renders AppBar with close button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('renders StepDatesView on step 0', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(StepDatesView), findsOneWidget);
    });

    testWidgets('shows step title for dates', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('When are you going?'), findsOneWidget);
    });
  });

  group('PlanTripFlowPage reinforcement', () {
    testWidgets('renders with French locale', (tester) async {
      await tester.pumpWidget(buildApp(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      expect(find.byType(PlanTripFlowPage), findsOneWidget);
      expect(find.byType(PremiumStepIndicator), findsOneWidget);
    });

    testWidgets('renders with initialDestination (isManualFlow=true)', (
      tester,
    ) async {
      const destination = LocationResult(
        name: 'Paris',
        iataCode: 'PAR',
        city: 'Paris',
        countryCode: 'FR',
        countryName: 'France',
        subType: 'CITY',
      );
      await tester.pumpWidget(buildApp(initialDestination: destination));
      await tester.pump();
      await tester.pump();

      expect(find.byType(PlanTripFlowPage), findsOneWidget);
      final bloc = blocOf(tester);
      expect(bloc.state.isManualFlow, isTrue);
      expect(bloc.state.selectedManualDestination?.city, 'Paris');
    });

    testWidgets('navigates to step 1 (travelers) after setting dates', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final bloc = blocOf(tester);
      bloc.add(
        PlanTripEvent.setExactDates(DateTime(2024, 6, 1), DateTime(2024, 6, 8)),
      );
      bloc.add(const PlanTripEvent.goToStep(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(bloc.state.currentStep, 1);
      expect(bloc.state.startDate, isNotNull);
      expect(find.byType(PlanTripFlowPage), findsOneWidget);
    });

    testWidgets(
      'navigates to step 2 (destination) with travelers + budget set',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final bloc = blocOf(tester);
        bloc.add(
          PlanTripEvent.setExactDates(
            DateTime(2024, 6, 1),
            DateTime(2024, 6, 8),
          ),
        );
        bloc.add(
          const PlanTripEvent.setTravelerCounts(
            adults: 2,
            children: 1,
            babies: 0,
          ),
        );
        bloc.add(const PlanTripEvent.setBudgetPreset(BudgetPreset.comfortable));
        bloc.add(const PlanTripEvent.goToStep(2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(bloc.state.currentStep, 2);
        expect(bloc.state.budgetPreset, BudgetPreset.comfortable);
        expect(find.byType(PlanTripFlowPage), findsOneWidget);
      },
    );

    testWidgets('navigates to step 3 (AI proposals) with destination set', (
      tester,
    ) async {
      const destination = LocationResult(
        name: 'Tokyo',
        iataCode: 'TYO',
        city: 'Tokyo',
        countryCode: 'JP',
        countryName: 'Japan',
        subType: 'CITY',
      );
      await tester.pumpWidget(buildApp(initialDestination: destination));
      await tester.pump();
      await tester.pump();

      final bloc = blocOf(tester);
      bloc.add(
        PlanTripEvent.setExactDates(DateTime(2024, 6, 1), DateTime(2024, 6, 8)),
      );
      bloc.add(const PlanTripEvent.setBudgetPreset(BudgetPreset.premium));
      bloc.add(const PlanTripEvent.goToStep(3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(bloc.state.currentStep, 3);
      expect(bloc.state.isDestinationValid, isTrue);
      expect(find.byType(PlanTripFlowPage), findsOneWidget);
    });

    testWidgets('flexible date mode renders step 0 without date indicator', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final bloc = blocOf(tester);
      bloc.add(const PlanTripEvent.setDateMode(DateMode.flexible));
      bloc.add(const PlanTripEvent.setFlexibleDuration(DurationPreset.oneWeek));
      await tester.pump();

      expect(bloc.state.dateMode, DateMode.flexible);
      expect(bloc.state.flexibleDuration, DurationPreset.oneWeek);
      expect(find.byType(PlanTripFlowPage), findsOneWidget);
    });

    testWidgets('month date mode sets preferred month/year', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final bloc = blocOf(tester);
      bloc.add(const PlanTripEvent.setDateMode(DateMode.month));
      bloc.add(const PlanTripEvent.setMonthPreference(7, 2024));
      await tester.pump();

      expect(bloc.state.dateMode, DateMode.month);
      expect(bloc.state.preferredMonth, 7);
      expect(bloc.state.preferredYear, 2024);
      expect(find.byType(PlanTripFlowPage), findsOneWidget);
    });

    testWidgets('previous step event from step 1 returns to step 0', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final bloc = blocOf(tester);
      bloc.add(const PlanTripEvent.goToStep(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(bloc.state.currentStep, 1);

      bloc.add(const PlanTripEvent.previousStep());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(bloc.state.currentStep, 0);

      expect(find.byType(PlanTripFlowPage), findsOneWidget);
    });

    testWidgets('setTravelerCounts with adults=1 kids=0 babies=0 renders', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final bloc = blocOf(tester);
      bloc.add(
        const PlanTripEvent.setTravelerCounts(
          adults: 1,
          children: 0,
          babies: 0,
        ),
      );
      await tester.pump();

      expect(bloc.state.nbTravelers, 1);
      expect(find.byType(PlanTripFlowPage), findsOneWidget);
    });
  });
}
