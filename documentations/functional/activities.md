# Activites

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

Le module Activites permet aux utilisateurs de gerer le programme d'un voyage : creer, modifier, supprimer et valider des activites. Les activites sont rattachees a un trip, classees par categorie, et affichees groupees par jour. Un systeme de suggestions IA propose des activites contextuelles basees sur la destination, la duree du voyage et le nombre de voyageurs. Le module couvre le CRUD complet cote mobile (Flutter BLoC) et cote API (FastAPI + SQLAlchemy), avec pagination, batch updates, et gestion des roles (owner vs viewer).

## Architecture Flutter

### BLoC

Le `ActivityBloc` (`bagtrip/lib/activities/bloc/activity_bloc.dart`) orchestre 7 events :

| Event | Description |
|-------|-------------|
| `LoadActivities` | Charge la premiere page (paginee) |
| `LoadMoreActivities` | Charge la page suivante (infinite scroll) |
| `CreateActivity` | Cree une activite via le repository |
| `UpdateActivity` | Met a jour une activite existante |
| `DeleteActivity` | Supprime une activite |
| `SuggestActivities` | Declenche les suggestions IA |
| `AddSuggestedActivity` | Ajoute une suggestion IA a la liste |

Les states cles sont `ActivitiesLoaded` (avec `groupedByDay`, `currentPage`, `totalPages`, `isLoadingMore`), `ActivitySuggestionsLoaded` (preserve les activites existantes + ajoute les suggestions), et `ActivityQuotaExceeded` (declenche le paywall premium).

Le groupement par jour (`_groupByDay`) trie les activites par `startTime` au sein de chaque journee.

### Page / View

- **`ActivitiesPage`** (`bagtrip/lib/activities/view/activities_page.dart`) : cree le `BlocProvider` et fire `LoadActivities`.
- **`ActivitiesView`** (`bagtrip/lib/activities/view/activities_view.dart`) : UI avec `PaginatedList<Activity>`, groupement par sections (dates), `ElegantEmptyState` si vide.

Le role determine l'editabilite : `canEdit = role != 'VIEWER' && !isCompleted`. Le pattern FAB est respecte : `FloatingActionButton.extended` sur Android, `IconButton(CupertinoIcons.add)` dans l'AppBar sur iOS.

Un bouton `Icons.auto_awesome` dans les actions de l'AppBar declenche les suggestions IA. Si le quota est depasse, `PremiumPaywall.show()` est affiche via un `BlocListener`.

### Formulaire

`ActivityForm` (`bagtrip/lib/activities/widgets/activity_form.dart`) est un `StatefulWidget` qui gere :

- **Titre** (requis, `TextFormField` avec validation)
- **Date** (via `showAdaptiveDatePicker`)
- **Description** (optionnel)
- **Horaires** (start/end via `showAdaptiveTimePicker`)
- **Lieu** (optionnel)
- **Categorie** (selection par `ChoiceChip` avec icone et couleur par categorie)
- **Cout estime** (en euros)
- **Reserve** (checkbox `isBooked`)

Le `validationStatus` est force a `'MANUAL'` pour les creations manuelles. Le formulaire s'affiche dans une bottom sheet avec decoration standard (transparent, rounded top 20px, handle bar).

### Carte d'activite

`ActivityCard` (`bagtrip/lib/activities/widgets/activity_card.dart`) affiche :
- Icone de categorie dans un `CircleAvatar`
- Titre avec `StatusBadge` (pending pour SUGGESTED, confirmed pour VALIDATED)
- Horaires, lieu, cout
- Menu contextuel : iOS utilise `AdaptiveContextMenu`, Android utilise `PopupMenuButton`
- Actions : edit, validate (si SUGGESTED), delete
- Semantique accessible via `Semantics` avec label compose

### Suggestions IA

Quand l'utilisateur clique sur le bouton suggestions :
1. `SuggestActivities` est fire dans le bloc
2. Le bloc appelle `activityRepository.suggestActivities(tripId)`
3. L'API appelle le `LLMService` avec un prompt `ACTIVITY_PLANNER_PROMPT`
4. Les suggestions sont affichees dans une bottom sheet (`DraggableScrollableSheet` sur Android, `showCupertinoModalPopup` sur iOS)
5. Chaque suggestion affiche : titre, description, categorie, cout estime, jour suggere
6. L'utilisateur peut ajouter une suggestion via `AddSuggestedActivity` qui cree l'activite avec `validationStatus: 'SUGGESTED'`
7. La date est calculee a partir de `tripStartDate + suggestedDay - 1`

### Validation d'activite

Les activites suggerees par l'IA ont le statut `SUGGESTED`. L'utilisateur peut les valider via `_showValidateModal` qui permet de :
- Confirmer la validation (passe le statut a `VALIDATED`)
- Optionnellement ajuster le cout estime

## Categories

| Enum | Icone | Couleur |
|------|-------|---------|
| `CULTURE` | museum | #5C6BC0 |
| `NATURE` | park | #66BB6A |
| `FOOD` | restaurant | #FF7043 |
| `SPORT` | fitness_center | #42A5F5 |
| `SHOPPING` | shopping_bag | #AB47BC |
| `NIGHTLIFE` | nightlife | #7E57C2 |
| `RELAXATION` | spa | #26A69A |
| `OTHER` | event | grey |

L'enum est defini cote Flutter dans `bagtrip/lib/models/activity.dart` et cote API dans `api/src/enums.py` (StrEnum).

