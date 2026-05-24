# Page de detail d'un voyage (Trip Detail)

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

L'ecran Trip Detail est le hub centralisateur de BagTrip apres l'etape de planification. Tout ce qu'un utilisateur fait sur un voyage existant (valider une suggestion, modifier des dates, ajouter une depense, inviter quelqu'un, packer un bagage) passe par cette page. Elle agrege sept domaines : metadonnees du trip, vols, hebergements, activites, bagages, budget et partages, plus un score de completion qui resume l'avancement.

Le choix architectural fort est d'avoir **un seul BLoC** (`TripDetailBloc`) qui possede l'integralite du snapshot. Les sept domaines ne sont pas eclates en sous-BLoCs : chaque mutation doit pouvoir recalculer le score de completion sur l'ensemble du state, et l'UI consomme tous les domaines simultanement (le hero affiche le budget, le board de validation affiche les compteurs par domaine, etc.). Le bloc reste lisible parce qu'il est decoupe en `part files` par domaine.

Cote backend, la page repose sur un endpoint principal `GET /v1/trips/{id}` qui retourne le trip + le role + le pourcentage de completion calcule en batch, et sur des endpoints dedies par domaine pour les listes (`/activities`, `/flights`, etc.). Les mutations vont vers `PATCH /v1/trips/{id}` (metadonnees), `PATCH /v1/trips/{id}/status` (transitions), `DELETE /v1/trips/{id}`.

Cote mobile, la page est une route nommee `TripRoute(tripId)` rendue par `TripDetailPage` qui injecte un `BlocProvider<TripDetailBloc>` local detruit a la sortie. La structure visuelle est un layout "wizard mirror" : hero dark en haut, barre de pills horizontale au milieu, `TabBarView` plein ecran en bas. Chaque pill correspond a un panel autonome qui consomme le state du bloc partage et dispatch ses propres events.

## Cote Backend

### Endpoints CRUD trip

| Methode | Path | Acces | Description |
|---------|------|-------|-------------|
| `GET` | `/v1/trips/{id}` | OWNER + EDITOR + VIEWER | Detail trip + flightOrder Amadeus + role + completionPercentage |
| `GET` | `/v1/trips/{id}/home` | OWNER + EDITOR + VIEWER | Stats agreges (baggageCount, totalExpenses, daysUntilTrip, tripDuration), feature tiles, section summaries |
| `PATCH` | `/v1/trips/{id}` | OWNER only | Update metadonnees (title, dates, destination, nbTravelers, budgetTarget, coverImageUrl, dateMode) |
| `PATCH` | `/v1/trips/{id}/status` | OWNER only | Transition de statut avec validation des prerequis |
| `PATCH` | `/v1/trips/{id}/tracking` | OWNER only | Bascule `flights_tracking` / `accommodations_tracking` entre `TRACKED` et `SKIPPED` |
| `DELETE` | `/v1/trips/{id}` | OWNER only | Suppression du trip (204) |
| `GET` | `/v1/trips/{id}/weather` | OWNER + EDITOR + VIEWER | Meteo destination (resolution coords via Amadeus + Open-Meteo) |
| `GET` | `/v1/trips/{id}/completion-debug` | OWNER only, prod desactive | Debug per-segment de la formule de completion |

L'autorisation est centralisee dans `src/api/auth/trip_access.py` :

- `get_trip_access` → lecture (les trois roles).
- `get_trip_owner_access` → ecriture trip-level (OWNER only).
- `get_trip_editor_access` → ecriture domaine (OWNER + EDITOR) utilisee par les endpoints domaine.

Un trip auquel l'utilisateur n'a aucun lien retourne **404** plutot que 403 pour ne pas leaker son existence.

### Transitions de statut

```python
VALID_TRANSITIONS = {
    "DRAFT":   ["PLANNED"],
    "PLANNED": ["ONGOING"],
    "ONGOING": ["COMPLETED"],
}
```

