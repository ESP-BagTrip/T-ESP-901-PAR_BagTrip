# Strategies de test

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip s'appuie sur quatre niveaux de tests pour le client Flutter : tests unitaires (BLoCs, models, helpers), tests de repository, tests de widgets, et tests E2E. Au total, environ 255 fichiers dans `bagtrip/test/` et 10 fichiers dans `bagtrip/integration_test/` (6 flows FT1-FT6 + 4 helpers partages). Stack outils : `flutter_test` pour le runner, `bloc_test` pour les BLoCs, `mocktail` pour les mocks, `integration_test` pour les flows E2E sur device/emulateur.

Le principe directeur est de centraliser les mocks et fixtures dans `test/helpers/` (et leur pendant `integration_test/helpers/`), pour eviter la duplication et garantir que tous les tests partent du meme modele de donnees. Les BLoCs acceptent un repository optionnel avec fallback `?? getIt<Repo>()`, ce qui rend l'injection de mocks triviale sans toucher au service locator de production.

Cible coverage : 100 % sur le code touche par chaque commit, seuil CI plancher 60 % sur les lignes non generees. Le script `bagtrip/test_coverage.sh` filtre le LCOV brut pour exclure le code generated/bootstrap avant verification du seuil.

## Structure test/

| Dossier | Contenu |
|---|---|
| `accessibility/` | Suites AX1-AX4 : semantic labels, touch targets, dynamic type, contrast |
| `accommodations/` | Widgets et helpers du domaine hebergement |
| `baggage/` | Cubits et widgets de la checklist bagages |
| `blocs/` | 18 BLoCs : auth, booking, navigation, notification, settings, trip_management, user_profile, plan_trip, feedback, subscription, accommodation, baggage, flight_search, flight_search_result, home, home_parallel, personalization, trip_share |
| `budget/` | Quick expense cubit, budget summary, kanban widgets |
| `core/` | `CacheService`, `ConnectivityService`, `ConnectivityBloc`, `OfflineWriteQueue`, app lifecycle |
| `design/` | Tokens, animations, haptics, widgets du design system (chips, cards, sheets) |
| `feedback/` | Page et bloc feedback post-trip |
| `flight_search/` | Search form, filtres, integration bloc |
| `flight_search_result/` | Liste de resultats Amadeus, bloc de pagination |
| `goldens/` | Snapshots visuels (golden tests) |
| `helpers/` | `mock_repositories.dart` + `test_fixtures.dart` partages |
| `home/` | Cubits, helpers, vues, widgets du dashboard home (idle, active trip, errors) |
| `integration/` | Tests d'integration legers : auth flow, trip creation, in-trip, post-trip |
| `l10n/` | Verification de la parite EN/FR sur les cles ARB critiques |
| `models/` | 28 fichiers : serialisation `fromJson` + roundtrips `fromJson(toJson(x)) == x` |
| `navigation/` | Deep links, route guards, redirects |
| `notifications/` | Bloc, count cubit, card widget |
| `personalization/` | Onboarding personalisation, bloc preferences |
| `plan_trip/` | Vues, widgets et helpers du wizard 6 etapes |
| `post_trip/` | Page post-trip et suggestions IA |
| `profile/` | Bloc user profile, edit profile, settings |
| `repositories/` | Auth, trip, weather (couche repository contre `ApiClient` mocke) |
| `service/` | `CachedTripRepository`, `LocationService`, `AgentService`, `SubscriptionService`, etc. |
| `services/` | Crashlytics, performance interceptor |
| `transports/` | Formulaire de vol manuel |
| `trip_detail/` | Vues, widgets, helpers du hub trip detail (TripDetailBloc + handlers) |
| `trips/` | `TripCard`, listings, filtres |
| `utils/` | Extensions DateTime, price formatting, error display |
| `widgets/` | Composants communs : snackbar, tab bar, error view, loading, paginated list, dialogs adaptatifs |

## Mocks et fixtures

### Mocks centralises

`bagtrip/test/helpers/mock_repositories.dart` declare un mock `mocktail` par repository et par service cross-cutting :

