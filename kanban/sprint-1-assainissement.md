# Sprint 1 — Assainissement Technique & Fondation

> **Objectif** : Corriger tous les bugs identifies par l'audit technique, poser les bases du design system, et preparer l'infrastructure pour le refactor.
> **Dependances** : Aucune (premier sprint)
> **Branch** : `feat/SMP-300-assainissement-fondation`

**Pourquoi ce sprint existe** : L'audit a revele des bugs P0 (deserialisation JSON, memory leaks, crashes potentiels) et des incohérences P1-P2 dans le codebase actuel. Construire de nouvelles features sur des fondations instables, c'est de la dette composee. On nettoie d'abord.

---

## 1.1 — Fixes P0 : Bugs actifs / crashes potentiels

### FIX-1 — Deserialisation JSON : `field_rename: snake_case`

Le `build.yaml` n'a pas `field_rename: snake_case`. Les models Freezed generent `json['userId']` au lieu de `json['user_id']`. Resultat : les champs arrivent `null` silencieusement quand l'API retourne du snake_case.

- [ ] **F1 — Ajouter `field_rename: snake_case` dans `build.yaml`**
  - Fichier : `bagtrip/build.yaml`
  - Ajouter sous `json_serializable.options` : `field_rename: snake_case`
  - Supprimer tous les `@JsonKey(name: 'snake_case')` devenus redondants dans les models
  - Garder les `@JsonKey(name:)` uniquement quand le nom API differe de la convention snake_case du champ Dart (cas rares)
  - Run `flutter pub run build_runner build --delete-conflicting-outputs`
  - **Test** : Tous les model tests existants passent. Ajouter un test de round-trip JSON pour `Trip`, `User`, `Activity`.

### FIX-2 — Models non-Freezed

- [ ] **F2 — Convertir `PaymentCard` en Freezed**
  - Fichier : `bagtrip/lib/models/payment_card.dart`
  - Ajouter `@freezed`, `factory`, `fromJson`, `part` directives
  - **Test** : `PaymentCard.fromJson()` round-trip, `==` equality

- [ ] **F3 — Convertir `RecentBooking` en Freezed**
  - Fichier : `bagtrip/lib/models/recent_booking.dart`
  - Meme traitement que F2
  - **Test** : `RecentBooking.fromJson()` round-trip, `==` equality

### FIX-3 — `FlightSegment` sans `fromJson`

- [ ] **F4 — Ajouter `fromJson` a `FlightSegment`**
  - Fichier : `bagtrip/lib/flight_search/models/flight_segment.dart`
  - Ajouter `part 'flight_segment.g.dart'` et `factory FlightSegment.fromJson(...)`
  - **Test** : `FlightSegment.fromJson()` fonctionne

### FIX-4 — Services qui `throw` au lieu de `Result<T>`

- [ ] **F5 — Wrapper `LocationService` dans `Result<T>`**
  - Fichier : `bagtrip/lib/service/location_service.dart`
  - Remplacer les 6 `throw Exception()` (lignes 76, 78, 144, 147, 186, 188) par `return Failure(AppError.xxx(...))`
  - Mettre a jour les appelants
  - **Test** : Unit test — success + failure paths

- [ ] **F6 — Wrapper `AgentService` dans `Result<T>`**
  - Fichier : `bagtrip/lib/service/agent_service.dart`
  - Remplacer `throw Exception()` et `throw UnimplementedError()` par `Failure()`
  - **Test** : Unit test — error mapping

### FIX-5 — `SubscriptionService` unsafe casts

- [ ] **F7 — Null-safe cast dans `SubscriptionService`**
  - Fichier : `bagtrip/lib/service/subscription_service.dart`
  - Lignes 18, 30 : `response.data['url'] as String` → `(response.data['url'] as String?) ?? ''` avec `Failure` si vide
  - **Test** : Unit test — null URL, missing key

---

## 1.2 — Fixes P1 : Memory leaks & ressources

### FIX-6 — FCM StreamSubscriptions