La transition `DRAFT → PLANNED` valide en sus que `destination_iata` ou `destination_name` est present, que `start_date` et `end_date` sont definies, et que `start_date <= end_date`. Toute violation renvoie `400 TRIP_INCOMPLETE` ou `400 INVALID_DATES`. La transition `ONGOING → COMPLETED` declenche une notification bulk `TRIP_ENDED` a tous les participants avec deep link vers le feedback.

### Calcul de completion

Implemente dans `TripsService.compute_completion_batch()`. Quatre segments (flights, accommodations, activities, baggage), chacun cote sur 0-100, moyenne arithmetique pour le score global :

- **flights** : `100` si `flights_tracking == SKIPPED`, sinon `validated_count / total_count`.
- **accommodations** : meme regle gatee par `accommodations_tracking`.
- **activities** : `validated_count / total_count`.
- **baggage** : `packed_count / total_count`.

`VALIDATED` et `MANUAL` comptent comme done ; `SUGGESTED` reste en attente. Si un domaine n'a aucun item, son segment vaut 0 (sauf SKIPPED). Le batch est appele depuis toutes les routes qui retournent un `TripResponse` (`_enrich_with_completion`).

### Get trip home

`GET /v1/trips/{id}/home` retourne en plus du trip et de son role :

- `stats` : `baggageCount`, `totalExpenses` (somme `budget_items` via `BudgetItemService.get_budget_summary`, masquee a 0 pour les VIEWERS), `nbTravelers`, `daysUntilTrip`, `tripDuration`.
- `features` : liste de tiles avec `id`, `label`, `icon`, `route`, `enabled` (baggage / budget / accommodation / activities / transport / map).
- `sections` : par section (`transports`, `accommodations`, `activities`, `baggage`, `budget`), `count` + `previewItems` (3 premiers labels).

Cet endpoint est aujourd'hui consomme par la home globale, pas par `TripDetailBloc` (cf. section "Ce qu'il manque").

## Cote Mobile

### TripDetailBloc — state partage

Le state `TripDetailLoaded` (`bagtrip/lib/trip_detail/bloc/trip_detail_state.dart`) porte le snapshot complet :

```dart
Trip trip;
List<Activity> activities;
List<ManualFlight> flights;
List<Accommodation> accommodations;
List<BaggageItem> baggageItems;
BudgetSummary? budgetSummary;
List<BudgetItem> budgetItems;
List<TripShare> shares;
CompletionResult completionResult;
String userRole;          // OWNER / EDITOR / VIEWER
bool deferredLoaded;
AppError? operationError; // erreur transitoire pour snackbar
Map<String, AppError> sectionErrors; // erreurs par section pour retry cible
```

Plus de l'etat UI : `selectedDayIndex`, `collapsedSections`, `suggestingForDay`, `daySuggestions`, `validationError`. Les getters derives (`isViewer`, `isOwner`, `isEditor`, `canEdit`, `isCompleted`, `isOngoing`, `totalDays`, `daysUntilTrip`, `currentDay`, `baggagePackedCount`) vivent sur le state pour eviter la duplication dans les panels.

### Handlers par domaine

Le BLoC principal (`trip_detail_bloc.dart`) declare la table de dispatch et les handlers de lifecycle. Le reste est eclate en cinq `part files` qui sont des extensions privees sur `TripDetailBloc` (acces aux champs prives et au state partage) :

| Part file | Domaines couverts |
|-----------|-------------------|
| `trip_detail_trip_handlers.dart` | UpdateTripStatus, UpdateTripTitle, UpdateTripDates, UpdateTripTravelers, UpdateTripTracking, DeleteTrip |
| `trip_detail_activity_handlers.dart` | ValidateActivity, RejectActivity, BatchValidate, UpdateActivity, MoveActivityToDay, SuggestActivitiesForDay, ClearDaySuggestions, CreateActivity |
| `trip_detail_transport_handlers.dart` | AddFlight, CreateFlight, UpdateFlight, DeleteFlight, ValidateFlight, ReplaceFlight + meme set pour Accommodation |
| `trip_detail_baggage_handlers.dart` | ToggleBaggagePacked, CreateBaggageItem, UpdateBaggageItem, DeleteBaggageItem |
| `trip_detail_budget_handlers.dart` | CreateBudgetItem, UpdateBudgetItem, DeleteBudgetItem, ValidateBudgetItem, RefreshBudgetSummary |
| `trip_detail_misc_handlers.dart` | CreateShare, DeleteShare |

