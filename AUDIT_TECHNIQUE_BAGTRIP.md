# AUDIT TECHNIQUE COMPLET — BagTrip Flutter App

**Auditeur** : Senior Engineer review
**Scope** : `bagtrip/lib/` — 378 fichiers, 22 BLoCs, 15 repositories, 30 models, 39 tests

---

## VERDICT GLOBAL

L'architecture est solide sur le papier (BLoC + Repository + Result + Freezed + GoRouter type-safe). Le squelette est bon. Mais l'execution est **incoherente** : les conventions sont documentees dans CLAUDE.md mais pas appliquees partout. C'est un projet qui a grandi vite sans passe de consolidation.

**Note : 6/10** — Bon pour un projet scolaire, insuffisant pour de la production.

---

## SEVERITY P0 — BUGS ACTIFS / CRASHES POTENTIELS

### 1. Deserialisation JSON incoherente — ~23 models concernes

Le `build.yaml` n'a PAS `field_rename: snake_case`. Les models Freezed sans `@JsonKey(name:)` cherchent `json['userId']` au lieu de `json['user_id']`.

**Le probleme** : l'API FastAPI utilise un mix — certains schemas Pydantic retournent du camelCase (via les field names), d'autres du snake_case (via les alias). Le model `Activity` Flutter attend `trip_id` (snake_case, via `@JsonKey`) alors que `Trip` attend `userId` (camelCase, sans `@JsonKey`).

**Models sans `@JsonKey` qui vont crasher si l'API change** :
- `trip.dart` — 11 champs (userId, startDate, endDate, coverImageUrl...)
- `user.dart` — 7 champs (fullName, stripeCustomerId, isProfileCompleted...)
- `manual_flight.dart` — 9 champs
- `traveler.dart` — 8 champs
- `budget_item.dart` + `BudgetSummary` — 12 champs
- `flight.dart` (flight_search_result) — 19 champs
- `traveler_profile.dart` — 6 champs
- `feedback.dart` — 5 champs
- `accommodation.dart` — 7 champs
- `baggage_item.dart` — 4 champs
- `notification.dart` — 3 champs
- `booking_response.dart` — 3 champs
- `payment_authorize_response.dart` — 2 champs
- `budget_estimation.dart` — 7 champs
- `flight_info.dart` — 15 champs
- `trip_summary.dart` — ~15 champs

**Fix haut ROI** : Ajouter `field_rename: snake_case` dans `build.yaml` et regenerer. Ca fixe tout d'un coup :
```yaml
json_serializable:
  options:
    explicit_to_json: true
    field_rename: snake_case  # ajouter cette ligne
```

### 2. `PaymentCard` et `RecentBooking` ne sont PAS Freezed

Ce sont des classes Dart manuelles sans immutabilite, sans `==`/`hashCode`, sans `fromJson`. Ils ne peuvent pas etre compares dans les BLoC states (un `emit` avec ces objets ne sera jamais detecte comme "meme etat").

- `lib/models/payment_card.dart`
- `lib/models/recent_booking.dart`

### 3. `FlightSegment` — Freezed mais pas de `fromJson`

```dart
// lib/flight_search/models/flight_segment.dart
@freezed
abstract class FlightSegment with _$FlightSegment {
  const factory FlightSegment({...}) = _FlightSegment;
  // MANQUE: factory FlightSegment.fromJson(...)
}
```

Impossible de deserialiser depuis l'API.

### 4. `LocationService` et `AgentService` — `throw Exception()` au lieu de `Result<T>`

Toute l'archi utilise `Result<T>`, sauf ces deux services qui `throw` directement. Les appelants qui ne wrappent pas dans un try/catch vont crasher.

- `lib/service/location_service.dart` — lignes 76, 78, 144, 147, 186, 188
- `lib/service/agent_service.dart` — lignes 16, 41, 44

### 5. `SubscriptionService` — Cast dangereux sans null-check

```dart
// lib/service/subscription_service.dart
response.data['url'] as String  // crash si 'url' absent ou null
```

Deux occurrences (lignes 18 et 30). Doit etre `(response.data['url'] as String?) ?? ''`.

---

## SEVERITY P1 — MEMORY LEAKS / RESSOURCES

