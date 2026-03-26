# Strategies de test

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

BagTrip dispose d'une suite de tests a cinq niveaux : tests unitaires (BLoC, models, helpers), tests de repository, tests de widget, golden tests visuels, tests d'accessibilite, et tests d'integration E2E. Le projet totalise environ 149 fichiers de test unitaire/widget dans `bagtrip/test/` et 5 fichiers d'integration E2E dans `bagtrip/integration_test/`, representant ~27 000 lignes de code de test. Le framework principal est `flutter_test` avec `bloc_test` pour les BLoCs et `mocktail` pour les mocks.

## Organisation du repertoire de test

```
bagtrip/test/
├── accessibility/          # Tests a11y (semantic labels, touch targets, Dynamic Type, contraste)
├── accommodations/         # Tests widgets accommodation
├── blocs/                  # Tests BLoC (auth, booking, navigation, notification, settings, trip, user, plan_trip, feedback)
├── budget/                 # Tests budget
├── core/                   # Tests cache, connectivity, app_lifecycle
│   └── cache/              # CacheService, ConnectivityBloc, ConnectivityService
├── design/                 # Tests design system (animations, haptics, widgets)
│   └── widgets/            # AI suggestion card, budget chip, destination carousel, etc.
├── flight_search/          # Tests flight search
├── goldens/                # Golden tests visuels (5 fichiers)
├── helpers/                # Mocks partages (MockApiClient, MockStorageService, etc.)
├── home/                   # Tests home (cubits, helpers, widgets, views)
├── integration/            # Tests d'integration (auth flow, trip creation, in-trip, post-trip)
├── models/                 # Tests de serialisation/deserialisation (10+ modeles)
├── navigation/             # Deep link tests
├── plan_trip/              # Tests PlanTrip flow (views, widgets, helpers)
├── post_trip/              # Tests post-trip
├── repositories/           # Tests repository (auth, trip, weather)
├── service/                # Tests services (cached trip repo, location, agent, subscription)
├── services/               # Tests crashlytics, performance interceptor
├── transports/             # Tests formulaire de vol
├── trip_detail/            # Tests trip detail (views, widgets, helpers)
├── trips/                  # Tests trip widgets (TripCard)
└── widgets/                # Tests widgets communs (snackbar, tab bar, error view, loading, paginated list)

bagtrip/integration_test/
├── helpers/
│   ├── e2e_fixtures.dart   # Factories de modeles + helpers de stub
│   ├── finders.dart        # Finders reutilisables (ValueKey, Type)
│   ├── mock_di_setup.dart  # MockContainer + setupTestServiceLocator()
│   └── pump_app.dart       # TestApp + pumpTestApp()
├── ft1_new_user_ai_trip_test.dart
├── ft2_manual_creation_test.dart
├── ft3_active_trip_test.dart
├── ft4_sharing_readonly_test.dart
└── ft5_end_of_trip_test.dart
```

## Tests BLoC

**Repertoire** : `bagtrip/test/blocs/`

Utilisent `bloc_test` avec le pattern `blocTest<Bloc, State>` :

```dart
// test/blocs/settings_bloc_test.dart
blocTest<SettingsBloc, SettingsState>(
  'emits SettingsState with selectedTheme=dark',
  build: () => SettingsBloc(),
  act: (bloc) => bloc.add(ChangeTheme('dark')),
  expect: () => [
    isA<SettingsState>()
        .having((s) => s.selectedTheme, 'selectedTheme', 'dark'),
  ],
);
```

**BLoCs testes** : AuthBloc, BookingBloc, NavigationBloc, NotificationBloc, SettingsBloc, TripManagementBloc, UserProfileBloc, PlanTripBloc, FeedbackBloc, ConnectivityBloc, TodayTickCubit, QuickExpenseCubit, PostTripBloc.

**Pattern** : les BLoCs acceptent un repo optionnel avec fallback `?? getIt<Repo>()`, ce qui permet l'injection de mocks dans les tests sans toucher au service locator.

## Tests de modeles

**Repertoire** : `bagtrip/test/models/`

Couvrent la serialisation JSON et les roundtrips :