Pour ajouter un nouvel event : entree dans la table de dispatch du fichier principal + handler dans le part file du domaine concerne. Les handlers utilisent l'API `Result<T>` exclusivement (pattern matching `switch` sur `Success` / `Failure`, pas de cast), et tout `Failure` finit dans `operationError` pour declencher un snackbar via le `BlocConsumer` du Scaffold.

### Events (33 events)

| Categorie | Events |
|-----------|--------|
| Lifecycle | `LoadTripDetail`, `RefreshTripDetail`, `LoadDeferredSections`, `RetryDeferredSection`, `SelectDay`, `ToggleSection` |
| Trip metadata | `UpdateTripStatus`, `UpdateTripTitle`, `UpdateTripDates`, `UpdateTripTravelers`, `UpdateTripTrackingFromDetail`, `DeleteTripDetail` |
| Activites | `ValidateActivity`, `RejectActivity`, `BatchValidateActivitiesFromDetail`, `UpdateActivityFromDetail`, `MoveActivityToDay`, `SuggestActivitiesForDay`, `ClearDaySuggestions`, `CreateActivityFromDetail` |
| Vols | `AddFlightToDetail`, `CreateFlightFromDetail`, `UpdateFlightFromDetail`, `DeleteFlightFromDetail`, `ValidateFlightFromDetail`, `ReplaceFlightFromDetail` |
| Hebergements | `CreateAccommodationFromDetail`, `UpdateAccommodationFromDetail`, `DeleteAccommodationFromDetail`, `ValidateAccommodationFromDetail`, `ReplaceAccommodationFromDetail` |
| Bagages | `ToggleBaggagePackedFromDetail`, `CreateBaggageItemFromDetail`, `UpdateBaggageItemFromDetail`, `DeleteBaggageItemFromDetail` |
| Budget | `CreateBudgetItemFromDetail`, `UpdateBudgetItemFromDetail`, `DeleteBudgetItemFromDetail`, `ValidateBudgetItemFromDetail`, `RefreshBudgetSummaryFromDetail` |
| Partage | `CreateShareFromDetail`, `DeleteShareFromDetail` |

### Chargement en deux temps

Le BLoC fait un chargement Tier 1 puis Tier 2 pour afficher le hero + le board de validation au plus vite et hydrater le reste en arriere-plan :

1. **Tier 1 — `_fetchCore`** : `getTripById` + `getActivities` en parallele. Emet `TripDetailLoaded` avec listes vides pour les autres domaines, puis schedule `LoadDeferredSections` apres 100 ms.
2. **Tier 2 — `_onLoadDeferredSections`** : 6 appels parallele (manual flights, accommodations, baggage, budget summary, budget items, shares). Chaque echec est capture individuellement dans `sectionErrors[<section>]` pour permettre un retry cible via `RetryDeferredSection`.

`RefreshTripDetail` (pull-to-refresh) fait un fetch complet des 8 endpoints en parallele en preservant le `selectedDayIndex` et les sections collapsed.

### Panels par domaine (TabBarView)

La vue (`trip_detail_view.dart`) est un `Column` avec :

- `ReviewHero` en haut (cover image, ville, date subtitle, badge statut, overflow menu, anneau de completion).
- `PanelChipsBar` (pills cliquables avec indicateur "incomplete" par domaine, drives un `TabController`).
- `TabBarView` avec 6 ou 7 onglets selon le role :

