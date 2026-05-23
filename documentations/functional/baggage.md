# Bagages

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

La feature Bagages fournit une checklist interactive de packing pour chaque voyage. L'utilisateur cree des items manuellement (nom, quantite, categorie) ou demande des suggestions a l'IA, qui prend en compte la destination, la duree, les activites prevues et le nombre de voyageurs. Chaque item porte un flag `is_packed` que l'utilisateur coche au fur et a mesure. Une barre de progression circulaire affiche le ratio packed/total et une celebration se declenche a 100%.

La checklist est offline-first via `CachedBaggageRepository` : lecture cache si hors-ligne, ecritures mises en file via `OfflineWriteQueue` et rejouees au retour de la connexion. Les permissions sont scopees par role (Owner / Editor / Viewer) via les dependencies trip-access du backend, et toute mutation est bloquee une fois le trip passe au statut COMPLETED.

## Cote Backend

### Endpoints (`/v1/trips/{tripId}/baggage`)

| Methode | Route | Acces | Description |
|---------|-------|-------|-------------|
| POST | `/baggage` | Editor | Cree un item. Retourne 201 |
| GET | `/baggage` | Owner + Viewer | Liste tous les items du trip |
| PATCH | `/baggage/{baggageItemId}` | Editor | Mise a jour partielle (nom, qte, packed, categorie, notes) |
| DELETE | `/baggage/{baggageItemId}` | Editor | Supprime. Retourne 204 |
| POST | `/baggage/suggest` | Editor + quota IA | Suggestions IA contextualisees |

Les dependencies `get_trip_editor_access` / `get_trip_access` portent les checks d'ownership. Le suggest passe aussi par `require_ai_quota` (plan free/premium) puis incremente le compteur via `PlanService.increment_ai_generation()`.

### Modele SQLAlchemy (`BaggageItem`)

| Champ | Type | Notes |
|-------|------|-------|
| `id` | UUID PK | |
| `trip_id` | UUID FK trips | indexe |
| `name` | String | obligatoire |
| `quantity` | Integer | default 1 |
| `is_packed` | Boolean | default false |
| `category` | String | default `OTHER` (enum `BaggageCategory`) |
| `notes` | String? | optionnel |
| `created_at` / `updated_at` | DateTime tz | auto |

Categories de l'enum : `DOCUMENTS`, `CLOTHING`, `ELECTRONICS`, `TOILETRIES`, `HEALTH`, `ACCESSORIES`, `OTHER`.

### Service (`BaggageItemsService`)

CRUD classique avec guard `_check_trip_not_completed()` sur create/update/delete : un trip au statut `COMPLETED` ne peut plus voir ses bagages modifies (`AppError TRIP_COMPLETED` 403).

### Suggestions IA (`suggest_baggage_items`)

1. **Construction du prompt utilisateur** (FR/EN selon `Accept-Language`, normalise via `normalize_locale`) avec :
   - `destination_name` du trip (fallback "Unknown" / "Inconnue")
   - duree en jours (`end_date - start_date`)
   - jusqu'a 8 titres d'activites prevues (si la relation est chargee)
   - `nb_travelers`
   Le bloc de labels traduits vit dans `_BAGGAGE_SUGGEST_LABELS` (constant module-level), une cle par locale.
2. **Appel LLM** via `LLMService.acall_llm()` avec le prompt systeme rendu par `render("baggage", locale=...)` (templates Jinja2 dans `src/agent/prompts/templates/{en,fr}/baggage.j2`).
3. **Parsing** de `result["items"]` en `[{name, quantity, category, reason}]`. Le service ne fait aucune validation forte sur les categories renvoyees (chaine libre cote retour).
4. **Deduplication** : on exclut toute suggestion dont le `name` (case-insensitive) existe deja dans les items du trip via `get_baggage_items_by_trip()`.
5. **Fallback** : si le LLM jette une exception, log via `logger.error("Baggage suggest LLM call failed", {"error": ...})` et retour d'une liste hardcodee de 6 essentiels (Passport, Travel adapter, Sunscreen, First aid kit, Phone charger, Change of clothes). La dedup s'applique aussi au fallback : si l'utilisateur a deja "Passport" en base, il ne re-apparaitra pas.