```dart
class MockAuthRepository extends Mock implements AuthRepository {}
class MockTripRepository extends Mock implements TripRepository {}
class MockActivityRepository extends Mock implements ActivityRepository {}
class MockAccommodationRepository extends Mock implements AccommodationRepository {}
class MockBudgetRepository extends Mock implements BudgetRepository {}
class MockBaggageRepository extends Mock implements BaggageRepository {}
class MockTravelerRepository extends Mock implements TravelerRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockNotificationRepository extends Mock implements NotificationRepository {}
class MockBookingRepository extends Mock implements BookingRepository {}
class MockTripShareRepository extends Mock implements TripShareRepository {}
class MockFeedbackRepository extends Mock implements FeedbackRepository {}
class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}
class MockAiRepository extends Mock implements AiRepository {}
class MockTransportRepository extends Mock implements TransportRepository {}
class MockWeatherRepository extends Mock implements WeatherRepository {}
class MockCrashlyticsService extends Mock implements CrashlyticsService {}
class MockCacheService extends Mock implements CacheService {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockPostTripDismissalStorage extends Mock implements PostTripDismissalStorage {}
class MockLocationService extends Mock implements LocationService {}
class MockGeoLocationService extends Mock implements GeoLocationService {}
```

Regle : tout nouveau mock partage va dans ce fichier. Les mocks locaux (`class _MockX extends Mock implements X {}`) ne sont tolere qu'au sein d'un test isole de service ou la cohabitation creerait un cycle.

### Fixtures partagees

`bagtrip/test/helpers/test_fixtures.dart` expose une factory par modele avec des defauts realistes :

| Factory | Modele |
|---|---|
| `makeUser({...})` | `User` (FREE par defaut) |
| `makeAuthResponse({...})` | `AuthResponse` complet |
| `makeTrip({...})` | `Trip` (Paris, 2 voyageurs, draft) |
| `makeTripGrouped({...})` | `TripGrouped` (ongoing/planned/completed) |
| `makeTripHome({...})` | `TripHome` + stats + features tiles |
| `makeActivity({...})` | `Activity` Eiffel 09:00 |
| `makeBudgetItem` / `makeBudgetSummary` | Budget item + summary alert level |
| `makeAccommodation({...})` | Hotel Paris |
| `makeBaggageItem` / `makeSuggestedBaggageItem` | Items checklist |
| `makeTraveler` / `makeTravelerProfile` | Profils voyageur |
| `makeAppNotification` | Notification typee |
| `makeTripFeedback` | Feedback post-trip |
| `makeTripShare` | Partage VIEWER/EDITOR |
| `makeBookingResponse` / `makePaymentAuthorizeResponse` | Stripe + Amadeus |
| `makeManualFlight` / `makeFlightInfo` | Vol manuel + lookup AirLabs |
| `makeBudgetEstimation` | Estimation IA |
| `makePaginatedResponse<T>` | Wrapper paginated generique |
| `makeCompletionResult` | Snapshot completion 4 segments |

Tous les parametres sont nommes et optionnels : `makeTrip(status: TripStatus.ongoing)` suffit. La regle est de **ne jamais reconstruire un modele a la main** dans un test : si la factory ne couvre pas un cas, etendre la factory.

### Fixtures JSON

Les modeles `@freezed` generent un `*.g.dart` qui dicte la convention attendue par `fromJson`. Avant de construire une fixture JSON, regarder le `.g.dart` pour savoir si l'endpoint attend snake_case ou camelCase (ca varie : `Accommodation` reste camelCase cote API alors que la majorite est snake_case). Sans cette verification, un `Failure(SerializationError)` mystifiant peut couter une heure de debug.

## Widget tests

### Wrapping standard

Les widget tests utilisent `MaterialApp` + delegates l10n + theme :

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

Pour un widget qui consomme un BLoC, wrapper avec `BlocProvider.value(value: mockBloc, child: ...)` ou injecter le repository mocke via le constructeur du BLoC.

### `pump()` explicite vs `pumpAndSettle()`