## Modele de donnees

### Flutter (Freezed)

Fichier : `bagtrip/lib/models/activity.dart`

Champs principaux : `id`, `tripId`, `title`, `description`, `date`, `startTime` (String?), `endTime` (String?), `location`, `category` (enum avec `@JsonKey(unknownEnumValue: ActivityCategory.other)`), `estimatedCost`, `isBooked`, `validationStatus` (enum SUGGESTED/VALIDATED/MANUAL), `suggestedDay`, `createdAt`, `updatedAt`.

### API (SQLAlchemy)

Le modele `Activity` est dans `api/src/models/activity.py`. Les champs mappent directement avec snake_case cote DB et camelCase cote schema Pydantic (via `Field(alias=...)`).

## API Backend

### Routes (`api/src/api/activities/routes.py`)

| Methode | Endpoint | Description | Acces |
|---------|----------|-------------|-------|
| `POST` | `/v1/trips/{tripId}/activities` | Creer une activite | Owner |
| `GET` | `/v1/trips/{tripId}/activities` | Liste paginee | Owner + Viewer |
| `GET` | `/v1/trips/{tripId}/activities/{activityId}` | Detail | Owner + Viewer |
| `PUT` | `/v1/trips/{tripId}/activities/{activityId}` | Mise a jour complete | Owner |
| `PATCH` | `/v1/trips/{tripId}/activities/{activityId}` | Mise a jour partielle | Owner |
| `DELETE` | `/v1/trips/{tripId}/activities/{activityId}` | Suppression | Owner |
| `PATCH` | `/v1/trips/{tripId}/activities/batch` | Batch update | Owner |
| `POST` | `/v1/trips/{tripId}/activities/suggest` | Suggestions IA | Owner (quota IA) |

### Controle d'acces

- `get_trip_owner_access` : requis pour les operations d'ecriture (create, update, delete, suggest)
- `get_trip_access` : suffisant pour la lecture (list, get)
- Les `VIEWER` ne voient pas le champ `estimatedCost` (mis a `None` dans la reponse)

### Protection trip COMPLETED

Le service `ActivityService._check_trip_not_completed()` empeche toute modification sur un trip au statut `COMPLETED` (403).

### Suggestions IA

La route `POST /suggest` accepte un parametre optionnel `day` (1-based). Elle appelle `ActivityService.suggest()` qui :
1. Construit un prompt avec destination, duree, nombre de voyageurs, jour cible
2. Appelle le LLM via `LLMService.acall_llm(ACTIVITY_PLANNER_PROMPT, user_prompt)`
3. Retourne la liste de suggestions en JSON

Le quota IA est controle par `require_ai_quota` et incremente via `PlanService.increment_ai_generation()`.

### Schemas Pydantic

- `ActivityCreateRequest` : `title` (requis), `date` (requis), tous les autres optionnels
- `ActivityUpdateRequest` : tous les champs optionnels
- `ActivityResponse` : mapping complet avec aliases snake_case (`Config: from_attributes = True, populate_by_name = True`)
- `ActivityPaginatedResponse` : `items`, `total`, `page`, `limit`, `totalPages`
- `ActivityBatchUpdateRequest` : `activityIds` (list UUID) + `updates` (ActivityUpdateRequest)
- `ActivitySuggestResponse` : `activities` (list dict, format libre)

### Repository Flutter

Interface : `bagtrip/lib/repositories/activity_repository.dart`

Methodes : `getActivities`, `getActivitiesPaginated`, `createActivity`, `updateActivity`, `deleteActivity`, `suggestActivities`, `batchUpdateActivities`.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Validation horaire | Le formulaire ne valide pas que `endTime > startTime` — l'utilisateur peut creer une activite avec des horaires incoherents (`bagtrip/lib/activities/widgets/activity_form.dart`) | P1 |
| Suggestions IA batch add | L'utilisateur ne peut ajouter qu'une seule suggestion a la fois (la sheet se ferme apres chaque ajout). Il manque un mode multi-selection (`bagtrip/lib/activities/view/activities_view.dart` l.403) | P2 |
| Bottom sheet suggestions iOS non-standard | La bottom sheet iOS (`showCupertinoModalPopup`) n'utilise pas le pattern `backgroundColor: transparent` + handle bar standard documente dans CLAUDE.md (`bagtrip/lib/activities/view/activities_view.dart` l.231-253) | P2 |
| Batch update non-utilise cote mobile | L'endpoint `PATCH /batch` et la methode `batchUpdateActivities` du repository existent mais ne sont appeles nulle part dans le code Flutter | P2 |
| Duplication `_groupByDay` | La methode `_groupByDay` est dupliquee dans `ActivityBloc` et `ActivitiesView` — devrait etre factorisee (`bagtrip/lib/activities/bloc/activity_bloc.dart` l.28, `activities_view.dart` l.217) | P2 |
| Pas de confirmation de suppression | `onDelete` dans `ActivitiesView` fire directement `DeleteActivity` sans dialogue de confirmation (`bagtrip/lib/activities/view/activities_view.dart` l.191) | P1 |
| Tests unitaires activites | Pas de tests pour `ActivityBloc` dans le repertoire `bagtrip/test/` | P1 |
| Couleurs en dur categories | Les couleurs des categories dans `ActivityForm._categoryColor` sont en hexadecimal brut au lieu d'utiliser `AppColors.*` (`bagtrip/lib/activities/widgets/activity_form.dart` l.114-124) | P2 |