### 6. FCM StreamSubscriptions jamais cancel dans main.dart

```dart
// main.dart — _MyAppState._setupFCMListeners()
FirebaseMessaging.onMessage.listen(...)       // jamais cancel
FirebaseMessaging.instance.onTokenRefresh.listen(...)  // jamais cancel
```

Ces deux `StreamSubscription` vivent pour toujours. Stocker dans des champs et cancel dans `dispose()`.

### 7. 15 BLoCs sans `close()` override

Aucun nettoyage de ressources pour :
ActivityBloc, AccommodationBloc, BaggageBloc, TransportBloc, BudgetBloc, BookingBloc, TripShareBloc, FeedbackBloc, PersonalizationBloc, NavigationBloc, FlightSearchBloc, FlightSearchResultBloc, FlightResultDetailsBloc, TripCreationBloc, CreateTripAiBloc.

Si un seul d'entre eux tient un StreamSubscription, timer ou listener → fuite memoire.

### 8. Anti-pattern `add(LoadXxx())` apres chaque mutation

Apres un create/update/delete, les blocs font `add(LoadActivities())` → round-trip API complet pour recharger la liste entiere. Ca se repete dans **5 blocs** (Activity, Baggage, Budget, Notification, Accommodation).

**Fix** : Optimistic update local + sync async, ou au minimum `emit` le nouvel etat directement sans re-fetch.

---

## SEVERITY P2 — INCOHERENCES ARCHITECTURALES

### 9. Legacy `EmptyState` encore utilise dans 2 fichiers

CLAUDE.md dit "Toujours `ElegantEmptyState`", mais :
- `lib/trips/view/trips_list_view.dart` — lignes 177, 201 : utilise `EmptyState()`
- `lib/feedback/view/feedback_list_view.dart` — ligne 14 : utilise `EmptyState()`

### 10. `Navigator.push()` qui bypass GoRouter

```dart
// lib/trip_creation/view/step_destination_view.dart:67
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const CreateTripAiFlowPage()),
);
```

Ca casse le type-safe routing, le deep linking, et l'historique GoRouter.

### 11. `SettingsState` et `NavigationState` — pas sealed

Tous les autres states sont sealed ou freezed. Ces deux sont des classes Dart basiques, ce qui casse l'exhaustivite du pattern matching.

### 12. 14 imports inutilises dans `service_locator.dart`

Legacy services importes mais jamais registered :
`AuthService`, `NotificationService`, `ProfileApiService`, `BookingService`, `ActivityService`, `BudgetService`, `TripService`, `TripShareService`, `AccommodationService`, `BaggageItemService`, `TravelerService`, `FeedbackService`, `SubscriptionService`, `AiService`, `TransportService`.

Dead code.

### 13. Erreurs silencieusement avalees

Plusieurs services retournent `Success([])` ou `Success(null)` quand le parsing echoue :

| Service | Comportement | Probleme |
|---------|-------------|----------|
| `activity_service.dart` | `Success([])` si format invalide | Cache la vraie erreur |
| `accommodation_service.dart` | `Success([])` si format invalide | Idem |
| `baggage_item_service.dart` | `Success([])` sur parse failure | Idem |
| `notification_service.dart` | `Success(null)` sur echec register token | L'app croit que c'est OK |
| `auth_service.dart` | `Success(null)` sur 401 getCurrentUser | Impossible de distinguer "pas auth" de "erreur reseau" |

### 14. `CachedTripRepository` — mauvais type d'erreur

Retourne `Failure(NetworkError('No cached data available'))` quand il n'y a pas de cache offline. C'est un `CacheError`, pas un `NetworkError`.

---

## SEVERITY P3 — COULEURS / UI HARDCODEES

### 15. 78 occurrences de `Colors.*` dans les fichiers `*_view.dart`

**Pires offenders** :
- `budget_view.dart` — **11 occurrences** (`Colors.blue.shade800`, `Colors.purple.shade100`, etc.)
- `activities_view.dart` — 9 occurrences
- `trip_home_view.dart` — 7 occurrences
- `personalization_view.dart` — 7 occurrences
- `step_review_view.dart` — 5 occurrences
- `step_dates_view.dart` — 4 occurrences
- `step_travelers_view.dart` — 3 occurrences