- [ ] **F8 — Cancel FCM listeners dans main.dart**
  - Fichier : `bagtrip/lib/main.dart`
  - Stocker les 2 `StreamSubscription` de `_setupFCMListeners()` dans des champs
  - Cancel dans `dispose()`
  - **Test** : Verify `dispose()` appelle `cancel()`

### FIX-7 — BLoCs sans `close()`

- [ ] **F9 — Ajouter `close()` override aux 15 BLoCs concernes**
  - Fichiers : `activity_bloc.dart`, `accommodation_bloc.dart`, `baggage_bloc.dart`, `transport_bloc.dart`, `budget_bloc.dart`, `booking_bloc.dart`, `trip_share_bloc.dart`, `feedback_bloc.dart`, `personalization_bloc.dart`, `navigation_bloc.dart`, `flight_search_bloc.dart`, `flight_search_result_bloc.dart`, `flight_result_details_bloc.dart`, `trip_creation_bloc.dart`, `create_trip_ai_bloc.dart`
  - Auditer chaque bloc pour les `StreamSubscription`, `Timer`, `Completer` non-cancel
  - Ajouter `close()` avec les `cancel()` / `dispose()` necessaires
  - **Test** : `blocTest` — verify `close()` ne throw pas

### FIX-8 — Anti-pattern `add(LoadXxx())` apres mutation

- [ ] **F10 — Optimiser le reload pattern dans les BLoCs**
  - Fichiers concernes : `ActivityBloc`, `BaggageBloc`, `BudgetBloc`, `NotificationBloc`, `AccommodationBloc`
  - Pattern actuel : `add(LoadActivities())` apres chaque create/update/delete = round-trip API complet
  - Nouveau pattern : apres mutation reussie, mettre a jour la liste locale dans le state (optimistic update) puis sync en background
  - **Test** : Unit test — state mis a jour immediatement sans re-fetch

---

## 1.3 — Fixes P2 : Incoherences architecturales

### FIX-9 — Legacy `EmptyState`

- [ ] **F11 — Remplacer `EmptyState` par `ElegantEmptyState`**
  - `bagtrip/lib/trips/view/trips_list_view.dart` (lignes 177, 201)
  - `bagtrip/lib/feedback/view/feedback_list_view.dart` (ligne 14)
  - **Test** : `flutter analyze` = 0

### FIX-10 — `Navigator.push()` bypass GoRouter

- [ ] **F12 — Remplacer `Navigator.push()` par GoRouter**
  - Fichier : `bagtrip/lib/trip_creation/view/step_destination_view.dart` (ligne 67)
  - Remplacer `Navigator.of(context).push(MaterialPageRoute(...))` par la route GoRouter correspondante
  - **Test** : Navigation fonctionne via GoRouter

### FIX-11 — Dead code dans `service_locator.dart`

- [ ] **F13 — Supprimer les 14 imports inutilises**
  - Fichier : `bagtrip/lib/config/service_locator.dart`
  - Supprimer les imports de : `AuthService`, `NotificationService`, `ProfileApiService`, `BookingService`, `ActivityService`, `BudgetService`, `TripService`, `TripShareService`, `AccommodationService`, `BaggageItemService`, `TravelerService`, `FeedbackService`, `SubscriptionService`, `AiService`, `TransportService`
  - **Test** : `flutter analyze` = 0

### FIX-12 — States non-sealed

- [ ] **F14 — Convertir `SettingsState` en sealed class**
  - Fichier : `bagtrip/lib/settings/bloc/settings_state.dart`
  - **Test** : Existant passe toujours

- [ ] **F15 — Convertir `NavigationState` en sealed class**
  - Fichier : `bagtrip/lib/navigation/bloc/navigation_state.dart`
  - **Test** : Existant passe toujours

### FIX-13 — Erreurs silencieuses dans les services

