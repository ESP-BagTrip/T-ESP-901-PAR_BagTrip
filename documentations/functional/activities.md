# Activites

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

Le module Activites est le coeur du programme d'un voyage BagTrip. Une activite represente un point au planning (visite, repas, sport, transport interne) rattache a un trip, optionnellement date et horodate. Chaque activite porte un `validation_status` qui dicte sa lecture visuelle et son cycle de vie :

- `SUGGESTED` : produite par l'agent LLM (plan trip ou suggestions ciblees), en attente de revue.
- `VALIDATED` : confirmee par l'utilisateur d'un geste (CTA, swipe).
- `MANUAL` : creee directement par l'utilisateur via le formulaire.

Le backend FastAPI expose un CRUD complet plus un endpoint de suggestions IA jour-par-jour et un batch update. Cote mobile, les activites sont consommees par le panel `ActivitiesPanel` (sous-onglet de `TripDetailPage`) qui propose trois modes d'affichage (timeline jour-par-jour, liste chronologique, regroupement par categorie) et trois primitives partagees du design system SMP-324 : `ItemStatusChip`, `ItemFormScaffold` et `QuickPreviewSheet`. Les viewers en lecture seule voient les activites sans le champ `estimatedCost` (redacte cote API).

## Cote Backend

### Routes (`api/src/api/activities/routes.py`)

| Methode | Endpoint | Description | Acces |
|---------|----------|-------------|-------|
| `POST` | `/v1/trips/{tripId}/activities` | Cree une activite | Editor |
| `GET` | `/v1/trips/{tripId}/activities` | Liste paginee | Owner + Viewer |
| `GET` | `/v1/trips/{tripId}/activities/{activityId}` | Detail | Owner + Viewer |
| `PATCH` | `/v1/trips/{tripId}/activities/{activityId}` | Update partiel | Editor |
| `DELETE` | `/v1/trips/{tripId}/activities/{activityId}` | Suppression | Editor |
| `PATCH` | `/v1/trips/{tripId}/activities/batch` | Update partiel groupe | Editor |
| `POST` | `/v1/trips/{tripId}/activities/suggest` | Suggestions IA (quota) | Editor |

Toutes les routes passent par les dependencies `get_trip_access` (lecture) ou `get_trip_editor_access` (ecriture). Le mapping HTTP cible 201 (create), 204 (delete) et 200 sur le reste. L'ancien handler `PUT` a ete supprime : `PATCH` couvre les memes besoins puisque `ActivityUpdateRequest` a tous ses champs optionnels.

### Schemas (`api/src/api/activities/schemas.py`)

- `ActivityCreateRequest` : `title` et `date` requis, tout le reste optionnel. Validateur `model_validator` qui rejette `endTime <= startTime`.
- `ActivityUpdateRequest` : tous les champs optionnels, meme validateur horaire.
- `ActivityResponse` : alias snake_case -> camelCase (`trip_id` -> `tripId`, `start_time` -> `startTime`, `validation_status` -> `validationStatus`, etc.), `model_config = ConfigDict(from_attributes=True, populate_by_name=True)`.
- `ActivityPaginatedResponse` : `items`, `total`, `page`, `limit`, `totalPages`.
- `ActivityBatchUpdateRequest` : `activityIds: list[UUID]` + `updates: ActivityUpdateRequest` (meme delta applique a chaque id).
- `ActivitySuggestResponse` : `activities: list[dict]` (forme libre, mappee cote mobile).

### Service (`api/src/services/activity_service.py`)

`ActivityService` est un staticmethod-only :

- `create / update / delete / batch_update` commencent tous par `_check_trip_not_completed(trip)` qui leve `AppError("TRIP_COMPLETED", 403)` si le voyage est `COMPLETED`. Aucune mutation possible sur un trip cloture.
- `get_by_trip_paginated` : tri `asc(date), asc(start_time)`, `total_pages` via `math.ceil`.
- `batch_update` : itere sur les ids, applique le meme delta partiel, un seul `db.commit()` puis `db.refresh()` sur chaque resultat. Pas encore wrap dans `unit_of_work` (cf. "Ce qu'il manque").
- `suggest` : construit un prompt localisable (labels EN/FR pour destination, duree, voyageurs, jour cible), appelle `LLMService.acall_llm(render("activity_planner", locale=...), user_prompt)`, retourne `result["activities"]`. En cas d'echec LLM, log + retour liste vide (jamais d'exception qui remonte).

### Modele ORM (`api/src/models/activity.py`)

Table `activities` :

