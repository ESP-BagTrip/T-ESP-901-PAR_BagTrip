# Architecture Mobile BagTrip (Flutter)

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip mobile est une app Flutter structuree autour de quatre invariants : **BLoC** pour la gestion d'etat, **Repository** pour l'acces donnees, **Result<T>** pour la propagation d'erreurs typees, et **GetIt** pour l'injection de dependances. La UI ne connait jamais Dio, le BLoC ne connait jamais une URL, et toute erreur reseau est convertie en sous-type `AppError` avant d'atteindre la vue.

Stack technique (`bagtrip/pubspec.yaml`) : `flutter_bloc ^9.1.1`, `go_router ^17.0.1`, `dio ^5.4.0`, `get_it ^8.0.2`, `freezed ^3.0.0` + `json_serializable ^6.8.0`, `hive ^2.2.3` (cache), `flutter_secure_storage ^10.0.0` (JWT), `flutter_client_sse ^2.0.0` (streaming agent IA), `firebase_*` (Crashlytics + FCM), `flutter_stripe ^12.4.0`.

Le code est organise par feature sous `lib/` (`home/`, `trip_detail/`, `plan_trip/`, `activities/`, `budget/`, `auth/`, etc.). Chaque feature contient son `view/`, `bloc/` et, quand pertinent, son `widgets/` ou `helpers/`. Les contrats traversants (Repositories, Result, AppError, ApiClient, DI) vivent dans `lib/repositories/`, `lib/core/`, `lib/service/`, `lib/config/`.

## Layering

Chaque feature suit le meme pipeline du haut vers le bas :

```
Page (BlocProvider + event initial)
  -> View (BlocBuilder, UI pure)
    -> BLoC / Cubit (events -> states)
      -> Repository (interface abstraite, lib/repositories/)
        -> *RepositoryImpl (lib/service/, nommage historique)
          -> ApiClient (Dio wrapper, JWT, mapping erreurs)
```

### Page

Une Page (`lib/<feature>/view/<feature>_page.dart`) cree le `BlocProvider`, fire l'event initial et rend la View. Pas de UI metier inline. Exemple type :

```dart
class ActivitiesPage extends StatelessWidget {
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ActivitiesBloc()..add(LoadActivities(tripId: tripId)),
    child: ActivitiesView(tripId: tripId),
  );
}
```

### View

La View consomme le BLoC via `BlocBuilder`, `BlocSelector` ou `context.read<>()`. UI pure : pas d'acces a un repository, pas d'appel a `getIt<>()` (sauf cas justifies par `splash`, `app_router` redirect, ou services cross-cutting type `CrashlyticsService`).

### BLoC / Cubit

Un BLoC traduit les `Event` en `State`. Il ne sait rien de Dio ni de JSON : il appelle uniquement les methodes du Repository injecte. Les BLoCs acceptent un repository optionnel avec fallback `?? getIt<Repo>()` -- c'est le point d'injection pour les tests.

```dart
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TripRepository _tripRepository;
  HomeBloc({TripRepository? tripRepository})
    : _tripRepository = tripRepository ?? getIt<TripRepository>(),
      super(HomeInitial()) { ... }
}
```

### Repository

Toute interface vit dans `lib/repositories/<domain>_repository.dart`, l'implementation concrete dans `lib/service/<domain>_service.dart` (le nommage `service` est historique -- garder tel quel). Toutes les methodes retournent `Future<Result<T>>`. Jamais de `throw`. Les wrappers cache (`CachedTripRepository`, `CachedActivityRepository`, etc.) implementent la meme interface et decorent le remote.

17 repositories actifs : `AccommodationRepository`, `ActivityRepository`, `AiRepository`, `AuthRepository`, `BaggageRepository`, `BookingRepository`, `BudgetRepository`, `FeedbackRepository`, `NotificationRepository`, `ProfileRepository`, `SubscriptionRepository`, `TransportRepository`, `TravelerRepository`, `TripRepository`, `TripShareRepository`, `WeatherRepository`, plus l'extension `validation_extensions.dart` qui ajoute `validate()` aux repositories d'items (activity/transport/accommodation/budget).

### ApiClient

`lib/service/api_client.dart` -- wrapper Dio singleton enregistre dans GetIt. Tous les `*RepositoryImpl` recoivent un `required ApiClient apiClient`. Aucun fallback `?? ApiClient()` toleree : ce serait bypasser le singleton et donc le handler JWT.

## Result et AppError

### Result<T>

Sealed defini dans `lib/core/result.dart` :

```dart
sealed class Result<T> { const Result(); }
final class Success<T> extends Result<T> { final T data; ... }
final class Failure<T> extends Result<T> { final AppError error; ... }

extension ResultX<T> on Result<T> {
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };
}
```