| Onglet | Panel | Rendu principal |
|--------|-------|-----------------|
| 0 | `ValidationBoardPanel` | Score global + une ligne par domaine avec etat (skipped / nothing / N restants / all done) + tap → jump to tab |
| 1 | `FlightsPanel` | Cards de vol (BoardingPassCard), QuickPreviewSheet pour validate/edit/replace/delete, FAB add, gere `flightsTracking=SKIPPED` |
| 2 | `HotelPanel` | Cards d'hebergement, meme grille d'actions, gere `accommodationsTracking=SKIPPED` |
| 3 | `ActivitiesPanel` | Timeline jour par jour, day chip row, drag & drop entre jours, suggestions IA inline |
| 4 | `EssentialsPanel` | Liste bagages groupee par categorie, ProgressStrip, tap toggle packed, swipe-to-delete |
| 5 | `BudgetPanel` | BudgetStripe summary, alert banner, liste recente d'expenses, QuickPreview |
| 6 | `SharesPanel` (OWNER only) | Liste invitations, invite sheet, revoke avec context menu |

Le footer global n'apparait que pour les voyages `COMPLETED` (CTA "Give a review" vers `FeedbackRoute`). Chaque panel embarque son propre FAB et ses sheets — il n'y a plus de boutons d'action centralises sous la liste.

Les quatre briques partagees imposees par le refactor SMP-324 que tous les panels consomment :

- `ItemStatusChip` (`lib/design/widgets/item_status_chip.dart`) — chip qui rend `validation_status` (SUGGESTED / VALIDATED / MANUAL) avec a11y semantics. Source unique pour le rendu visuel du statut.
- `ItemFormScaffold` + helper `showItemFormSheet` — chrome standardise pour tout formulaire d'edition d'item (drag handle, keyboard padding, top radius, header avec status chip). Le form ne ship que ses fields propres.
- `QuickPreviewSheet` (`lib/design/widgets/review/sheets/quick_preview_sheet.dart`) — sheet d'apercu d'un item avec slots `validateAction` (priorise Validate en CTA primaire quand SUGGESTED), `primaryAction` (Edit / Replace), `secondaryAction`, `destructiveAction`, `openFullLabel`.
- `ReplaceSearchSheet` + helper `showReplaceSearchSheet` — sheet plein-ecran 95% pour wrap n'importe quel flow search-and-replace (vols, hotels), tap-outside dismiss desactive pour preserver le state mid-search.

Cote bloc, l'extension `validate(...)` (`lib/repositories/validation_extensions.dart`) sur les repositories activity / transport / accommodation / budget envoie un payload unique `{validationStatus: VALIDATED}` ; les handlers passent toujours par cette extension, jamais par un `updateXxx` direct.

### Completion compute cote mobile

`bagtrip/lib/trip_detail/helpers/trip_detail_completion.dart` expose `tripDetailCompletion()` qui retourne un `CompletionResult` avec 4 segments enumeres dans `CompletionSegmentType` (flights / accommodation / activities / baggage). La formule mirroite celle du backend pour pouvoir afficher le score sans re-fetch apres chaque mutation optimiste : chaque handler qui touche une liste recalcule `completionResult` sur le snapshot mis a jour.

