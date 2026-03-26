# Architecture Mobile BagTrip (Flutter)

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

L'application BagTrip repose sur une architecture **BLoC + Repository + Result** avec injection de dependances via **GetIt**. Chaque feature suit un layering strict qui separe les responsabilites : la UI ne connait que le BLoC, le BLoC ne connait que le Repository (interface), et le Repository encapsule l'acces reseau (ApiClient / Dio) ou cache. Toutes les erreurs sont typees via un sealed class `AppError` et transitent dans un wrapper `Result<T>`.

## Layering par feature

Chaque feature respecte le schema suivant :

```
Page (BlocProvider + event initial)
  -> View (BlocBuilder, UI pure)
    -> BLoC (logique metier, events/states)
      -> Repository (interface abstraite)
        -> RepositoryImpl (ApiClient / Dio)
```

### Page

La Page cree le `BlocProvider` et fire l'event initial. Elle n'a aucune logique UI :

```dart
// lib/activities/view/activities_page.dart (pattern type)
class ActivitiesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActivitiesBloc()..add(LoadActivities(tripId: tripId)),
      child: ActivitiesView(tripId: tripId),
    );
  }
}
```

### View

La View utilise `BlocBuilder` ou `BlocSelector` pour reconstruire l'UI en fonction du state :

```dart
BlocBuilder<ActivitiesBloc, ActivitiesState>(
  builder: (context, state) {
    return switch (state) {
      ActivitiesLoading() => const LoadingView(),
      ActivitiesLoaded(:final activities) => _buildList(activities),
      ActivitiesError(:final message) => ErrorView(message: message),
      _ => const SizedBox.shrink(),
    };
  },
)
```

### Exception : BLoCs globaux dans MultiBlocProvider

Certains BLoCs persistent entre navigations et sont enregistres dans le `MultiBlocProvider` de `main.dart` (`lib/main.dart`, l.163-173) :

- `HomeBloc` (via `BlocProvider.value` -- cree dans `_MyAppState`)
- `SettingsBloc`
- `UserProfileBloc`
- `BookingBloc`
- `AuthBloc`
- `TripManagementBloc`
- `NotificationBloc`
- `ConnectivityBloc`

`HomeBloc` est cree manuellement dans `initState()` pour etre pilote par le `AppLifecycleObserver`. La Page `HomePage` verifie `state is HomeInitial` avant de fire `LoadHome` pour eviter les doublons.

## Injection de dependances -- GetIt

Le service locator est configure dans `lib/config/service_locator.dart`. L'enregistrement suit un ordre strict de dependances :

| Couche | Exemples | Dependances |
|--------|----------|-------------|
| 1. Leaf services | `StorageService`, `CacheService`, `ConnectivityService`, `CrashlyticsService` | Aucune |
| 2. ApiClient | `ApiClient` | `StorageService` |
| 3. AuthRepository | `AuthRepositoryImpl` | `ApiClient`, `StorageService` |
| 4. Domain repositories | `TripRepository`, `ActivityRepository`, `BudgetRepository`... | `ApiClient` |
| 5. Schedulers | `TripNotificationScheduler` | Repositories |
| 6. Standalone | `LocationService` | Dio direct (pas ApiClient) |

Les BLoCs acceptent un repo optionnel avec fallback vers GetIt, ce qui facilite les tests :

```dart
// lib/home/bloc/home_bloc.dart
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TripRepository _tripRepository;
  final AuthRepository _authRepository;

  HomeBloc({
    TripRepository? tripRepository,
    AuthRepository? authRepository,
  }) : _tripRepository = tripRepository ?? getIt<TripRepository>(),
       _authRepository = authRepository ?? getIt<AuthRepository>(),
       super(HomeInitial()) {
    on<LoadHome>(_onLoadHome);
    on<RefreshHome>(_onRefreshHome);
  }
}
```

## Error Handling -- Result<T> + AppError

### Result<T>

Sealed class defini dans `lib/core/result.dart` :

```dart
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}
```

Extension helper pour le pattern matching rapide :

```dart
extension ResultX<T> on Result<T> {
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };
}
```

### AppError

Hierarchie sealed dans `lib/core/app_error.dart` -- chaque sous-type mappe un scenario d'erreur precis :