Regles de consommation cote BLoC :

```dart
// Pattern matching obligatoire, jamais de cast.
switch (tripResult) {
  case Success(:final data): trip = data;
  case Failure(:final error):
    emit(TripDetailError(error: error));
    return;
}

// Rollback optimistic.
if (result case Failure(:final error)) {
  emit(loaded.copyWith(operationError: error));
}
```

### AppError

Hierarchie sealed dans `lib/core/app_error.dart`. Chaque sous-type porte `message`, `statusCode`, `code` (code backend type `ALREADY_PREMIUM`) et `originalError`.

| Classe | Scenario | HTTP |
|--------|----------|------|
| `NetworkError` | Timeout, connexion perdue | - |
| `AuthenticationError` | Token invalide / expire | 401 |
| `ForbiddenError` | Droits insuffisants | 403 |
| `NotFoundError` | Ressource absente | 404 |
| `ValidationError` | Donnees invalides | 400, 409 |
| `QuotaExceededError` | Limite premium atteinte | 402 |
| `StaleContextError` | Conflit `stale_context` | 409 |
| `RateLimitError` | Trop de requetes | 429 |
| `ServerError` | Erreur serveur | 500, 502 |
| `CancelledError` | Annulation utilisateur | - |
| `UnknownError` | Tout le reste | * |

### loggedFailure + UI display

Tout `Failure` cote repository passe par `loggedFailure<T>(error)` (`lib/core/logged_failure.dart`) qui enregistre l'erreur dans Crashlytics via `CrashlyticsService.recordAppError()` (sauf `CancelledError`). Cote vue, l'erreur est convertie via `toUserFriendlyMessage(error, l10n)` (`lib/utils/error_display.dart`) qui resout d'abord le `code` backend (mapping precis : `ALREADY_PREMIUM` -> `l10n.errorAlreadyPremium`, `REFUND_AMOUNT_EXCEEDS_REMAINING` -> `l10n.errorRefundExceedsRemaining`, etc.) puis tombe sur le sous-type generique. **Jamais** `error.message` brut : les strings backend sont en anglais et fuiteraient dans les UIs francaises.

## DI GetIt

Service locator : `lib/config/service_locator.dart`. L'ordre d'enregistrement reflete la chaine de dependances :

| Couche | Exemples | Depend de |
|--------|----------|-----------|
| 1. Leaf services | `StorageService`, `CacheService`, `ConnectivityService`, `CrashlyticsService`, `OnboardingStorage`, `SettingsStorage` | rien |
| 2. OfflineWriteQueue | `OfflineWriteQueue` | `CacheService` + `ConnectivityService` |
| 3. ApiClient | `ApiClient` | `StorageService` |
| 4. AuthRepository | `AuthRepositoryImpl` | `ApiClient` + `StorageService` |
| 5. Domain repos | `TripRepository`, `ActivityRepository`, ... | `ApiClient` (+ cache + connectivity pour les wrappers `Cached*`) |
| 6. Standalone | `LocationService`, `GeoLocationService` | Dio direct (pas ApiClient) |

Tout est en `registerLazySingleton`. Les BLoCs sont crees a la volee (jamais enregistres dans GetIt) avec fallback `?? getIt<Repo>()` sur leurs dependances.

**Regle stricte** : `getIt<>()` dans une page ou une vue est interdit quand un BLoC/Cubit parent existe. Pour charger de la data depuis une vue, creer un Cubit dedie. Exceptions tolerees : `app_router.dart` (redirect sans widget tree), `splash_page.dart` (bootstrap), appels internes a `CrashlyticsService` / `CacheService` depuis un BLoC.

## ApiClient et 401 refresh

`lib/service/api_client.dart` configure Dio avec :

- `connectTimeout` + `receiveTimeout` = 30 s.
- Headers JSON par defaut.
- `PerformanceInterceptor` (Firebase Performance).
- `LogInterceptor` en `kDebugMode` uniquement.
- `InterceptorsWrapper` JWT + refresh.

### JWT auto-injection

```dart
onRequest: (options, handler) async {
  final token = await _storageService.getToken();
  if (token != null) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  return handler.next(options);
}
```

`StorageService` stocke `access_token` + `refresh_token` dans `flutter_secure_storage` (Keychain iOS / EncryptedSharedPreferences Android).

### 401 refresh single-guard

Flag `_isRefreshing` -- garantit qu'une seule tentative de refresh tourne en parallele, meme si N requetes 401 arrivent en rafale :

```dart
onError: (error, handler) async {
  if (error.response?.statusCode == 401 && !_isRefreshing) {
    final refreshed = await _tryRefreshToken();
    if (refreshed) {
      // Retry original request with new token.
      opts.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.fetch(opts);
      return handler.resolve(response);
    } else {
      await _storageService.deleteToken();
      AuthEventBus.fireUnauthenticated();
    }
  }
  return handler.reject(_handleError(error));
}
```