- [ ] **F16 — Corriger les `Success([])` / `Success(null)` silencieux**
  - `activity_service.dart` : si format invalide → `Failure(ServerError('Invalid response format'))`
  - `accommodation_service.dart` : idem
  - `baggage_item_service.dart` : idem
  - `notification_service.dart` : `registerDeviceToken()` doit retourner `Failure` si echec (pas `Success(null)`)
  - `auth_service.dart` : `getCurrentUser()` sur 401 → `Failure(AuthenticationError(...))` (pas `Success(null)`)
  - **Test** : Unit tests pour chaque service corrige

### FIX-14 — `CachedTripRepository` mauvais type d'erreur

- [ ] **F17 — Retourner un type d'erreur semantiquement correct**
  - Fichier : `bagtrip/lib/service/cached_trip_repository.dart`
  - Lignes 84, 172 : `NetworkError('No cached data')` → `UnknownError('No cached data available')` ou nouveau `CacheError`
  - **Test** : Unit test

### FIX-15 — `Platform.isIOS` direct dans `main.dart`

- [ ] **F18 — Remplacer `Platform.isIOS` par `AdaptivePlatform.isIOS`**
  - Fichier : `bagtrip/lib/main.dart` (lignes ~101, ~161, ~172)
  - CLAUDE.md interdit `Platform.isIOS` directement — toujours `AdaptivePlatform.isIOS`
  - **Test** : `grep -r "Platform.isIOS" bagtrip/lib/ --include="*.dart" | grep -v adaptive_platform` = 0

### FIX-16 — Couleurs hardcodees

- [ ] **F19 — Remplacer les 78 `Colors.*` dans les views**
  - Passer en revue tous les fichiers `*_view.dart`
  - Remplacer `Colors.blue.shade800` par `AppColors.xxx` ou `Theme.of(context).colorScheme.xxx`
  - Priorite : `budget_view.dart` (11), `activities_view.dart` (9), `trip_home_view.dart` (7), `personalization_view.dart` (7)
  - Creer des tokens semantiques dans `AppColors` si necessaire (`AppColors.categoryFlight`, `AppColors.categoryHotel`, etc.)
  - **Test** : `flutter analyze` = 0, dark mode OK

### FIX-17 — `debugPrint` non-gate en production

- [ ] **F20 — Gater tous les `debugPrint` derriere `kDebugMode`**
  - Fichiers : `ai_service.dart` (3), `auth_service.dart` (2), `notification_service.dart` (3), `crashlytics_service.dart` (1)
  - Wrapper avec `if (kDebugMode) debugPrint(...)`
  - **Test** : Grep pour `debugPrint` sans `kDebugMode` guard = 0

---

## 1.4 — Fondation : Design System & Infrastructure

### DS-0 — Audit et harmonisation des spacing tokens

- [ ] **DS0 — Scanner et corriger les spacings hardcodes**
  - Scanner tous les fichiers pour des valeurs hardcodees : `grep -rn "EdgeInsets\.\(all\|symmetric\|only\)(" bagtrip/lib/`
  - Remplacer les valeurs brutes (`padding: 24`, `height: 300`) par les tokens `AppSpacing.*`
  - Ajouter les tokens manquants si necessaire (ex: `AppSpacing.space12` si absent)
  - **Test** : Inventaire avant/apres des valeurs hardcodees

### DS-1 — Spring animations library

- [ ] **DS1 — Creer `AppAnimations`**
  - Fichier : `bagtrip/lib/design/app_animations.dart`
  - Constantes : `springCurve` (Curves.easeOutBack), `staggerDelay` (80ms), `cardTransitionDuration` (350ms), `microInteractionDuration` (200ms), `wizardTransitionDuration` (300ms)
  - **Test** : Smoke test — constantes accessibles

### DS-2 — Haptic feedback utilities

- [ ] **DS2 — Creer `AppHaptics`**
  - Fichier : `bagtrip/lib/design/app_haptics.dart`
  - Methodes : `light()`, `medium()`, `success()`, `error()`
  - Guard avec `AdaptivePlatform.isIOS` pour les haptics iOS-only
  - **Test** : Unit test — appels par plateforme

### DS-3 — Nouveaux composants du wizard