Reponse : `BaggageSuggestionListResponse { items: [BaggageSuggestionItem] }` ou chaque item a `name`, `quantity` (default 1), `category` (default "OTHER"), `reason?`. Le contrat est volontairement permissif pour rester compatible avec les variantes de structure renvoyees par le LLM.

## Cote Mobile

### Page & navigation

`BaggageBlocPage` (`bagtrip/lib/baggage/view/baggage_page.dart`) recoit `tripId`, `role` (default `OWNER`), `isCompleted` (default `false`), cree le `BaggageBloc` via `BlocProvider`, fire `LoadBaggage(tripId)` immediatement dans le `create` callback et rend `BaggageView`. La route est exposee sous `/home/:tripId/baggage` via `GoRouter` type. Le bloc reste local a la page (contrairement a `HomeBloc` qui vit app-level) — sortir de la page reset le state.

### BLoC (`BaggageBloc`)

Le bloc consomme `BaggageRepository` (injecte via `getIt`, fallback testable). Events :

| Event | Action |
|-------|--------|
| `LoadBaggage` | Charge tous les items, calcule `packedCount`/`totalCount` |
| `TogglePacked` | PATCH `isPacked` inverse + detection transition vers 100% |
| `CreateBaggageItem` | POST item, append au state |
| `UpdateBaggageItem` | PATCH (nom/qte/categorie), remplace dans la liste |
| `DeleteBaggageItem` | DELETE, retire du state |
| `SuggestBaggage` | POST `/suggest`, preserve les items pendant le chargement |
| `AcceptSuggestion` | Cree l'item depuis la suggestion + reload + retire la suggestion |
| `DismissSuggestion` | Retire la suggestion localement (aucun appel API) |
| `ReorderBaggageItem` | Drag & drop des items non-packed (local uniquement) |

States : `BaggageInitial`, `BaggageLoading`, `BaggageLoaded` (items + counts + suggestions + celebrationTriggered), `BaggageSuggestionsLoading` (preserve items + counts), `BaggageQuotaExceeded`, `BaggageError`.

### Packing toggle & celebration

Dans `_onTogglePacked` :
- `wasPreviouslyAllPacked = current.packedCount == current.totalCount`
- `isNowAllPacked = packed == total && total > 0`
- Si transition de non-complet vers complet : `celebrationTriggered = true` dans le state suivant
- Le widget `BaggageCelebration` ecoute ce flag pour declencher l'animation

### Categories cote mobile

Les categories cote bagage ne passent pas par `category_mappers.dart` (qui ne couvre que `ActivityCategory` et `BudgetCategory`). Elles sont gerees comme des `String?` libres dans le modele `BaggageItem` Freezed, et l'UI (`BaggageAddForm`, `BaggageEditForm`) propose un selecteur sur les valeurs de l'enum backend (`DOCUMENTS`, `CLOTHING`, `ELECTRONICS`, `TOILETRIES`, `HEALTH`, `ACCESSORIES`, `OTHER`).

### Widgets

| Widget | Role |
|--------|------|
| `BaggageView` | UI principale (header, liste, FAB suggest IA) |
| `BaggageProgressHeader` | Arc circulaire `_ProgressArcPainter` + barre lineaire + compteur "X/Y" |
| `BaggageItemTile` | Ligne avec checkbox, tap-to-edit, `AdaptiveContextMenu` iOS |
| `BaggageAddForm` | Bottom sheet d'ajout (nom, quantite, categorie) |
| `BaggageEditForm` | Bottom sheet d'edition pre-remplie |
| `BaggageSuggestionCard` | Carte IA (icone `auto_awesome`, nom, reason, accepter / rejeter, fade-out 300ms) |
| `BaggageCelebration` | Animation 100% packed |

### Offline-first (`CachedBaggageRepository`)

Wrapper implementant `BaggageRepository` autour du remote `BaggageItemService` (fichier reel : `bagtrip/lib/service/cached_baggage_repository.dart`, le chemin `lib/core/cache/` ne contient pas ce wrapper). Stockage Hive box `baggage_cache`, cle par trip `baggage:{tripId}`.