- `id` UUID PK, `trip_id` UUID FK indexed.
- `title` (NOT NULL), `description` nullable.
- `date` **nullable** depuis SMP-324 : les recommandations IA recurrentes (repas, transports internes) sont persistees sans jour calendaire et surfacees dans un bucket "Unscheduled" dedie.
- `start_time` / `end_time` nullables.
- `category` String default `"OTHER"` (jamais de FK enum cote DB pour faciliter les evolutions).
- `estimated_cost` Numeric(12,2) nullable.
- `is_booked`, `is_done` boolean default false.
- `validation_status` String default `"MANUAL"` (server_default identique).
- `created_at`, `updated_at` timestamps timezone-aware.

### Validation status et redaction viewer

La route `list_activities` reserialise les items et force `item.estimatedCost = None` lorsque `access.role == TripRole.VIEWER`. Meme regle dans `get_activity`. Les viewers voient titre, description, lieu, horaires, statut, mais jamais le cout estime.

## Cote Mobile

### Panel principal (`bagtrip/lib/trip_detail/view/panels/activities_panel.dart`)

`ActivitiesPanel` est rendu par `TripDetailPage` lorsque l'onglet "Activites" est selectionne. Il prend en entree la liste deja chargee par `TripDetailBloc` (jamais de fetch direct dans le panel) :

- `activities`, `tripStartDate`, `totalDays`, `selectedDayIndex`, `canEdit`, `isCompleted`, `role`.
- `canEdit` est calcule en amont a partir du role et du statut du trip.

Le panel embarque un `BlocProvider<ActivitiesViewCubit>` local qui gere l'etat de la vue (mode courant + filtres). Le cubit n'est jamais elevage au-dessus du panel : changer d'onglet remet la vue par defaut.

### Modes d'affichage (`activities_view_mode.dart`)

Trois modes selectionnables par un `_ViewModePicker` segmente :

- **Timeline** : selecteur horizontal "J1, J2, ..." derive de `tripStartDate + index`, affiche les activites du jour selectionne, puis un bucket "Unscheduled" pour les items sans date. Tap sur "Jn" dispatch `SelectDay` sur le `TripDetailBloc` (etat partage avec les autres panels).
- **List** : liste plate chronologique (`date` asc puis `startTime` asc), unscheduled en bas.
- **Category** : regroupement par `ActivityCategory`, sections vides masquees, items tries par date dans chaque bucket.

### Filtres (`activities_view_state.dart`)

`_FilterBar` propose un filtre single-choice sur `validationStatus` (All / Suggested / Validated / Manual) et un sheet de filtres multi-choix sur les categories (`_CategoryFilterSheet`). Le badge "Clear" n'apparait que si au moins un filtre est actif. Quand le filtrage reduit la liste a zero, `_FilterEmptyState` distingue ce cas du vrai etat vide pour ne pas suggerer que le voyage n'a pas de contenu.

### Status chip (`bagtrip/lib/design/widgets/item_status_chip.dart`)

`ItemStatusChip` est la single source of truth pour `validation_status` partagee avec vols, hotels et budget. Trois variantes :

- `suggested` : halo dore (`#FFF4D6` / `#8A6300`), icone `auto_awesome`, signale qu'un humain doit revoir le row.
- `validated` : vert succes, icone `check_circle`.
- `manual` : gris neutre (`AppColors.surfaceVariant`), icone `edit_note`.

Modes `compact: true` (icone seule pour les card headers denses) et `compact: false` (icone + label localise pour les sheets). Adapter `ItemStatusChip.fromBackend(raw)` mappe la string backend, fallback `manual` sur unknown.

### Quick preview (`quick_preview_sheet.dart`)

`showQuickPreviewSheet(...)` est ouvert au tap sur une activite. Le sheet contient :

- Header : icone `event_note_rounded`, titre (titre activite), subtitle (label categorie en majuscules).
- Body : `_ActivityPreviewBody` (date formatee `yMMMMEEEEd`, horaires, lieu, description, badge `SUGGERE` quand applicable).
- Actions slots : `primaryAction`, `secondaryAction`, `destructiveAction`, `validateAction`. Le sheet promeut automatiquement `validateAction` en slot primaire quand il est fourni, faisant glisser l'ancien `primaryAction` (Edit) en secondaire. Cote panel, la logique est inversee a la main : si `isSuggested && canEdit`, primary = Validate et secondary = Edit ; sinon primary = Edit.

### Formulaire (`activity_form.dart`)

`ActivityForm` est wrappe par `ItemFormScaffold` (chrome standard SMP-324 : drag handle, padding clavier, header avec `ItemStatusChip` du statut courant, slot actions). Helper d'ouverture : `showItemFormSheet`. Champs :