| Fichier | Modele |
|---------|--------|
| `activity_test.dart` + `activity_json_roundtrip_test.dart` | Activity |
| `trip_test.dart` + `trip_json_roundtrip_test.dart` | Trip |
| `user_test.dart` + `user_json_roundtrip_test.dart` | User |
| `budget_test.dart` | Budget |
| `flight_segment_test.dart` | FlightSegment |
| `auth_response_test.dart` | AuthResponse |
| `paginated_response_test.dart` | PaginatedResponse |
| `payment_card_test.dart` | PaymentCard |
| `recent_booking_test.dart` | RecentBooking |
| `plan_trip_models_test.dart` | PlanTrip models |

Les roundtrip tests verifient `fromJson(model.toJson()) == model`.

## Tests de repository

**Repertoire** : `bagtrip/test/repositories/`

Testent la couche repository avec des mocks de `ApiClient` :

- `auth_repository_test.dart` — login, register, token refresh
- `trip_repository_test.dart` — CRUD trips
- `weather_repository_test.dart` — fetch weather

Le `CachedTripRepository` a sa propre suite dans `test/service/cached_trip_repository_test.dart` (9 tests couvrant online/offline, cache hit/miss, invalidation).

## Tests de widget

**Repertoire** : `bagtrip/test/widgets/`, `bagtrip/test/home/`, `bagtrip/test/trip_detail/`, etc.

Utilisent `WidgetTester.pumpWidget()` avec des wrappers qui fournissent l10n, theme et BLoC :

```dart
await tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: AppTheme.light(),
    home: Scaffold(body: widgetUnderTest),
  ),
);
```

**Composants testes** : AppSnackbar, BottomTabBar, ErrorView, LoadingView, PaginatedList, TripCard, TripHeroHeader, TimelineActivityCard, FlightBoardingPassCard, BaggageChecklistCard, AccommodationBookingCard, NowIndicator, CurrentActivity, QuickExpense, TomorrowPreview, CompletedTripsCarousel, ShareInvite, ViewerReadonly.

## Golden tests

**Repertoire** : `bagtrip/test/goldens/`

Tests de regression visuelle avec `matchesGoldenFile()`. Tagged `@Tags(['golden'])` pour execution selective.

**Helpers** (`golden_helpers.dart`) :
```dart
const goldenSurfaceSize = Size(400, 800);

Widget goldenWrapper(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('en'),
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: child)),
  );
}

Future<void> setGoldenSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(goldenSurfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
```

**Golden tests existants** :

| Fichier | Composant | Variantes |
|---------|-----------|-----------|
| `elegant_empty_state_golden_test.dart` | ElegantEmptyState | default, with CTA, with secondary action |
| `adaptive_button_golden_test.dart` | AdaptiveButton | default, loading, disabled |
| `primary_button_golden_test.dart` | PrimaryButton | variantes visuelles |
| `status_badge_golden_test.dart` | StatusBadge | variantes de statut |
| `budget_chip_selector_golden_test.dart` | BudgetChipSelector | variantes |

**Execution** : `flutter test --tags golden` ou `flutter test --update-goldens` pour mettre a jour les fichiers de reference.

## Tests d'accessibilite

**Repertoire** : `bagtrip/test/accessibility/`

Suite dediee couvrant 4 axes (17 tests au total). Voir `documentations/technical/mobile/accessibility.md` pour le detail.

## Tests d'integration E2E

**Repertoire** : `bagtrip/integration_test/`

5 flows utilisateur complets avec mocks DI :

| Fichier | Flow | Scenarios |
|---------|------|-----------|
| `ft1_new_user_ai_trip_test.dart` | Nouveau user → AI trip | OnboardingHome, AI inspiration, SSE stream, accept, full flow |
| `ft2_manual_creation_test.dart` | Creation manuelle | PlanTrip flow |
| `ft3_active_trip_test.dart` | Trip actif | ActiveTripHome, activites du jour |
| `ft4_sharing_readonly_test.dart` | Partage & lecture seule | Invite, viewer readonly |
| `ft5_end_of_trip_test.dart` | Fin de voyage | Transition post-trip |

### Infrastructure E2E

