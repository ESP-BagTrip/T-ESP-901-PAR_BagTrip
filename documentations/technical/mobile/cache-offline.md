# Cache et mode offline

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip embarque un cache local Hive avec TTL 15 min par defaut, un service de connectivite temps reel, et une file d'attente d'ecritures offline rejouee au retour du reseau. Cinq domaines metier sont caches via des repositories decorateurs (Trip, Activity, Baggage, Budget, Weather) qui appliquent un pattern cache-aside : online -> remote + cache.put, offline -> cache.get + repli `Failure(UnknownError)` si vide. Les mutations offline sur Activity, Baggage et Budget sont mises en file dans `OfflineWriteQueue` et rejouees automatiquement quand `ConnectivityService` signale le retour online.

Architecture :

```
ConnectivityService (connectivity_plus)
        |
        v
ConnectivityBloc --> OfflineBanner (AppShell)
        |
CacheService (Hive boxes, TTL)
        |
        v
Cached{Trip,Activity,Baggage,Budget,Weather}Repository
   |-- online  -> remote API + cache.put
   |-- offline -> cache.get | enqueue mutation
        |
        v
OfflineWriteQueue --> replay() au retour online
```

## CacheService

Fichier : `bagtrip/lib/core/cache/cache_service.dart`.

Wrapper minimaliste sur Hive (`hive_flutter`). Chaque entree stocke `{ data, cachedAt }` ou `cachedAt` est un timestamp ms. La lecture compare l'age vs le TTL et supprime l'entree expiree avant de retourner `null`.

API :

| Methode | Comportement |
|---------|--------------|
| `CacheService.initialize()` | `Hive.initFlutter()` ; appele dans `main()` avant l'app |
| `put(boxName, key, data)` | Ecrit `{data, cachedAt: now}` dans la box, ouverture lazy |
| `get(boxName, key, {ttl = 15 min})` | Retourne data si `age <= ttl`, sinon supprime et retourne `null` ; `ttl = 0` force expiration |
| `delete(boxName, key)` | Suppression unitaire |
| `clearBox(boxName)` | Vide une box |
| `clearAll()` | Vide toutes les boxes deja ouvertes (tracking via `_openedBoxes`) |

Invalidation : pas de TTL custom centralise. Chaque cached repository pilote son TTL en passant `ttl:` explicitement (Weather utilise 1h), sinon defaut 15 min. Les mutations invalident les cles concernees via `cache.delete(boxName, key)` immediatement apres un `Success` remote.

Pas de limite de taille, pas de politique LRU. Les boxes Hive grossissent sans borne (cf. section finale).

## Cached repositories

Cinq decorateurs en `bagtrip/lib/service/cached_*_repository.dart` implementent chacun l'interface du repository sous-jacent. Pattern uniforme :

- READ online -> appel `_remote.xxx()`, si `Success` -> `_cache.put`, retourne le `Result` remote.
- READ offline -> `_cache.get`, si hit -> `Success(fromJson)`, sinon `Failure(UnknownError('No cached data available'))`.
- WRITE online -> `_remote.xxx()`, si `Success` -> invalidation des cles impactees.
- WRITE offline (si `OfflineWriteQueue` injectee) -> `enqueue(PendingWriteOperation)` + `Failure(NetworkError('Operation queued for sync'))`.

Tableau de couverture :

| Repository | Box Hive | Cles | TTL | Queue offline | Notes |
|------------|----------|------|-----|---------------|-------|
| `CachedTripRepository` | `trips_cache` | `grouped_trips`, `all_trips`, `trip:{id}`, `trip_home:{id}` | 15 min | Non | `getTripsPaginated` bypass cache (toujours remote) |
| `CachedActivityRepository` | `activities_cache` | `activities:{tripId}` | 15 min | Oui (`create`, `update`, `delete`) | `getActivitiesPaginated` et `suggestActivities` bypass cache |
| `CachedBaggageRepository` | `baggage_cache` | `baggage:{tripId}` | 15 min | Oui (`create`, `update`, `delete`) | `suggestBaggage` bypass cache |
| `CachedBudgetRepository` | `budget_cache` | `budget_items:{tripId}`, `budget_summary:{tripId}` | 15 min | Oui (`create`, `update`, `delete`) | `estimateBudget` bypass cache ; `acceptBudgetEstimate` invalide `budget_summary` |
| `CachedWeatherRepository` | `weather` | `trip_{tripId}` | 1h | Non (read-only) | TTL plus long, donnees stables sur la duree d'un trip |