L'anneau (`CompletionRing`) dans le hero est tappable et ouvre une bottom sheet listant les segments incomplets pour jump vers l'onglet correspondant. Le ValidationBoardPanel ajoute un cinquieme rang "Budget" synthese depuis `budgetItems` (counted localement, pas inclus dans le pourcentage global pour eviter qu'un budget tracke a 100% gonfle artificiellement le score).

### Optimistic updates + rollback

Toutes les mutations suivent le meme pattern, derive de `Result<T>` + `AppError` :

1. Capturer le `loaded` actuel (snapshot pre-mutation).
2. Calculer le nouvel etat localement (validate flip un `validationStatus`, delete retire l'item, move recompute la date).
3. Recalculer `completionResult` sur le nouvel etat si la mutation impacte un segment.
4. `emit()` immediat → l'UI bouge avant le reseau.
5. Appel repository (`Future<Result<T>>`).
6. Si `Failure(error)` → `emit(loaded.copyWith(operationError: error))` puis `emit(loaded.copyWith(clearOperationError: true))`. Le `BlocConsumer` du Scaffold attrape `operationError` et affiche un snackbar via `toUserFriendlyMessage(error, l10n)`.

Cas particuliers :

- **ReplaceFlight / ReplaceAccommodation** : operation atomique DELETE puis CREATE. Si le CREATE echoue apres un DELETE reussi, le snapshot original est restaure pour eviter de laisser l'utilisateur sur un etat semi-applique.
- **UpdateActivity / UpdateBudgetItem** : pas d'optimistic update, l'appel API precede l'emit puisque la mutation modifie potentiellement plusieurs champs (le serveur renvoie la version canonique).
- **BatchValidate** : flip optimiste sur N activites en une emit, rollback total via `loaded` si l'appel batch echoue.
- **DeleteTrip** : pas de rollback, le success emet `TripDetailDeleted` qui declenche `HomeRoute().go(context)` + refresh des listes home/management.

## Roles et permissions

| Capacite | OWNER | EDITOR | VIEWER |
|----------|-------|--------|--------|
| Lire trip + sections | oui | oui | oui |
| Modifier metadonnees (title, dates, travelers, tracking) | oui | non | non |
| Transition de statut (DRAFT → PLANNED → ONGOING → COMPLETED) | oui | non | non |
| Supprimer le trip | oui | non | non |
| CRUD activites / vols / hebergements / bagages / budget | oui | oui | non |
| Validate (flip SUGGESTED → VALIDATED) | oui | oui | non |
| Inviter / revoquer un partage | oui | non | non |
| Voir l'onglet Shares | oui | non | non |
| Voir l'anneau de completion + board de validation | oui | oui | oui (read-only) |
| Donner un feedback post-voyage | oui | oui | oui (selon plan premium) |

Cote Flutter, le getter `canEdit = (isOwner || isEditor) && !isCompleted` est la source unique consultee par les panels pour gater FABs, swipe-to-delete et context menus. Le hero affiche un badge "Read only" pour les viewers et "Trip complete" pour les voyages termines.

## Map

La vue carte n'est volontairement pas integree au TripDetail principal. Elle vit dans une route dediee `TripLocationsPage` (`bagtrip/lib/trips/view/trip_locations_page.dart`) pilotee par un `TripLocationsCubit` local (`bagtrip/lib/trips/cubit/trip_locations_cubit.dart`).

Le cubit charge en parallele `getTripById`, `getActivities` et `getByTrip` (accommodations), puis emet un seul `TripLocationsLoaded` avec les trois listes. La vue filtre les activites avec `location` non vide et les hebergements avec `address` non vide, puis rend une liste a deux sections (destination + activites + hebergements). Chaque tile lance la navigation native via `launchMapNavigation()` (URI scheme Apple Maps / Google Maps selon plateforme). Pas de carte interactive embarquee a ce stade : on delegue au systeme.

Si aucune adresse n'est exploitable, `ElegantEmptyState` avec icone `map_outlined` et message `mapNoLocations`.

## Flux

### Ouverture de la page

1. `TripRoute(tripId).go(context)` → `TripDetailPage` cree `BlocProvider<TripDetailBloc>` local + fire `LoadTripDetail(tripId)`.
2. Tier 1 fetch (trip + activities) → `TripDetailLoaded` emis avec listes vides ailleurs.
3. Apres 100 ms, `LoadDeferredSections` charge les 6 sections restantes en parallele.
4. Le hero affiche le badge statut, le score de completion bouge des que le Tier 2 atterrit, les panels remplacent leurs shimmers par leur contenu.

### Edition d'une metadonnee

1. Tap sur l'overflow du hero → bottom sheet `HeroOverflowMenu` (Edit title, Edit travelers, Share, Mark as ready/completed, Give review, Delete trip).
2. Selection d'une action → bottom sheet edit (title / travelers / dates) ou dialog destructif (delete) ou direct event (status transitions).
3. Bloc fait optimistic update + appel API.
4. Si validation backend echoue (ex: `DRAFT → PLANNED` avec dates manquantes), l'UI affiche un dialog `cannotFinalizeTitle` listant les champs manquants avant meme de fire l'event.

### Validation d'un item suggere

1. User tape sur une card SUGGESTED (vol / hebergement / activite / budget item).
2. `QuickPreviewSheet` s'ouvre avec en CTA primaire "Validate" (auto-promote des que `validationStatus == suggested`).
3. Tap → dispatch `ValidateXxxFromDetail(itemId)` → optimistic flip vers VALIDATED + recompute completionResult + ferme la sheet.
4. Repo appelle `PATCH /v1/trips/{id}/<domain>/{itemId}` avec `{validationStatus: VALIDATED}` via l'extension `validate(...)` (`lib/repositories/validation_extensions.dart`).
5. Si echec → rollback snapshot + snackbar.

### Suppression du trip

1. Overflow menu → "Delete trip" → dialog destructif `tripDeleteConfirm`.
2. Confirm → `DeleteTripDetail` → `DELETE /v1/trips/{id}` (204).
3. Sur success → `TripDetailDeleted` → listener navigue vers `HomeRoute`, fire `RefreshHome` + `LoadTripsByStatus` x3.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Endpoint `GET /{id}/home` non consomme cote Flutter | `TripHomeResponse` expose stats / features / sections agreges cote backend, mais le BLoC reconstruit tout depuis 8 appels separes. Si on l'adoptait, on economiserait 4 round-trips au cold start. | P2 |
| Map sans carte embarquee | `TripLocationsPage` se contente d'une liste qui delegue au systeme. Une vue Mapbox / Google Maps integree avec markers categorises serait l'experience attendue. | P1 |
| Pas d'editor en pratique cote UI | Le role `EDITOR` est supporte cote API (`get_trip_editor_access`) et cote state (`isEditor`, `canEdit`) mais l'invite sheet (`shares_panel`) propose uniquement `VIEWER`. Tester et exposer le toggle EDITOR pour les invitations. | P1 |
| Budget non integre au score global | Le segment Budget est synthese dans le ValidationBoardPanel mais n'entre pas dans `compute_completion_batch`. Le note "Budget exclu" est explicite mais cree un decrochage entre ce que le board affiche et ce que l'anneau totalise. Decider : soit l'integrer, soit retirer la ligne du board. | P2 |
| Section Map dans le hub | Aucun onglet Map dans le TabBarView. L'acces a la carte passe par l'overflow menu / la route directe. Un septieme panel ou un raccourci depuis le ValidationBoard donnerait une porte d'entree plus claire. | P2 |
| FlightOrder Amadeus non affiche | `TripDetailResponse.flightOrder` (id, amadeusFlightOrderId, status) est retourne par l'API mais aucun panel ne le rend. La carte de vol pourrait afficher le statut de reservation (CONFIRMED / PENDING / CANCELLED). | P2 |
| Pas de cache offline pour les mutations | Les optimistic updates ne sont pas persistes localement. Si l'app est tuee pendant un rollback en attente, la mutation est perdue. Brancher `OfflineWriteQueue` sur les handlers principaux. | P2 |
| Tests widget panel-level minces | `trip_detail_bloc_test.dart` couvre bien la logique, mais les panels (validation board, drag & drop activites, quick preview sheets) ne sont pas testes en widget. | P2 |
| Pas de retry UI pour `sectionErrors` | Le state expose `sectionErrors` et le BLoC supporte `RetryDeferredSection`, mais aucune banniere de panel ne propose le retry visible. Une bandeau "Cette section n'a pas pu charger — Reessayer" par panel manquant. | P1 |
| Pas de differentiel sur les transitions automatiques | Les transitions auto (`auto_transition_statuses` PLANNED→ONGOING, ONGOING→COMPLETED) ne pushent aucune notification au client. L'app voit le nouveau statut uniquement au prochain refresh, sans signal sonore / banner. | P2 |