**MockContainer** (`integration_test/helpers/mock_di_setup.dart`) :

Container centralise de 27 mocks (16 repositories + 11 services), enregistres dans GetIt. Fournit des stubs universels (connectivity online, crashlytics no-op, scheduler no-op).

```dart
class MockContainer {
  final MockAuthRepository auth;
  final MockTripRepository trip;
  final MockActivityRepository activity;
  // ... 24 autres mocks
}
```

**Fixtures** (`integration_test/helpers/e2e_fixtures.dart`) :

Factories de modeles (`makeUser()`, `makeTrip()`, `makeActivity()`, etc.) et helpers de stub (`stubAuthenticated()`, `stubEmptyHome()`, `stubActiveTripHome()`, `stubTripManagerHome()`).

**Finders** (`integration_test/helpers/finders.dart`) :

Finders reutilisables bases sur `ValueKey` et type :

```dart
final homeNewUser = find.byKey(const ValueKey('home-new-user'));
final onboardingHomeView = find.byType(OnboardingHomeView);
final tripDetailPage = find.byType(TripDetailPage);
```

**TestApp et pumpTestApp** (`integration_test/helpers/pump_app.dart`) :

```dart
Future<MockContainer> pumpTestApp(
  WidgetTester tester, {
  String initialRoute = '/home',
}) async {
  final mocks = await setupTestServiceLocator();
  stubAuthenticated(mocks);
  final router = createTestRouter(initialLocation: initialRoute);
  await tester.pumpWidget(TestApp(router: router));
  // Pump explicite (pas pumpAndSettle) pour gerer les animations infinies
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return mocks;
}
```

**Note** : les tests E2E n'utilisent pas `pumpAndSettle()` car les animations infinies (shimmer, Lottie) empechent le settle. Ils utilisent un pump explicite en boucle.

## Mocks unitaires

**Fichier** : `bagtrip/test/helpers/mock_services.dart`

Mocks partages pour les tests unitaires :

```dart
class MockApiClient extends Mock implements ApiClient {}
class MockStorageService extends Mock implements StorageService {}
class MockPersonalizationStorage extends Mock implements PersonalizationStorage {}
class MockLocationService extends Mock implements LocationService {}
```

## Execution des tests

```bash
# Tous les tests unitaires/widget
flutter test

# Tests avec tags
flutter test --tags golden

# Mise a jour des goldens
flutter test --update-goldens

# Tests d'integration E2E
flutter test integration_test/

# Coverage
flutter test --coverage
```

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Golden tests dark mode | Tous les golden tests utilisent `AppTheme.light()`. Aucune variante dark. (`bagtrip/test/goldens/golden_helpers.dart`) | P1 |
| Test de l'OfflineBanner | Pas de test widget verifiant l'affichage du bandeau offline avec `ConnectivityBloc`. | P1 |
| Tests du PlanTrip flow complet | Le flow PlanTrip est teste partiellement (vues et widgets individuels dans `test/plan_trip/`) mais pas le parcours multi-etapes complet en E2E. | P1 |
| Coverage report et seuil | Pas de seuil de coverage configure (`--min-coverage`) dans le CI. Pas de rapport de coverage visible. | P1 |
| Tests de performance | Pas de `flutter drive` ou benchmark pour mesurer les temps de rendu, la taille de frame, ou la consommation memoire. | P2 |
| Tests de regression l10n | Pas de test verifiant la parite des cles entre `app_en.arb` et `app_fr.arb`. | P2 |
| Mock de MethodChannel | Les tests E2E mockent les repositories via GetIt mais pas les platform channels (camera, file picker, etc.). Les features natives ne sont pas testees. | P2 |
| Tests de snapshot multi-resolution | Les golden tests utilisent une seule taille (`400x800`). Pas de test sur petits ecrans (iPhone SE) ni tablettes. | P2 |
| Test de navigation deep link en E2E | `test/navigation/deep_link_test.dart` existe mais le deep link n'est pas teste dans le context E2E complet avec auth. | P2 |
| Tests de concurrence cache | Le `CacheService` n'est pas teste pour les acces concurrents (deux reads/writes simultanees sur la meme box). | P2 |