- **GET (`getByTrip`)** : online -> remote + put cache `baggage:{tripId}`. Offline -> lecture cache, `Failure(UnknownError("No cached data available"))` si vide.
- **POST / PATCH / DELETE** : online -> remote + invalide la cle cache. Offline -> enqueue dans `OfflineWriteQueue` (operation `baggage:createBaggageItem` / `updateBaggageItem` / `deleteBaggageItem`), retour `Failure(NetworkError("Operation queued for sync"))` pour signaler l'attente.
- **Replay** : `_registerReplayHandlers()` enregistre les 3 handlers au constructor. Au retour de la connexion, `OfflineWriteQueue` rejoue chaque entree dans l'ordre FIFO, invalide le cache trip a chaque succes pour forcer un refetch propre au prochain `getByTrip`.
- **Suggest IA** : non cache, non queue (necessite obligatoirement le LLM serveur). Echec immediat si offline.
- **Connectivite** : la decision online/offline est lue depuis `ConnectivityService.isOnline`, lui-meme alimente par `ConnectivityBloc` et l'ecoute du package `connectivity_plus`.

## Flux

### Suggest IA -> validate -> pack

1. L'utilisateur tape sur le bouton "Suggestions IA" dans `BaggageView`.
2. `SuggestBaggage` est dispatche -> bloc emet `BaggageSuggestionsLoading` (items courants preserves).
3. `CachedBaggageRepository.suggestBaggage()` delegue au remote (`POST /suggest`).
4. Backend : `require_ai_quota` -> `BaggageItemsService.suggest_baggage_items()` (prompt context -> LLM -> dedup) -> `PlanService.increment_ai_generation()`.
5. Reponse renvoyee comme liste de `SuggestedBaggageItem` -> bloc emet `BaggageLoaded` avec `suggestions` peuplees.
6. L'UI rend chaque suggestion dans une `BaggageSuggestionCard`. L'utilisateur :
   - **Accepte** -> `AcceptSuggestion` -> POST `/baggage` -> reload de la liste -> suggestion retiree
   - **Rejette** -> `DismissSuggestion` -> retrait local sans appel API
7. Une fois l'item cree, l'utilisateur le coche dans `BaggageItemTile` -> `TogglePacked` -> PATCH `isPacked: true`.
8. Quand `packed == total`, le bloc set `celebrationTriggered: true` -> `BaggageCelebration` joue l'animation une fois.

### Quota depasse

Si l'utilisateur free a epuise son quota IA, `require_ai_quota` retourne 403 `AI_QUOTA_EXCEEDED`. Le repository remonte un `QuotaExceededError`, le bloc emet `BaggageQuotaExceeded`, l'UI affiche un upsell premium et conserve les items courants sans toucher a la liste.

### Trip completed

Toute mutation (`create`, `update`, `delete`, `suggest` cote service) est bloquee si `trip.status == COMPLETED` via `_check_trip_not_completed()` (403 `TRIP_COMPLETED`). Cote mobile, `BaggageView` recoit `isCompleted` et masque les CTAs d'edition.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Persistence du reordonnancement | `ReorderBaggageItem` reordonne localement mais le modele n'a pas de champ `position`. A la prochaine ouverture, l'ordre est perdu. | P2 |
| Categorie typee cote Flutter | Les categories restent des `String?` libres au lieu d'un enum Freezed mappe via `category_mappers.dart`. Pas de single source of truth icon/color/label. | P2 |
| Partage actif entre voyageurs | Les viewers lisent la checklist mais ne contribuent pas. Pas d'assignation d'items a un voyageur. | P2 |
| Tri / filtrage par categorie | L'UI affiche items non-packed puis packed, sans filtre par categorie (DOCUMENTS, CLOTHING, etc.). | P2 |
| Export / impression checklist | Pas de generation PDF ni de partage hors-app. | P3 |
| Cache des suggestions IA | `suggestBaggage` court-circuite le cache. Une rerelance offline echoue meme si la derniere reponse est recente. | P3 |
| Tests widget `BaggageCelebration` | Animation non couverte par un test dedie. | P2 |