Tous les decorateurs sont enregistres dans `bagtrip/lib/config/service_locator.dart` comme `LazySingleton` en wrappant le repository remote :

```
CacheService          -> getIt singleton
ConnectivityService   -> getIt singleton (initialize() appele dans main.dart)
OfflineWriteQueue     -> getIt singleton
Cached{X}Repository   -> wraps {X}RepositoryImpl + CacheService + ConnectivityService [+ OfflineWriteQueue]
```

Les BLoCs et widgets consomment l'interface `XxxRepository`, transparents au wrapping.

## Connectivity

Fichiers : `bagtrip/lib/core/cache/connectivity_service.dart` + `connectivity_bloc.dart`.

`ConnectivityService` encapsule `connectivity_plus`. Maintient `_isOnline` (defaut `true`), expose un `Stream<bool>` broadcast qui n'emet que sur transitions (deduplication via comparaison `online != _isOnline` avant `add`). `_mapResults` traite `ConnectivityResult.none` comme offline, toute autre liste non-vide comme online.

Cycle de vie :

- `main.dart` : `await getIt<ConnectivityService>().initialize()` apres `CacheService.initialize()`.
- `dispose()` cancel la subscription `onConnectivityChanged` et close le `StreamController`.

`ConnectivityBloc` ecoute le stream et expose une `sealed class ConnectivityState` :

- Etat initial : `ConnectivityOnline` ; si `service.isOnline == false` au demarrage, le constructeur dispatch immediatement un `ConnectivityChanged(isOnline: false)`.
- Evenement unique : `ConnectivityChanged({required bool isOnline})`.
- Etats : `ConnectivityOnline`, `ConnectivityOffline`.

Le bloc est fourni dans le `MultiBlocProvider` app-level (`main.dart`) pour rester monte sur toute l'app.

`OfflineBanner` (`bagtrip/lib/components/offline_banner.dart`) ecoute `ConnectivityBloc` via `BlocBuilder`, affiche un container `AppColors.warning` plein largeur avec `l10n.offlineMode` quand `state is ConnectivityOffline`, sinon `SizedBox.shrink()`. Transition via `AnimatedSwitcher` 300 ms.

Mount dans `AppShell` (`bagtrip/lib/navigation/app_shell.dart`) : le banner est rendu en tete de colonne **avant** `widget.navigationShell` sur les deux branches plateforme (`CupertinoPageScaffold` iOS et `Scaffold` Android), donc visible sur toutes les routes shell.

## OfflineWriteQueue

Fichier : `bagtrip/lib/core/cache/offline_write_queue.dart`.

File d'attente persistee dans la box Hive `offline_write_queue`, cle `pending_operations`. Permet d'accepter les mutations cote client en offline et de les rejouer dans l'ordre quand la connectivite revient.

Modele `PendingWriteOperation` :

```dart
{
  id: String,          // microsecondsSinceEpoch unique
  repository: String,  // 'activity' | 'baggage' | 'budget'
  method: String,      // 'createActivity' | 'updateBaggageItem' | ...
  arguments: Map<String, dynamic>,
  createdAt: DateTime,
}
```

Cycle :

1. **Enqueue** : le cached repository detecte `!connectivity.isOnline && queue != null`, construit un `PendingWriteOperation`, appelle `queue.enqueue(op)`. Le store relit la liste, append, sauvegarde, emet le nouveau count sur `pendingCount` (`StreamController<int>.broadcast`). Le repository retourne `Failure(NetworkError('Operation queued for sync'))` au caller.