- `title` requis (validator inline).
- `date` (showAdaptiveDatePicker), `startTime` / `endTime` (showAdaptiveTimePicker).
- `description`, `location`, `estimatedCost` optionnels.
- `category` : `FormChoiceChips<ActivityCategory>` avec `cat.icon` / `cat.color` / `cat.label(l10n)` issus de l'extension `ActivityCategoryPresentation`.
- `isBooked` checkbox.

A la soumission, validation horaire client (`endTime > startTime`, sinon `AppSnackBar.showError`), `validationStatus: 'MANUAL'` force sur creation manuelle, payload camelCase pousse vers le bloc parent via `onSave(data)`. Le bloc pop le sheet et dispatch `CreateActivityFromDetail` ou `UpdateActivityFromDetail` sur `TripDetailBloc`.

### Repository (`bagtrip/lib/repositories/activity_repository.dart`)

Interface : `getActivities`, `getActivitiesPaginated`, `createActivity`, `updateActivity`, `deleteActivity`, `suggestActivities`, `batchUpdateActivities`. Chaque methode retourne `Future<Result<T>>`. Extension `ActivityValidation.validate(tripId, activityId)` dans `validation_extensions.dart` : alias de `updateActivity` avec le payload constant `{validationStatus: 'VALIDATED'}` partage entre activites, vols, hotels et budget.

### Geste swipe et hints

`_ActivityRow` wrap la `ActivityPanelCard` dans un `Dismissible` quand `canEdit == true`. La direction depend du statut :

- `SUGGESTED` : `DismissDirection.horizontal` (gauche = valider, droite = supprimer).
- autres : `DismissDirection.endToStart` (uniquement supprimer).

Les backgrounds gauche/droit (`_SwipeActionBackground`) affichent l'icone d'action sur fond couleur (`secondary` pour valider, `error` pour supprimer). En bas de liste, `_ActivitiesGestureHint` rappelle les gestes disponibles (texte adapte selon presence ou non de suggestions).

### Carte panneau (`ActivityPanelCard`)

La card affiche titre, description tronquee, label categorie en majuscules, time label compose (`startTime — endTime` ou `startTime` seul), localisation, et `ItemStatusChip(kind: ..., compact: true)` quand le statut est suggested ou validated. Le tap sur la card delegue au `onTap` du panel (`_showPreview`).

## Categories

L'enum `ActivityCategory` est aligne mobile (Freezed `@JsonValue`) et backend (`src/enums.py` StrEnum). La presentation visuelle vit dans `ActivityCategoryPresentation` (extension sur l'enum) :

| Enum | Icone Material | Couleur token | Label l10n |
|------|----------------|---------------|------------|
| `culture` | `museum_outlined` | `AppColors.activityCulture` (`#5C6BC0`) | `categoryCulture` |
| `nature` | `park_outlined` | `AppColors.activityNature` (`#66BB6A`) | `categoryNature` |
| `food` | `restaurant_outlined` | `AppColors.activityFood` (`#FF7043`) | `categoryFoodDrink` |
| `sport` | `fitness_center_outlined` | `AppColors.activitySport` (`#42A5F5`) | `categorySport` |
| `shopping` | `shopping_bag_outlined` | `AppColors.activityShopping` (`#AB47BC`) | `categoryShopping` |
| `nightlife` | `nightlife_outlined` | `AppColors.activityNightlife` (`#7E57C2`) | `categoryNightlife` |
| `relaxation` | `spa_outlined` | `AppColors.activityRelaxation` (`#26A69A`) | `categoryRelaxation` |
| `transport` | `directions_transit_outlined` | `AppColors.budgetTransport` | `reviewBudgetTransport` |
| `other` | `event_outlined` | `AppColors.secondary` | `categoryOtherActivity` |

Toute UI qui rend une activite (card panel, form, preview body, filter sheet) tape sur cette extension. Pas de switch local, pas de hexadecimal en dur dans les widgets.

## Flux

### Suggestions IA

1. L'utilisateur fire l'action depuis l'UI (button "Suggestions IA").
2. Le bloc parent appelle `activityRepository.suggestActivities(tripId, day: dayNumber?)`.
3. La route `POST /suggest` exige `get_trip_editor_access` + `require_ai_quota` (gating premium).
4. `ActivityService.suggest` resout la locale (header `Accept-Language` via `normalize_locale`), construit un prompt localise, appelle `LLMService.acall_llm(render("activity_planner", locale=...), user_prompt)`.
5. Le quota IA est incremente via `PlanService.increment_ai_generation` apres succes.
6. Les suggestions retournees (forme libre) sont rendues cote mobile, l'utilisateur peut convertir une suggestion en activite reelle via le flux create classique (`validationStatus: 'SUGGESTED'`).