| Classe | Scenario | Code HTTP |
|--------|----------|-----------|
| `NetworkError` | Timeout, connexion perdue | - |
| `AuthenticationError` | Token invalide / expire | 401 |
| `ForbiddenError` | Droits insuffisants | 403 |
| `NotFoundError` | Ressource absente | 404 |
| `ValidationError` | Donnees invalides | 400, 409 |
| `QuotaExceededError` | Limite premium atteinte | 402 |
| `StaleContextError` | Conflit de version (409 + `stale_context`) | 409 |
| `ServerError` | Erreur serveur | 500 |
| `RateLimitError` | Trop de requetes | 429 |
| `CancelledError` | Annulation utilisateur | - |
| `UnknownError` | Tout le reste | * |

### Mapping HTTP -> AppError

Effectue dans `ApiClient.mapDioError()` (`lib/service/api_client.dart`, l.148-217). Le mapping utilise un `switch` sur le `statusCode` Dio :

```dart
return switch (statusCode) {
  400 => ValidationError(detailStr, statusCode: statusCode),
  401 => AuthenticationError(detailStr, statusCode: statusCode),
  402 => QuotaExceededError(detailStr, statusCode: statusCode),
  403 => ForbiddenError(detailStr, statusCode: statusCode),
  404 => NotFoundError(detailStr, statusCode: statusCode),
  409 when data is Map && data['error'] == 'stale_context' =>
    StaleContextError(detailStr, statusCode: statusCode),
  429 => RateLimitError(detailStr, statusCode: statusCode),
  500 => ServerError(detailStr, statusCode: statusCode),
  _ => UnknownError(detailStr, statusCode: statusCode),
};
```

### loggedFailure

`lib/core/logged_failure.dart` -- factory qui cree un `Failure` et enregistre l'erreur dans Crashlytics (sauf `CancelledError`) :

```dart
Failure<T> loggedFailure<T>(AppError error, {StackTrace? stackTrace}) {
  if (error is! CancelledError && getIt.isRegistered<CrashlyticsService>()) {
    getIt<CrashlyticsService>().recordAppError(error, stackTrace: stackTrace ?? StackTrace.current);
  }
  return Failure<T>(error);
}
```

## Repository Pattern

Chaque domaine definit une interface abstraite et une implementation concrete :

```dart
// lib/repositories/trip_repository.dart
abstract class TripRepository {
  Future<Result<Trip>> createTrip({required String title, ...});
  Future<Result<List<Trip>>> getTrips();
  Future<Result<TripHome>> getTripHome(String tripId);
  Future<Result<Trip>> getTripById(String tripId);
  Future<Result<void>> deleteTrip(String tripId);
}
```

16 repositories au total, tous exportes via `lib/repositories/repositories.dart` :
`AccommodationRepository`, `ActivityRepository`, `AiRepository`, `AuthRepository`, `BaggageRepository`, `BookingRepository`, `BudgetRepository`, `FeedbackRepository`, `NotificationRepository`, `ProfileRepository`, `SubscriptionRepository`, `TravelerRepository`, `TripRepository`, `TransportRepository`, `TripShareRepository`, `WeatherRepository`.

## API Layer -- ApiClient

`lib/service/api_client.dart` -- wrapper Dio avec :

- **JWT auto-injection** : interceptor `onRequest` lit le token via `StorageService` et l'injecte dans `Authorization: Bearer`.
- **401 refresh single-guard** : flag `_isRefreshing` empeche les refresh paralleles. Utilise une instance Dio separee pour eviter les boucles d'interceptor.
- **AuthEventBus** : si le refresh echoue, `AuthEventBus.fireUnauthenticated()` est emis. `AuthListener` (`lib/auth/widgets/auth_listener.dart`) ecoute ce stream et redirige vers `/login`.
- **Performance interceptor** : `PerformanceInterceptor` mesure les temps de requete.
- **Debug logging** : `LogInterceptor` actif en `kDebugMode` uniquement.

## Cache / Offline

### CacheService

`lib/core/cache/cache_service.dart` -- cache local base sur Hive avec TTL de 15 minutes par defaut :

```dart
// Ecriture
await cache.put('trips_cache', 'grouped_trips', data.toJson());

// Lecture avec TTL
final cached = await cache.get('trips_cache', 'grouped_trips',
    ttl: const Duration(minutes: 15));
```

### CachedTripRepository

`lib/service/cached_trip_repository.dart` -- decorator qui wraps le `TripRepositoryImpl` remote :

- **READ** : si online, appel remote + mise en cache. Si offline, lecture cache.
- **WRITE** : toujours delegue au remote + invalidation des caches associes.
- Les appels pagines ne sont pas caches (delegues directement).