- [ ] **DS3 — Creer les composants reutilisables**
  - `StepHeader` : header compact montrant le resume des steps precedents
  - `BudgetChipSelector` : 4 chips en 2x2 grid, selection unique
  - `FlexibleDatePicker` : 3 modes (exact, month, flexible) avec segment control
  - `AiSuggestionCard` : card destination avec image, match reason, badges
  - `DestinationCarousel` : `PageView.builder` de `AiSuggestionCard`
  - `StreamingChecklist` : checklist animee pour la generation SSE
  - **Test** : Widget test pour chaque composant

---

## 1.5 — Fondation : Navigation & HomeBloc

### NAV-1 — Restructuration des routes

- [ ] **N1 — Preparer les nouvelles routes**
  - Fichier : `bagtrip/lib/navigation/route_definitions.dart`
  - Ajouter `PlanTripRoute` (remplacera `TripCreationRoute` et AI routes)
  - Ajouter `TripDetailRoute(tripId)` (remplacera `TripHomeRoute`)
  - Garder les anciennes routes fonctionnelles pour l'instant (suppression au Sprint 6)
  - **Test** : Navigation existante non cassee

- [ ] **N2 — Route transition animations**
  - Fichier : `bagtrip/lib/navigation/page_transitions.dart`
  - `buildHeroTransitionPage` : shared element trip card → detail
  - `buildWizardTransitionPage` : slide left/right entre steps
  - **Test** : Smoke test visuel

### NAV-2 — Deep link pour partage de trip

- [ ] **N3 — Deep link `/trip/:tripId`**
  - Ajouter la route `/trip/:tripId` comme deep link
  - Gerer le cas "pas authentifie" → redirect login puis retour vers le trip
  - Configurer Universal Link (iOS) / App Link (Android)
  - **Test** : Integration test — deep link route vers la bonne page ou login si non auth

### BLOC-1 — HomeBloc parallelisation

- [ ] **B1 — Paralleliser les appels HomeBloc**
  - Fichier : `bagtrip/lib/home/bloc/home_bloc.dart`
  - Remplacer les appels sequentiels par `Future.wait([user, ongoing, planned, completed])`
  - **Test** : Unit test — temps de chargement reduit, toutes les donnees presentes

- [ ] **B2 — Ajouter `HomeError` state**
  - Ajouter un state `HomeError(message, retryCallback)` pour les erreurs reseau
  - **Test** : Unit test — network failure → `HomeError`, retry → `HomeLoaded`

---

## 1.6 — Fondation : API Hardening

> Les changements API necessaires au refactor sont integres ici (pas dans un sprint API isole).

### API-1 — Validation stricte a la creation

- [ ] **A1 — Validation `TripCreateRequest`**
  - Fichier API : `api/src/api/trips/schemas.py`
  - Require `destination_name` OR `destination_iata`
  - Validator : `start_date <= end_date`, `start_date` dans le futur (sauf update)
  - **Test** : `test_trip_validation.py` — 8 scenarios (valid, no dest, inverted, past, etc.)

### API-2 — Harmonisation des enums

- [ ] **A2 — Unifier `ActivityCategory`**
  - 8 valeurs : CULTURE, NATURE, FOOD, SPORT, SHOPPING, NIGHTLIFE, RELAXATION, OTHER
  - Mapping ancien → nouveau : VISIT→CULTURE, RESTAURANT→FOOD, LEISURE→RELAXATION
  - Migration Alembic
  - **Test** : `test_enum_migration.py`

- [ ] **A3 — Harmoniser `BaggageCategory`**
  - Aligner avec l'enum officiel
  - Fixer les hardcodes dans `plan_trip_routes.py`
  - **Test** : Default categories valides

### API-3 — Auto-ajout du createur comme TripTraveler

- [ ] **A4 — Ajouter le createur automatiquement**
  - Fichier : `api/src/services/trips_service.py`
  - A la creation, ajouter le owner comme premier `TripTraveler`
  - **Test** : `trip.travelers[0].user_id == owner.user_id`

