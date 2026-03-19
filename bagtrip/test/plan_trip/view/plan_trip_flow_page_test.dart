import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/design/widgets/premium_step_indicator.dart';
import 'package:bagtrip/plan_trip/view/plan_trip_flow_page.dart';
import 'package:bagtrip/plan_trip/view/step_dates_view.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:flutter/material.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocationService extends Mock implements LocationService {}

class _MockTripRepository extends Mock implements TripRepository {}

class _MockAiRepository extends Mock implements AiRepository {}

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

  Widget buildApp() {
    return const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: PlanTripFlowPage(),
    );
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
}