### Edition

1. Tap sur une activite -> `showQuickPreviewSheet`.
2. Tap sur le bouton Edit -> `Navigator.pop` du preview puis `showItemFormSheet(child: ActivityForm(activity: ..., onSave: ...))`.
3. `ActivityForm` capture les valeurs, valide cote client, fire `onSave(data)`.
4. Le panel dispatch `UpdateActivityFromDetail(activityId, data)` sur `TripDetailBloc`.
5. Le handler bloc appelle `activityRepository.updateActivity` (PATCH partial), recompute `completionResult` sur le snapshot complet du trip.

### Validation

Trois entry points :
- CTA "Valider" du `QuickPreviewSheet` (slot `primaryAction` promu en haut quand SUGGESTED).
- Swipe `startToEnd` sur le `_ActivityRow` (uniquement si `isSuggested`, haptic success, geste non-destructif retourne `false` au `confirmDismiss`).
- Boutons de revue dans le `validation_board_panel.dart` (panel dedie de revue groupee).

Toutes ces actions dispatchent `ValidateActivity(activityId)` sur `TripDetailBloc`. Le handler appelle `ActivityRepository.validate(tripId, activityId)` (extension qui PATCH `{validationStatus: 'VALIDATED'}`).

### Suppression

Deux entry points :
- Action destructive du `QuickPreviewSheet`.
- Swipe `endToStart` sur le `_ActivityRow` (`confirmDismiss` retourne `true`, haptic medium, `onDismissed` appelle `onDelete`).

Les deux dispatchent `RejectActivity(activityId)` sur `TripDetailBloc` qui appelle `activityRepository.deleteActivity` (DELETE 204). Pas de dialogue de confirmation (le swipe fait office d'undo implicite via le pattern Dismissible).

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| `unit_of_work` sur `batch_update` | `ActivityService.batch_update` commit en une fois mais sans wrap `with unit_of_work(db)` : si un `get_by_id` leve `ACTIVITY_NOT_FOUND` au milieu, les activites deja mutees en memoire ne sont pas rollback proprement (`api/src/services/activity_service.py` l.170) | P1 |
| Endpoint suggest renvoie `list[dict]` | `ActivitySuggestResponse.activities: list[dict]` n'est pas type ni valide cote Pydantic : le contrat avec le client repose sur la convention de prompt LLM. Schema dedie a creer (`SuggestedActivity` avec `title`, `category`, `suggestedDay`, `estimatedCost`) (`api/src/api/activities/schemas.py` l.92) | P1 |
| Batch update mobile non-cable | `ActivityRepository.batchUpdateActivities` existe mais n'est appele par aucun handler du `TripDetailBloc`. La validation groupee depuis le `validation_board_panel` itere encore au lieu d'utiliser l'endpoint batch (`bagtrip/lib/repositories/activity_repository.dart` l.26) | P2 |
| Tests services IA suggest | Pas de tests unitaires sur `ActivityService.suggest` (mock LLM + verification du prompt rendu en EN/FR). Le path est silencieusement degrade en cas d'erreur LLM, donc indetectable sans test (`api/src/services/activity_service.py` l.207) | P1 |
| Suggested day non-mappe cote API | Le modele Flutter `Activity` porte `suggestedDay` mais aucune route n'expose ce champ dans `ActivityResponse` (la colonne DB n'existe pas non plus). A confirmer comme dette : champ legacy a supprimer du modele mobile ou colonne a ajouter cote backend (`bagtrip/lib/models/activity.dart` l.51) | P2 |
| Pas de creation directe depuis suggestion | Le sheet de preview suggestions IA convertit une suggestion en activite via un nouveau `create`, mais il n'y a pas de bulk-add : l'utilisateur doit traiter ligne par ligne. Un endpoint `POST /activities/bulk-from-suggestions` permettrait d'eviter N round-trips (`api/src/api/activities/routes.py`) | P2 |
| Filtres non persistes | `ActivitiesViewCubit` n'est pas persiste entre changements d'onglet : revenir sur "Activites" reset les filtres et le mode. A discuter si comportement souhaite ou regression UX (`bagtrip/lib/trip_detail/bloc/activities_view_cubit.dart`) | P3 |
| `is_done` non-expose UI | La colonne `is_done` existe en DB et dans le schema mais aucune UI ne permet de marquer une activite comme realisee. Soit feature a finaliser, soit champ a deprecier (`api/src/models/activity.py` l.38) | P2 |