**Regle** : `pumpAndSettle()` est interdit des qu'une animation infinie est en jeu (shimmer, Lottie, indicators iOS). L'app contient plusieurs de ces animations en permanence (shimmer sur le home loading, Lottie sur l'empty state, halo anime sur `ElegantEmptyState`). `pumpAndSettle` boucle jusqu'au timeout et fait echouer le test.

Convention :

```dart
// Charger le widget initial
await tester.pumpWidget(app);

// Avancer de N frames (anime ce qui doit l'etre, laisse les loops infinies)
await tester.pump();                                 // 1 frame
await tester.pump(const Duration(milliseconds: 100)); // animation step
await tester.pump(const Duration(milliseconds: 500)); // attendre un async
```

Pour les flows asynchrones (auth → home), pumper en boucle :

```dart
for (int i = 0; i < 10; i++) {
  await tester.pump(const Duration(milliseconds: 100));
}
```

C'est exactement ce que `pumpTestApp` fait par defaut (10 frames de 100 ms apres le pump initial).

### Patterns specifiques

- **`ignore_for_file: avoid_redundant_argument_values`** en tete d'un test qui enumere explicitement des valeurs par defaut pour la lisibilite (sinon le lint hurle).
- Tester un bottom sheet : ouvrir via le trigger UI, puis verifier les widgets visibles. Ne pas tester `showModalBottomSheet` en isolation, le `BuildContext` requis n'est pas trivial a synthetiser.
- Tester un dialog adaptatif : utiliser `AdaptivePlatform.isIOS = ...` (overridable depuis les tests) pour forcer la branche Material ou Cupertino.

## E2E integration_test/

Les flows E2E couvrent les parcours utilisateur bout-en-bout en mockant uniquement les repositories (DI mock via `setupTestServiceLocator`). L'UI complete (router, BLoCs, navigation) est exercee.

| Fichier | Flow utilisateur | Scenarios principaux |
|---|---|---|
| `ft1_new_user_ai_trip_test.dart` | Onboarding -> creation IA | Empty home, AI inspiration, SSE stream, accept proposal, full flow |
| `ft2_manual_creation_test.dart` | Creation manuelle | Wizard 6 etapes, validation, persistance trip |
| `ft3_active_trip_test.dart` | Trip actif (companion) | ActiveTripHome, activites du jour, weather card |
| `ft4_sharing_readonly_test.dart` | Partage + viewer | Invite viewer, lecture seule, redaction edit actions |
| `ft5_end_of_trip_test.dart` | Fin de voyage | Transition ongoing -> completed, post-trip page, dismissal storage |
| `ft6_budget_flows_test.dart` | Kanban budget (SMP-322) | Suggested -> Validated -> Spent, quick expense, summary refresh |

### Infrastructure E2E

**`MockContainer`** (`mock_di_setup.dart`) : aggregation typee de 26 mocks (16 repositories + 10 services). Methode `setupTestServiceLocator()` reset `getIt`, instancie tous les mocks, les enregistre dans GetIt en respectant l'ordre de dependance (leaf services -> ApiClient -> repositories -> composite services) puis pose les **stubs universels** :

- `connectivity.isOnline = true` + stream vide
- `crashlytics.setUserId/clearUserId/recordAppError` no-op
- `dismissalStorage.wasDismissedRecently = false`
- `trip.getTripById` et `activity.getActivities` retournent des valeurs neutres pour eviter les `MissingStubError` quand le test navigue vers post-trip

**`e2e_fixtures.dart`** : factories simplifiees (`makeUser`, `makeTrip`, `makeActivity`, `makeAccommodation`, `makeBaggageItem`, `makeManualFlight`, `makeTripShare`, `makeTripFeedback`) + **composites pre-cables** (`makeBarcelonaTrip`, `makeLisbonTrip`, `makeActiveTripToday`, `makeEndedTrip`) + helpers de stub :

- `stubAuthenticated(mocks)` : auth OK + token en storage
- `stubEmptyHome(mocks)` : aucune liste de trips
- `stubActiveTripHome(mocks, trip, activities, weather)` : ongoing trip + activites + meteo
- `stubTripManagerHome(mocks, planned, completed)` : listings planned/completed

Le helper interne `_stubTripsPaginated` enregistre le **catch-all en premier** (mocktail : last registered wins, donc les specifiques overrident le wildcard), puis chaque combinaison `status x limit` utilisee par `HomeBloc` (limit 5) et `TripManagementBloc` (limit defaut 20). Cette double couche evite les `MissingStubError` sur des appels paginated qui ne matchent pas exactement.

**`finders.dart`** : finders typed reutilisables.

```dart
final homeLoading = find.byKey(const ValueKey('home-loading'));
final homeIdle = find.byKey(const ValueKey('home-idle'));
final homeActiveTrip = find.byKey(const ValueKey('home-active-trip'));
final idleHomeView = find.byType(IdleHomeView);
final activeTripHomeView = find.byType(ActiveTripHomeView);
final planTripFlowPage = find.byType(PlanTripFlowPage);
final tripDetailPage = find.byType(TripDetailView);
final postTripPage = find.byType(PostTripPage);
```

Convention : tout widget cible par un E2E expose une `ValueKey('feature-state')` en racine. Les finders by-type sont reserves aux pages (un seul instance dans l'arbre).

**`pumpTestApp`** (`pump_app.dart`) : entree unique pour bootstrap un test E2E.

```dart
Future<MockContainer> pumpTestApp(
  WidgetTester tester, {
  String initialRoute = '/home',
  MockContainer? existingMocks,
}) async {
  final mocks = existingMocks ?? await setupTestServiceLocator();
  stubAuthenticated(mocks);
  final router = createTestRouter(initialLocation: initialRoute);
  await tester.pumpWidget(TestApp(router: router));
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return mocks;
}
```

Le router de test (`createTestRouter`) by-passe `AppShell` et `LiquidGlass` (composants visuels lourds qui rallongent les tests sans valeur metier) et conserve les vraies routes typed (`$homeRoute`, `$activityRoute`, etc.) avec le meme `redirect` auth que la prod.

**Fallback values mocktail** : `registerE2eFallbackValues()` doit etre appele en `setUpAll` une fois par run. Il enregistre les valeurs de fallback pour `Trip`, `AppError`, `StackTrace`, et `Map<String, dynamic>` (sinon `any()` plante sur ces types non-primitifs).

## Coverage

### Cible et seuils

- **Cible** : 100 % sur le code touche par un commit. Toute feature/fix/refactor pousse des tests dans le meme commit.
- **Plancher CI mobile** : 60 % de couverture de lignes apres filtrage, enforced par `test_coverage.sh` via `lcov --summary`. Le seuil monte au fur et a mesure que la dette baisse.
- **Plancher CI backend** : 70 % sur `tests/services/` et `tests/api/` (gates separes, cf. `documentations/technical/backend/`).

### Filtrage LCOV

`bagtrip/test_coverage.sh` filtre le LCOV brut avant de calculer le pourcentage. Patterns exclus :

| Pattern | Justification |
|---|---|
| `*.g.dart`, `*.freezed.dart` | Code generated (json_serializable, freezed) — aucun comportement a tester |
| `lib/l10n/app_localizations*.dart` | Genere depuis ARB |
| `lib/gen/*` | flutter_gen (colors, fonts, assets) |
| `lib/firebase_options.dart` | Genere par flutterfire |
| `lib/main.dart` | App bootstrap, exerce uniquement en E2E |
| `lib/config/service_locator.dart` | DI wiring, exerce en E2E |
| `lib/navigation/route_definitions.dart` + `.g.dart` | Routes typed generees |
| `lib/navigation/app_router.dart`, `app_shell.dart`, `page_transitions.dart` | Routing glue, exerce en E2E |
| `lib/pages/payment/*` | Stripe redirect pages, tests staging end-to-end |

Le LCOV filtre est ensuite ingere par SonarQube pour le suivi historique.

### Execution

```bash
make coverage                                    # script complet avec filtrage + threshold
make test-mobile                                 # tests unitaires/widget sans coverage
make test-e2e                                    # tous les flows E2E
make test-e2e-ft3_active_trip                    # un flow precis
cd bagtrip && flutter test                       # equivalent direct
cd bagtrip && flutter test test/blocs            # une suite
cd bagtrip && flutter test --coverage --reporter expanded
```

Le pre-commit hook lance `flutter analyze` + `flutter test` (sans coverage, pour la vitesse). La CI complete tourne `make coverage` avec seuil enforced.

## Ce qu'il manque

| Element | Description | Priorite |
|---|---|---|
| Tests `OfflineBanner` | Pas de widget test verifiant l'affichage / dismiss du bandeau quand `ConnectivityBloc` emet offline -> online. | P1 |
| Plan Trip E2E complet | Le wizard 6 etapes est teste par etape (vues isolees dans `test/plan_trip/`). FT2 couvre la creation manuelle mais pas le flow IA avec SSE simule de bout en bout. | P1 |
| Coverage par-package | Seuil global 60 % uniquement. Pas de gate par feature (ex : trip_detail doit rester a 80 %, blocs a 90 %). | P1 |
| Tests de regression l10n | `test/l10n/` valide quelques cles mais pas la parite exhaustive EN/FR ni la presence de toutes les placeholders ICU. | P2 |
| Mock MethodChannel | Les platform channels (camera, file_picker, share_plus, in_app_purchase, FCM) ne sont pas mockes. Les features natives sont testees uniquement en device manuel. | P2 |
| Tests performance | Pas de `flutter drive` benchmark, pas de mesure frame time / memoire / cold start. Regression possible sans signal. | P2 |
| Concurrence cache | `CacheService` (Hive) n'est pas teste pour deux reads/writes concurrents sur la meme box (race possible sur `OfflineWriteQueue`). | P2 |
| Deep link E2E | `test/navigation/deep_link_test.dart` existe en unitaire mais le deep link n'est pas exerce en E2E avec auth + cold start. | P3 |
| Golden tests etendus | `test/goldens/` couvre quelques composants. Pas de baseline visuel sur les pages cles (home, trip detail, plan trip wizard). | P3 |
