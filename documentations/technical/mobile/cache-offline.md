# Cache et mode offline

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

BagTrip implemente un systeme de cache local base sur Hive avec un TTL de 15 minutes par defaut, combine a un service de connectivite qui detecte les changements de reseau en temps reel. Lorsque l'utilisateur perd sa connexion, l'application bascule automatiquement sur les donnees en cache et affiche un bandeau d'avertissement. Le pattern repose sur trois couches : `CacheService` (stockage), `ConnectivityService` (detection reseau), et `CachedTripRepository` (orchestration cache/remote).

## Architecture

```
ConnectivityService (connectivity_plus)
        │
        ▼
ConnectivityBloc ──► OfflineBanner (UI)
        │
CacheService (Hive, TTL 15min)
        │
        ▼
CachedTripRepository
   ├── online  → remote API + cache.put()
   └── offline → cache.get()
```

## CacheService — stockage local Hive

**Fichier** : `bagtrip/lib/core/cache/cache_service.dart`

Le `CacheService` encapsule Hive et ajoute un systeme de TTL transparent. Chaque entree est stockee avec un timestamp `cachedAt` qui permet de verifier l'expiration a la lecture.

```dart
Future<void> put(String boxName, String key, Map<String, dynamic> data) async {
  final box = await _openBox(boxName);
  await box.put(key, {
    'data': data,
    'cachedAt': DateTime.now().millisecondsSinceEpoch,
  });
}

Future<Map<String, dynamic>?> get(
  String boxName, String key,
  {Duration ttl = const Duration(minutes: 15)},
) async {
  // ... verifie l'age vs TTL, supprime si expire
}
```

**API** :
- `put(boxName, key, data)` — stocke avec timestamp
- `get(boxName, key, {ttl})` — lit si non expire, sinon supprime et retourne `null`
- `delete(boxName, key)` — suppression unitaire
- `clearBox(boxName)` — vide une box entiere
- `clearAll()` — vide toutes les boxes ouvertes
- `CacheService.initialize()` — static, appele dans `main()` pour initialiser Hive

## ConnectivityService — detection reseau

**Fichier** : `bagtrip/lib/core/cache/connectivity_service.dart`

Utilise `connectivity_plus` pour detecter les changements reseau. Expose un `Stream<bool>` qui emet uniquement sur les transitions (online <-> offline), avec deduplication.

```dart
class ConnectivityService {
  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  bool _mapResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) return false;
    return results.isNotEmpty;
  }
}
```

Initialise dans `main()` :
```dart
await CacheService.initialize();
await getIt<ConnectivityService>().initialize();
```

## ConnectivityBloc — gestion d'etat

**Fichier** : `bagtrip/lib/core/cache/connectivity_bloc.dart`

BLoC qui ecoute le `ConnectivityService` et expose un etat simple : `ConnectivityOnline` ou `ConnectivityOffline`.

```dart
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  ConnectivityBloc({ConnectivityService? connectivityService})
    : super(ConnectivityOnline()) {
    // ecoute le stream, emet ConnectivityChanged
    _subscription = service.onConnectivityChanged.listen((isOnline) {
      add(ConnectivityChanged(isOnline: isOnline));
    });
  }
}
```

- **Etat initial** : `ConnectivityOnline` (verifie `service.isOnline` dans le constructeur)
- **Evenements** : `ConnectivityChanged(isOnline: bool)`
- **Etats** : `ConnectivityOnline`, `ConnectivityOffline` (sealed class)

Le bloc est fourni dans le `MultiBlocProvider` app-level dans `main.dart`.

## CachedTripRepository — cache-aside pattern

**Fichier** : `bagtrip/lib/service/cached_trip_repository.dart`

Implemente `TripRepository` et orchestre la strategie cache-aside :

**Lecture (online)** : appel remote → si `Success`, stocke en cache → retourne le resultat.
**Lecture (offline)** : lit depuis le cache → si cache hit, retourne `Success` → sinon `Failure(UnknownError)`.
**Ecriture** : delegue toujours au remote → si `Success`, invalide les caches concernes.

```dart
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
```

**Invalidation** : les mutations (`createTrip`, `updateTrip`, `deleteTrip`) invalident les cles de liste (`grouped_trips`, `all_trips`) et les cles specifiques au trip (`trip:{id}`, `trip_home:{id}`).

**Note** : les requetes paginee (`getTripsPaginated`) ne sont pas cachees et delegent toujours au remote.

## OfflineBanner — indicateur visuel

**Fichier** : `bagtrip/lib/components/offline_banner.dart`

Bandeau jaune (`AppColors.warning`) affiche avec un `AnimatedSwitcher` (300ms) quand l'etat est `ConnectivityOffline`. Le texte est localise via `l10n.offlineMode`.

```dart
BlocBuilder<ConnectivityBloc, ConnectivityState>(
  builder: (context, state) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: state is ConnectivityOffline
          ? Container(/* bandeau warning */)
          : const SizedBox.shrink(),
    );
  },
);
```

Integre dans `AppShell` (`bagtrip/lib/navigation/app_shell.dart`).

## Enregistrement DI

**Fichier** : `bagtrip/lib/config/service_locator.dart`

```
CacheService          → getIt singleton
ConnectivityService   → getIt singleton
CachedTripRepository  → wraps TripRepository remote + CacheService + ConnectivityService
```

## Tests

| Fichier | Portee | Tests |
|---------|--------|-------|
| `test/core/cache/cache_service_test.dart` | put/get, TTL, delete, clearBox, clearAll, overwrite | 7 tests |
| `test/core/cache/connectivity_bloc_test.dart` | Initial state, offline initial, stream transitions | 4 blocTests |
| `test/core/cache/connectivity_service_test.dart` | isOnline default, initialize, stream emit, dedup, transitions | 5 tests |
| `test/service/cached_trip_repository_test.dart` | online/offline read, cache hit/miss, write invalidation | 9 tests |

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Cache des activites | Seul `TripRepository` est wrape par `CachedTripRepository`. Les activites, bagages, budget, accommodations n'ont pas d'equivalent `CachedXxxRepository`. | P1 |
| Queue d'ecriture offline | Les operations d'ecriture echouent silencieusement en mode offline car elles delegent toujours au remote. Un systeme de file d'attente (write-behind queue) avec retry au retour de la connexion est absent. | P1 |
| Persistance du theme/langue | `SettingsBloc` ne persiste pas les preferences (pas de SharedPreferences/Hive). Le choix de theme et de langue est perdu au redemarrage de l'app. (`bagtrip/lib/settings/bloc/settings_bloc.dart`) | P1 |
| Cache des requetes paginee | `getTripsPaginated` est explicitement exclue du cache. Les listes paginee ne sont pas disponibles offline. | P2 |
| Taille du cache | Pas de limite de taille ni de politique d'eviction (LRU). Les boxes Hive grossissent sans borne. | P2 |
| Prefetch au lancement | Pas de pre-chargement des donnees critiques au demarrage pour garantir un cache chaud avant la premiere perte de connexion. | P2 |
| Test d'integration OfflineBanner | Pas de test widget verifiant l'apparition/disparition du bandeau offline dans l'arbre widget complet. | P2 |