`_tryRefreshToken()` utilise une **instance Dio separee** (`_refreshDioFactory`) pour eviter une boucle d'interceptor (si le refresh repond 401, on ne re-rentre pas dans le meme interceptor). Tests : `refreshDioFactory` est injectable pour brancher un `DioAdapter` (`http_mock_adapter`).

En cas d'echec de refresh, `AuthEventBus.fireUnauthenticated()` est emis ; `AuthListener` (`lib/auth/widgets/auth_listener.dart`) ecoute le stream et redirige vers `/login`.

### Mapping DioException -> AppError

`ApiClient.mapDioError(error)` est une methode statique reutilisee par tous les repositories. Elle parse l'enveloppe backend `{detail: "..."}` ou `{detail: {error, code}}`, puis switch sur `statusCode` :

```dart
return switch (statusCode) {
  400 => ValidationError(detailStr, statusCode: statusCode, code: detailCode, ...),
  401 => AuthenticationError(...),
  402 => QuotaExceededError(...),
  403 => ForbiddenError(...),
  404 => NotFoundError(...),
  409 when data is Map && data['error'] == 'stale_context' => StaleContextError(...),
  409 => ValidationError(...),
  429 => RateLimitError(...),
  500 | 502 => ServerError(...),
  _ => UnknownError(...),
};
```

Sans response (timeout, connection error) : `NetworkError('timeout')` ou `NetworkError('connection_error')`.

## Models Freezed

Tous les DTOs API sont `@freezed` avec `fromJson` genere via `json_serializable`. Les champs snake-case du backend sont mappes via `@JsonKey(name: 'snake_case')` :

```dart
@freezed
abstract class Activity with _$Activity {
  const factory Activity({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(unknownEnumValue: ActivityCategory.other)
    @Default(ActivityCategory.other) ActivityCategory category,
    @JsonKey(name: 'validation_status')
    @Default('MANUAL') String validationStatus,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
}
```

Regles :

- `@Default(...)` systematique sur les champs optionnels du backend -- jamais `required` sur un champ qui peut etre omis.
- `@JsonKey(unknownEnumValue: Foo.default)` obligatoire sur les enums JSON -- sans ca, ajout d'une valeur cote backend = crash runtime sur tous les clients deployes.
- `copyWith(field: null)` ne **clear pas** un champ nullable (Freezed interprete `null` = "leave unchanged"). Si on a besoin de clear explicitement, ajouter un flag `clearField: true` au copyWith custom (voir `TripDetailLoaded`).
- Mutation : toujours `obj.copyWith(...)`. Jamais de reconstruction manuelle qui enumere tous les champs -- casse silencieusement a chaque ajout de champ.

Regeneration apres edit : `cd bagtrip && flutter pub run build_runner build --delete-conflicting-outputs`.

## Cas particuliers

### HomeBloc app-level

`HomeBloc` vit dans le `MultiBlocProvider` de `main.dart` (l. 221-242) -- il persiste entre toutes les navigations pour eviter de re-fetcher la home a chaque retour sur l'onglet. Il est instancie manuellement dans `_MyAppState.initState()` (`_homeBloc = HomeBloc()`) puis injecte via `BlocProvider.value(value: _homeBloc)`.

Ce pattern est partage par : `SettingsBloc`, `UserProfileBloc`, `AuthBloc`, `BookingBloc`, `TripManagementBloc`, `NotificationBloc`, `NotificationCountCubit`, `ConnectivityBloc`, `SubscriptionBloc`. Tous les autres BLoCs (TripDetail, PlanTrip, Activities, Budget, FlightSearch...) sont **locaux** a leur page.

`HomePage` verifie `state is HomeInitial` avant de fire `LoadHome` pour eviter de re-charger inutilement quand on revient sur l'onglet. Un `AppLifecycleObserver` (`lib/core/app_lifecycle_observer.dart`) fire `RefreshHome` quand l'app revient au foreground.

Un `BlocListener<AuthBloc>` dans `main.dart` reset les BLoCs user-scoped (`ResetHome`, `ResetUserProfile`, `ResetTripManagement`, ...) a chaque login/logout pour eviter les fuites de donnees entre sessions.

### TripDetailBloc -- hub centralisateur eclate en part files

`TripDetailBloc` (`lib/trip_detail/bloc/trip_detail_bloc.dart`) est le hub central de la page detail d'un voyage. Son state `TripDetailLoaded` agrege **tout** ce qui appartient au trip : `trip`, `activities`, `flights`, `accommodations`, `baggageItems`, `budgetSummary`, `budgetItems`, `shares`, `userRole`, `completionResult`, plus des champs UI (`selectedDayIndex`, `collapsedSections`, `deferredLoaded`, `sectionErrors`).