```dart
class CachedTripRepository implements TripRepository {
  final TripRepository _remote;
  final CacheService _cache;
  final ConnectivityService _connectivity;

  @override
  Future<Result<TripGrouped>> getGroupedTrips() async {
    if (_connectivity.isOnline) {
      final result = await _remote.getGroupedTrips();
      if (result case Success(:final data)) {
        await _cache.put(_box, 'grouped_trips', data.toJson());
      }
      return result;
    }
    return _fromCache('grouped_trips', TripGrouped.fromJson);
  }
}
```

### ConnectivityService + ConnectivityBloc

`lib/core/cache/connectivity_service.dart` -- ecoute `connectivity_plus` et expose un stream `bool`. Le `ConnectivityBloc` (`lib/core/cache/connectivity_bloc.dart`) expose `ConnectivityOnline` / `ConnectivityOffline` pour la UI. L'`OfflineBanner` (`lib/components/offline_banner.dart`) affiche une baniere jaune quand offline.

## Lifecycle

### AppLifecycleObserver

`lib/core/app_lifecycle_observer.dart` -- observe `WidgetsBindingObserver` et fire un callback `onResumed` quand l'app revient au premier plan. Utilise dans `main.dart` pour rafraichir le `HomeBloc` :

```dart
_lifecycleObserver = AppLifecycleObserver(
  onResumed: () {
    if (_homeBloc.state is! HomeInitial && !_homeBloc.isClosed) {
      _homeBloc.add(RefreshHome());
    }
  },
);
```

### AuthEventBus

`lib/core/auth_event_bus.dart` -- bus d'evenements broadcast pour deconnexion forcee. L'`ApiClient` fire `AuthEventBus.fireUnauthenticated()` apres un echec de refresh token. L'`AuthListener` ecoute et redirige vers `/login`.

### Initialisation (main.dart)

Sequence de boot dans `main()` :
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `LiquidGlassWidgets.initialize()` (shaders iOS)
3. `setupServiceLocator()` (GetIt)
4. Firebase init + Stripe config
5. Crashlytics setup (FlutterError + PlatformDispatcher)
6. FCM permissions + background handler
7. Local notifications init
8. Cache init (`CacheService.initialize()` + `ConnectivityService.initialize()`)
9. `runApp(MyApp())`

## Models -- Freezed

Tous les modeles suivent le pattern `@freezed` avec annotations `@JsonKey` pour le mapping snake_case :

```dart
@freezed
abstract class Activity with _$Activity {
  const factory Activity({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(unknownEnumValue: ActivityCategory.other)
    @Default(ActivityCategory.other) ActivityCategory category,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
}
```

Regeneration apres modification : `flutter pub run build_runner build --delete-conflicting-outputs`.

## Pagination

`PaginatedResponse<T>` (`lib/core/paginated_response.dart`) encapsule les reponses paginables :

```dart
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int totalPages;
  bool get hasMore => page < totalPages;
}
```

Le widget `PaginatedList<T>` (`lib/components/paginated_list.dart`) gere le scroll infini avec `loadMoreThreshold` et supporte le groupement (`groupBy` + `sectionHeaderBuilder`).

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| AgentService non implemente | `lib/service/agent_service.dart` contient deux methodes marquees `TODO: Implement in Epic 6.` -- service d'agent IA vide | P1 |
| LocationService multi-destination | `lib/service/location_service.dart:29` contient `TODO: Implement multi-destination search when backend supports it` | P2 |
| Pas de BlocObserver centralise | Aucun `BlocObserver` configure dans `main.dart` pour le logging global des transitions BLoC -- utile pour le debug et le monitoring | P2 |
| Cache weather non teste offline | `CachedWeatherRepository` et `CachedTripRepository` sont enregistres mais la pagination n'est pas cachee (delegation directe au remote) -- perte de donnees en offline sur les listes longues | P1 |
| Pas de retry automatique | Aucun mecanisme de retry automatique sur `NetworkError` ou `RateLimitError` dans `ApiClient` -- les erreurs transitoires ne sont pas re-tentees | P2 |
| Tests d'integration repository manquants | Les repositories cached (`CachedTripRepository`, `CachedWeatherRepository`) n'ont pas de tests d'integration visibles verifiant le fallback offline | P1 |
| ConnectivityService dispose asymetrique | `ConnectivityService.dispose()` est `async` mais appele depuis `_MyAppState.dispose()` qui est synchrone (`lib/main.dart:132`) -- le dispose peut ne pas se completer | P2 |