### API-4 — Harmoniser `nb_travelers` default

- [ ] **A5 — Default `nb_travelers` = 1 partout**
  - Frontend : default stepper a 1
  - Backend : default schema a 1
  - **Test** : Verification coherence front/back

---

## 1.7 — Database Migrations

- [ ] **M1 — Migration : nouveaux enums `ActivityCategory`** (8 valeurs + mapping)
- [ ] **M2 — Migration : `NotificationType.TRIP_STARTED`** (nouvel enum)
- [ ] **M3 — Migration : champ `date_mode` sur Trip** (exact/month/flexible, default exact)

---

## Tests Sprint 1

### Tests unitaires

| Test | Module | Scenarios |
| --- | --- | --- |
| `trip_json_roundtrip_test.dart` | Trip model | fromJson → toJson → fromJson identity |
| `user_json_roundtrip_test.dart` | User model | idem |
| `activity_json_roundtrip_test.dart` | Activity model | idem |
| `payment_card_test.dart` | PaymentCard (Freezed) | fromJson, equality, copyWith |
| `recent_booking_test.dart` | RecentBooking (Freezed) | fromJson, equality, copyWith |
| `location_service_result_test.dart` | LocationService | Success path, failure path |
| `agent_service_result_test.dart` | AgentService | Error mapping |
| `subscription_service_test.dart` | SubscriptionService | Null URL, missing key |
| `home_bloc_parallel_test.dart` | HomeBloc | Parallel calls, HomeError, retry |
| `app_haptics_test.dart` | AppHaptics | Correct calls per platform |
| `season_mapping_test.dart` | Season helper | Month → season in English |

### Tests navigation

| Test | Module | Scenarios |
| --- | --- | --- |
| `navigation_routes_test.dart` | Route definitions | Toutes les routes accessibles, pas de crash |
| `deep_link_test.dart` | Deep link `/trip/:id` | Redirige vers bon trip ou login si non auth |

### Tests widgets (composants)

| Test | Widget | Scenarios |
| --- | --- | --- |
| `step_header_test.dart` | StepHeader | Resume des etapes, expandable |
| `budget_chip_selector_test.dart` | BudgetChipSelector | Selection unique, callback, visuel |
| `flexible_date_picker_test.dart` | FlexibleDatePicker | 3 modes, dates valides |
| `ai_suggestion_card_test.dart` | AiSuggestionCard | Accept/reject callbacks |

### Tests API

| Test | Module | Scenarios |
| --- | --- | --- |
| `test_trip_validation.py` | TripCreateRequest | 8 scenarios validation |
| `test_enum_migration.py` | ActivityCategory | Migration + mapping |
| `test_auto_traveler.py` | Trip creation | Creator auto-added |

---

## Criteres d'acceptation Sprint 1

- [ ] `flutter analyze` = 0 issues
- [ ] Tous les tests existants passent toujours
- [ ] Tous les nouveaux tests passent
- [ ] `build_runner build` genere correctement avec `field_rename: snake_case`
- [ ] Zero `EmptyState` dans le code (seulement `ElegantEmptyState`)
- [ ] Zero `Navigator.push()` hors GoRouter
- [ ] Zero `Colors.*` hardcode dans les `*_view.dart`
- [ ] Zero `debugPrint` non-gate par `kDebugMode`
- [ ] Zero imports dead dans `service_locator.dart`
- [ ] Tous les BLoCs ont un `close()` override
- [ ] FCM subscriptions annulees dans `dispose()`
- [ ] HomeBloc charge en < 2s (vs ~5s avant)
- [ ] API rejette les creations invalides (pas de dest, dates inversees, dates passees)
- [ ] Zero `Platform.isIOS` dans le code (sauf `adaptive_platform.dart`)
- [ ] Deep link `/trip/:tripId` fonctionne (auth redirect inclus)
- [ ] Spacing tokens audites, hardcodes corriges
- [ ] Dark mode fonctionne toujours
- [ ] Le build iOS/Android compile sans erreur