**Ne pas scinder en sous-BLoCs.** Chaque mutation doit recomputer `completionResult` sur le snapshot complet via `tripDetailCompletion(...)` -- impossible si l'etat est fragmente. A la place, le bloc est eclate en **part files** par domaine :

```dart
part 'trip_detail_activity_handlers.dart';
part 'trip_detail_baggage_handlers.dart';
part 'trip_detail_budget_handlers.dart';
part 'trip_detail_event.dart';
part 'trip_detail_misc_handlers.dart';
part 'trip_detail_state.dart';
part 'trip_detail_transport_handlers.dart';
part 'trip_detail_trip_handlers.dart';
```

Chaque part file contient les handlers (`_onValidateActivity`, `_onCreateFlightFromDetail`, ...) sous forme d'extensions privees. Pour ajouter un event : entree dans la dispatch table (`on<...>(_onX)`) du main file + handler dans le part file du domaine concerne.

**Chargement deferred a 2 tiers** : `_fetchCore` charge trip + activities et emit immediatement, puis schedule un `LoadDeferredSections` (delay 100 ms) qui fetch en parallele flights + accommodations + baggage + budget + shares. Les echecs partiels sont stockes dans `sectionErrors` (par section) et permettent un retry granulaire via `RetryDeferredSection`. Un `RefreshTripDetail` recharge tout en parallele (7 calls) en preservant `selectedDayIndex` et `collapsedSections`.

### PlanTripBloc -- wizard 6 etapes + SSE streaming

`PlanTripBloc` (`lib/plan_trip/bloc/plan_trip_bloc.dart`) pilote le wizard de planification de voyage IA : dates -> voyageurs/budget -> destination -> propositions IA -> generation SSE -> review. Le step de generation (step 4) consomme `AiRepository.planTripStream(...)` qui retourne un `Stream<Map<String, dynamic>>` connecte au endpoint backend `/agent/plan-trip-stream`.

Le bloc maintient un `StreamSubscription<Map<String, dynamic>>? _sseSubscription` et applique systematiquement le pattern suivant avant tout nouveau stream (retry, back-to-proposals, close) :

```dart
Future<void> _cancelSseStream() async {
  await _sseSubscription?.cancel();
  _sseSubscription = null;
}

// Avant de demarrer un nouveau stream :
await _cancelSseStream();
_sseSubscription = _aiRepository.planTripStream(...).listen(
  (event) { ... },
  onError: (e) { ... },
  onDone: () { ... },
);
```

Le `close()` du bloc et tout retour utilisateur intermediaire (back, retry) appellent `unawaited(_cancelSseStream())` -- sans ca, l'orchestrateur LangGraph cote backend continuerait a consommer du quota LLM pour un client qui n'ecoute plus.

Le bloc est local a `PlanTripFlowPage`. Le state est `@freezed` (`plan_trip_state.dart` + `plan_trip_bloc.freezed.dart`) pour beneficier de `copyWith` automatique sur un state aussi large (entree wizard + propositions + jour-par-jour stream).

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| BlocObserver centralise | Aucun `BlocObserver` configure dans `main.dart` pour logger les transitions BLoC en debug -- utile pour reproduire les bugs cote QA | P2 |
| Retry automatique reseau | `ApiClient` ne re-tente pas les `NetworkError` ni les `RateLimitError`. Aujourd'hui chaque bloc choisit individuellement -- centraliser via un interceptor Dio | P2 |
| Cache pagine | Les listes paginees (trips, activities) ne sont pas mises en cache (delegation directe au remote dans les wrappers `Cached*`) -- perte de donnees en offline sur les listes longues | P1 |
| `ConnectivityService.dispose()` asymetrique | `dispose()` est `async` mais appele depuis `_MyAppState.dispose()` synchrone (`lib/main.dart` l. 175) -- la cancellation peut ne pas se completer en cas de teardown rapide | P3 |
| Tests d'integration repositories caches | `CachedTripRepository`, `CachedActivityRepository`, `CachedWeatherRepository`, `CachedBudgetRepository`, `CachedBaggageRepository` n'ont pas de tests d'integration verifiant le fallback offline bout-en-bout | P1 |
| `LocationService` multi-destination | Le service contient un TODO sur le multi-destination search (en attente du contrat backend) | P2 |
| Type-safety du `userRole` | `TripDetailLoaded.userRole` est `String` (`'OWNER'`, `'VIEWER'`, `'EDITOR'`) -- migrer vers une enum Freezed avec `unknownEnumValue` pour proteger contre l'ajout de nouveaux roles cote backend | P2 |