2. **Register handlers** : chaque cached repository wrappable (Activity, Baggage, Budget) appelle `_registerReplayHandlers()` dans son constructeur, enregistrant un `ReplayHandler` par cle `'{repository}:{method}'`. Le handler reconstruit les arguments typés depuis la `Map<String, dynamic>` et appelle le remote, invalide le cache local sur succes, retourne `bool`.

3. **Listening** : `OfflineWriteQueue.startListening()` souscrit au `ConnectivityService.onConnectivityChanged` ; chaque transition `isOnline == true` declenche `replay()`. **Attention** : aucun appel `startListening()` n'est fait au boot dans `main.dart` ni dans `service_locator.dart` — la file n'est rejouee que si du code appelant l'invoque, soit la encore au prochain enqueue/replay manuel. Cf. section finale.

4. **Replay** : itere les operations triees par `createdAt`, applique le handler correspondant. Si `handler == null` (cle inconnue) ou si le handler retourne `false`, l'operation est conservee en file ET `stopped = true` : toutes les operations suivantes sont skippees pour preserver l'ordre causal (eviter qu'un `update` reussisse avant qu'un `create` echoue). La liste restante est resauvegardee, le count emis.

5. **clear()** : vide explicitement la file, emet `0` sur `pendingCount`.

Garanties :

- Ordre FIFO preserve via tri sur `createdAt` a chaque load.
- Atomicite par operation (succes complet ou conservee).
- Pas de retry automatique avec backoff ; le replay est all-or-stop sur la premiere erreur.
- Pas de deduplication : enqueuer deux `update` sur la meme entite genere deux appels au replay.
- Pas de TTL sur les operations en file (le `CacheService` est utilise comme store mais le TTL n'est pas exploite pour cette box specifique : `_loadOperations` appelle `_cache.get` avec TTL defaut 15 min, ce qui signifie qu'une operation enqueue en offline depuis plus de 15 min sans reconnexion est silencieusement supprimee — bug connu).

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| `startListening()` jamais appele | Le replay automatique au retour online ne se declenche pas car `OfflineWriteQueue.startListening()` n'est appele ni dans `main.dart` ni dans `service_locator.dart`. La file ne se vide qu'au prochain enqueue offline ou via un trigger manuel. | P0 |
| TTL applique aux pending ops | `_loadOperations` lit via `cache.get` qui applique le TTL 15 min defaut : une mutation offline non rejouee dans les 15 min est perdue. Il faut passer `ttl: Duration.zero` ou bypasser le TTL pour cette box. | P0 |
| Accommodations non cachees | Pas de `CachedAccommodationRepository`. L'onglet hebergements et la completion score deviennent indisponibles offline. | P1 |
| Flights / shares / feedback non caches | Vols manuels, partages, feedback post-voyage delegant directement au remote sans cache ni queue. | P1 |
| Pagination jamais cachee | `getTripsPaginated`, `getActivitiesPaginated` court-circuitent le cache. Pas de fallback offline pour les listes paginees. | P2 |
| Limite de taille / eviction LRU | Pas de quota par box, pas d'eviction des entrees froides. Les boxes Hive grossissent indefiniment. | P2 |
| Prefetch au lancement | Aucun warm-up cache au demarrage. Premiere ouverture offline = ecran vide tant qu'aucune session online n'a peuple les boxes. | P2 |
| Backoff sur replay | Echec replay -> stop total. Pas de retry avec backoff exponentiel ni de discrimination entre erreur reseau transitoire et erreur metier definitive (404, 422). | P2 |
| Conflits offline / serveur | Pas de strategie de resolution si l'entite a ete modifiee cote serveur entre l'enqueue et le replay (last-write-wins implicite via l'API). | P2 |
| Persistance theme / langue | `SettingsBloc` ne persiste pas les preferences ; choix de theme et de langue perdus au redemarrage. | P2 |
| Indicateur UI du pending count | `OfflineWriteQueue.pendingCount` est expose mais aucun widget ne le consomme. L'utilisateur ne voit pas le nombre de mutations en attente. | P3 |
| Test d'integration OfflineBanner | Pas de widget test du cycle complet ConnectivityService -> Bloc -> OfflineBanner dans `AppShell`. | P3 |