CLAUDE.md dit : "Jamais de hex brut" / "AppColors.* ou ColorName.*".

### 16. 11 `debugPrint()` en production

5 fichiers avec 11 appels `debugPrint`. Seul `api_client.dart` les gate derriere `kDebugMode`. Les autres (`ai_service.dart`, `auth_service.dart`, `notification_service.dart`) les laissent en prod. Pas critique mais pas propre.

---

## SEVERITY P4 — COUVERTURE DE TESTS

### La couverture est le plus gros probleme du projet.

| Categorie | Total | Testes | Coverage |
|-----------|-------|--------|----------|
| BLoCs | 22 | 11 | **50%** |
| Repositories | 15 | 3 | **20%** |
| Services | 26 | 7 | **27%** |
| Models | 22 | 7 | **32%** |
| Pages/Views | ~30 | 0 | **0%** |
| Integration flows | - | 2 | **~0%** |

**Chemins critiques SANS AUCUN test** :
1. `ApiClient` — JWT injection, 401 refresh, error mapping. C'est la FONDATION du reseau.
2. `FlightSearchBloc` — 25+ event handlers, le feature le plus complexe
3. `HomeBloc` — dashboard principal
4. `BookingService` — transactions Stripe
5. `SubscriptionService` — paiements
6. `CreateTripAiBloc` — SSE streaming AI
7. **Zero** widget test sur les pages reelles

Le seuil configure dans `test_coverage.sh` est de 60%. La couverture reelle est probablement autour de **35-40%**.

---

## TOP 10 — ACTIONS HAUT ROI (par ordre de priorite)

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| 1 | Ajouter `field_rename: snake_case` dans `build.yaml` + regen | 10 min | Fixe ~100+ champs de deserialisation |
| 2 | Convertir `PaymentCard` et `RecentBooking` en Freezed | 20 min | Elimine bugs d'egalite dans les BLoC states |
| 3 | Ajouter `fromJson` a `FlightSegment` | 2 min | Fix crash potentiel |
| 4 | Cancel les FCM StreamSubscriptions dans `main.dart` | 5 min | Fix memory leak permanent |
| 5 | Wrapper `LocationService`/`AgentService` dans `Result<T>` | 30 min | Elimine les throw non-catches |
| 6 | Remplacer les 2 `EmptyState()` restants par `ElegantEmptyState` | 5 min | Coherence avec le design system |
| 7 | Remplacer `Navigator.push()` par GoRouter dans `step_destination_view.dart` | 10 min | Fix le routing casse |
| 8 | Supprimer les 14 imports dead dans `service_locator.dart` | 2 min | Code propre |
| 9 | Tests pour `ApiClient` (JWT, refresh, error mapping) | 2h | Couvre la fondation reseau |
| 10 | Tests pour `FlightSearchBloc` + `HomeBloc` | 3h | Couvre les 2 features les plus critiques |

---

## CE QUI EST BIEN FAIT

- Architecture BLoC + Repository + Result — propre et coherent (quand c'est applique)
- `ApiClient` — singleton Dio, JWT auto-inject, refresh single-guard, error mapping
- Token storage via `flutter_secure_storage` (pas SharedPreferences)
- Design system documente (AppSpacing, AppRadius, AppColors, adaptive components)
- FAB platform handling correct (Android FAB / iOS AppBar icon) dans la majorite des views
- GoRouter type-safe avec `@TypedGoRoute` et code generation
- l10n FR+EN avec `AppLocalizations` bien utilise
- Firebase Crashlytics + Performance monitoring integres
- Bonne structure de test helpers (mock_repositories, test_fixtures)
- `flutter analyze` passe a 0 issues
- Les 11 BLoCs testes ont une bonne qualite de tests (success + failure paths)

---

**En resume** : le projet a une bonne architecture documentee, mais environ 40% du code ne suit pas ses propres conventions. Le JSON mismatch est le bug le plus urgent (P0). La couverture de tests est le probleme structurel le plus important (P4 en severity mais P1 en importance long-terme). Les 10 actions ci-dessus, realisables en ~1 jour de travail, amelioreraient significativement la qualite du projet.
