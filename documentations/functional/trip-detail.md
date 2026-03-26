# Page de detail d'un voyage (Trip Detail)

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

La page de detail d'un voyage est la vue centrale de planification et de suivi dans BagTrip. Elle agrege toutes les informations d'un voyage unique : metadonnees (titre, dates, destination), timeline jour par jour, vols, hebergements, bagages, budget et partage. La page est geree par un `TripDetailBloc` local (cree dans `TripDetailPage`, detruit a la sortie) qui orchestre un chargement en deux temps (core puis sections differees) et un systeme d'updates optimistes avec rollback.

Cote API, les donnees proviennent de 7 endpoints distincts appeles en parallele (trip, activites, vols, hebergements, bagages, budget, partages), proteges par le systeme d'autorisation Owner/Viewer.

## Architecture BLoC

**Fichiers** : `bagtrip/lib/trip_detail/bloc/trip_detail_bloc.dart`, `trip_detail_event.dart`, `trip_detail_state.dart`

### Dependencies injectees (7 repositories)

| Repository | Donnees |
|-----------|---------|
| `TripRepository` | Trip metadata, status, CRUD |
| `ActivityRepository` | Activites, suggestions IA, batch validation |
| `TransportRepository` | Vols manuels |
| `AccommodationRepository` | Hebergements |
| `BaggageRepository` | Checklist bagages |
| `BudgetRepository` | Budget summary, items |
| `TripShareRepository` | Partages (invitations) |

### Events (28 events)

| Categorie | Events |
|-----------|--------|
| Lifecycle | `LoadTripDetail`, `RefreshTripDetail`, `LoadDeferredSections` |
| Navigation | `SelectDay`, `ToggleSection` |
| Activites | `ValidateActivity`, `RejectActivity`, `BatchValidateActivitiesFromDetail`, `UpdateActivityFromDetail`, `MoveActivityToDay`, `CreateActivityFromDetail` |
| Suggestions IA | `SuggestActivitiesForDay`, `ClearDaySuggestions` |
| Trip metadata | `UpdateTripTitle`, `UpdateTripDates`, `UpdateTripTravelers`, `UpdateTripStatus` |
| Vols | `AddFlightToDetail`, `DeleteFlightFromDetail` |
| Hebergement | `DeleteAccommodationFromDetail` |
| Bagages | `ToggleBaggagePackedFromDetail`, `DeleteBaggageItemFromDetail` |
| Budget | `CreateBudgetItemFromDetail` |
| Partage | `DeleteShareFromDetail` |
| Destruction | `DeleteTripDetail` |

### States

| State | Description |
|-------|-------------|
| `TripDetailInitial` | Etat par defaut |
| `TripDetailLoading` | Shimmer pendant le chargement |
| `TripDetailLoaded` | Donnees chargees, contient toutes les listes et l'etat de completion |
| `TripDetailError` | Erreur de chargement |
| `TripDetailDeleted` | Voyage supprime, declenche navigation vers `HomeRoute` |

### Chargement en deux temps

**Tier 1 — Core** (`_fetchCore`, ~100ms) :
1. `getTripById(tripId)` + `getActivities(tripId)` en parallele
2. Emission de `TripDetailLoaded` avec listes vides pour vols/hebergements/bagages/shares
3. Apres 100ms de delai, ajout de `LoadDeferredSections`

**Tier 2 — Sections differees** (`_onLoadDeferredSections`) :
1. 5 appels en parallele : vols, hebergements, bagages, budget summary, shares
2. Mise a jour de l'etat avec `deferredLoaded: true`
3. Recalcul de la completion

Ce pattern permet un affichage quasi-instantane du hero + timeline, avec des shimmers pour les sections secondaires.

### Updates optimistes

Toutes les mutations (validate, reject, delete, toggle, update) suivent le pattern :
1. Mise a jour locale immediate de l'etat
2. Appel API en arriere-plan
3. En cas d'echec → rollback vers l'etat precedent (`emit(loaded)`)

## Page et Vue

**Fichiers** : `trip_detail_page.dart`, `trip_detail_view.dart`

### TripDetailPage

Cree un `BlocProvider<TripDetailBloc>` local et fire `LoadTripDetail(tripId)` immediatement. Le bloc est detruit a la sortie de la page.

### TripDetailView — Structure de la page

La vue utilise un `BlocConsumer` pour :
- **Listener** : naviguer vers `HomeRoute` apres suppression, afficher les snackbars d'erreur, afficher le message de validation impossible
- **Builder** : rendu conditionnel selon l'etat

La page chargee (`_LoadedContent`) est un `CustomScrollView` avec les sections suivantes :

## Sections de la page

### 1. SliverAppBar avec Hero Header

**Widget** : `trip_hero_header.dart`

AppBar expansible (280px) avec :
- **Background** : image de couverture ou gradient placeholder
- **Overlay gradient** : 3 stops (transparent → 33% noir → 80% noir)
- **Contenu** : destination (icone pin), plage de dates (editable si owner, tap → date picker), badge de statut (`TripStatusBadge`), pill contextuelle
- **Titre** : titre du voyage dans la barre collapssee, editable si owner (icone edit)
- **Actions** : bouton share (si non-viewer)

La pill contextuelle change selon l'etat :
| Etat | Icone | Label |
|------|-------|-------|
| Upcoming | `schedule` | "Dans X jours" |
| Ongoing | `play_circle` | "Jour X/Y" |
| Completed | `check_circle` | "Termine" |

### 2. Bannieres conditionnelles

- **Viewer banner** : affiche si `isViewer == true`, icone oeil + "Lecture seule"
- **Completed banner** : affiche si `isCompleted == true`, icone cadenas + "Voyage termine"

### 3. Stats Row

Ligne de statistiques dans une carte elevee :
- **Voyageurs** (tap → edition si owner) : icone people + nombre
- **Jours restants** (si voyage futur) : icone timer + countdown
- **Duree** (si dates definies) : icone calendar + nombre de jours

### 4. Barre de completion

**Widget** : `trip_completion_bar.dart`

Affichee uniquement si non-viewer. Barre segmentee a 6 segments avec animation d'apparition echelonnee :

| Segment | Icone | Condition remplie |
|---------|-------|-------------------|
| Dates | `calendar_today` | `startDate` ET `endDate` non-null |
| Vols | `flight` | Au moins 1 vol |
| Hebergement | `hotel` | Au moins 1 hebergement |
| Activites | `hiking` | 3+ activites |
| Bagages | `luggage` | 5+ items de bagage |
| Budget | `wallet` | Budget summary existe |

Chaque segment est cliquable (haptic + scroll vers la section correspondante via `Scrollable.ensureVisible`). Le pourcentage global est affiche a gauche (chaque segment vaut ~16.67%).

**Helper** : `trip_detail_completion.dart` — `tripDetailCompletion()` retourne un `CompletionResult` avec le pourcentage et la map segment→bool.

### 5. Quick Actions Row

**Widget** : `quick_actions_row.dart`

Scroll horizontal de chips d'action rapide. Le contenu varie selon le statut et le role :

| Statut | Role | Actions |
|--------|------|---------|
| Draft / Planned | Owner | Add Flight, Add Hotel, Add Activity |
| Ongoing | Owner | Expense, Activities, Baggage |
| Completed | Owner | Souvenirs, Memories |
| Tout statut | Viewer | Flights, Activities |

Chaque chip est un `_QuickActionChip` avec animation de press (scale 0.95), carte elevee, icone + label.

### 6. Timeline Section

**Widget** : `trip_timeline_section.dart`

Section la plus complexe, visible uniquement si `totalDays > 0`.

#### Day Chip Row (DragTarget)

Barre horizontale scrollable de chips "J1", "J2", etc. avec la date sous chaque chip. Le jour courant a un dot indicateur. Les chips sont des `DragTarget<Activity>` : on peut glisser une activite d'un jour vers un autre (event `MoveActivityToDay`).

#### Batch Validate Banner

Si des activites ont le statut `SUGGESTED` et que l'utilisateur est owner, une banniere warning propose :
- "Valider tout" → `BatchValidateActivitiesFromDetail`
- "Revoir un par un" → navigation vers `ActivitiesRoute`

#### Day Content

**Helper** : `day_grouping.dart` — `groupActivitiesByDay()` classe les activites par jour puis par periode :
- `allDay` : pas de `startTime`
- `morning` : heure < 12
- `afternoon` : heure 12-16
- `evening` : heure >= 17

Chaque activite est rendue par un `TimelineActivityCard` avec :
- Validation/rejet (swipe ou boutons) pour les activites `SUGGESTED`
- Drag & drop vers un autre jour
- Edition via bottom sheet avec `ActivityForm`
- Suppression

#### Empty Day Content (avec suggestions IA)

Si un jour est vide, `ElegantEmptyState` avec deux CTA :
1. "Obtenir des suggestions" → `SuggestActivitiesForDay(dayNumber)` → appel API IA → affichage de suggestions inline avec bouton "+" pour ajouter
2. "Ajouter manuellement" → navigation vers `ActivitiesRoute`

Pendant le chargement des suggestions, un shimmer anime 3 blocs placeholder.

### 7. Sections de detail (chargement differe)

Chaque section apparait avec un `StaggeredFadeIn` et un shimmer pendant le chargement differe.

#### Section Vols (`trip_flights_section.dart`)

Affiche les vols manuels avec status derive (`flight_status.dart`) :
- **Confirmed** : tous les 5 champs critiques remplis (depart, arrivee, dates, compagnie)
- **Pending** : un ou plusieurs champs manquants

#### Section Hebergement (`trip_accommodation_section.dart`)

Affiche les hebergements avec status derive (`accommodation_status.dart`) :
- **Confirmed** : `bookingReference` non-null et non-vide
- **Pending** : pas de reference de reservation

#### Section Activites (TripSectionCard)

Carte recapitulative avec le nombre d'activites et 3 previews. Tap → navigation vers `ActivitiesRoute`.

#### Section Bagages (`trip_baggage_section.dart`)

Checklist de bagages avec toggle pack/unpack (optimiste). Compteur `baggagePackedCount / total`.

#### Section Budget (`trip_budget_section.dart`)

Resume du budget : total, depense, restant, pourcentage consomme, niveau d'alerte (WARNING a 80%, DANGER a 100%). Ajout rapide de depense depuis la page detail (`CreateBudgetItemFromDetail`).

#### Section Partage (`trip_sharing_section.dart`)

Liste des participants :
- Owner toujours en premier avec badge "Proprietaire"
- Viewers avec badge "Spectateur" et bouton de suppression (si owner)
- Maximum 3 affiches, puis "Voir tout" → `SharesRoute`
- Etat vide : `ElegantEmptyState` avec CTA "Inviter" → `SharesRoute`

#### Section Carte (TripSectionCard)

Carte recapitulative placeholder avec label "Bientot disponible". Tap → `MapRoute`.

### 8. Boutons d'action de statut

Affiches conditionnellement selon le statut et le role :

| Statut | Bouton | Action |
|--------|--------|--------|
| Draft (non-viewer) | "Marquer comme pret" (`FilledButton`) | Validation : destination + dates requises, sinon dialog d'erreur. Event `UpdateTripStatus(status: 'PLANNED')` |
| Draft (non-viewer) | "Supprimer" (`OutlinedButton` rouge) | Dialog de confirmation destructif → `DeleteTripDetail` |
| Ongoing (non-viewer) | "Terminer le voyage" (`OutlinedButton`) | Event `UpdateTripStatus(status: 'COMPLETED')` |
| Completed | "Donner un avis" (`OutlinedButton`) | Navigation vers `FeedbackRoute` |

### 9. Bottom Padding

Adaptatif : 100px sur iOS (pour la `GlassBottomBar`), 32px sur Android.

## Gestion des roles

Le systeme de roles utilise deux niveaux :

### Cote API (`trip_access.py`)

| Role | Resolution | Droits |
|------|-----------|--------|
| `OWNER` | `trip.user_id == current_user.id` | Lecture + ecriture (CRUD complet) |
| `VIEWER` | Partage existant dans `TripShare` | Lecture seule |
| Aucun | Pas de lien | 404 (masque l'existence du trip) |

Les endpoints d'ecriture (`PATCH`, `DELETE`) utilisent `get_trip_owner_access` qui retourne 403 si le role est `VIEWER`.

### Cote Flutter

L'etat `TripDetailLoaded` expose :
- `userRole` : string "OWNER" ou "VIEWER" (defaut "OWNER")
- `isViewer` : `userRole == 'VIEWER'`
- `isOwner` : `userRole == 'OWNER'`
- `_canEdit` (dans la vue) : `isOwner && !isCompleted`

Impact sur l'UI :
- **Viewer** : banniere "lecture seule", pas de barre de completion, quick actions limitees (Flights + Activities en lecture), pas de boutons de statut, pas de suppression de partages, pas de CTA d'ajout
- **Completed** : banniere "voyage termine", memes restrictions qu'un viewer sauf acces au feedback, bouton "Donner un avis"

## Validation de transition DRAFT → PLANNED

Double validation :

1. **Cote Flutter** (`trip_detail_view.dart` L593-615) : verifie `destinationName` et `startDate + endDate`. Si manquant → dialog listant les champs manquants
2. **Cote Flutter BLoC** (`trip_detail_bloc.dart` L369-381) : meme verification, emet `validationError` → snackbar
3. **Cote API** (`trips_service.py` L227+) : validation identique, retourne erreur 400 avec liste des champs manquants

## Edition des metadonnees

### Titre

Tap sur le titre dans l'AppBar collapsee → `showAdaptiveEditDialog` → `UpdateTripTitle` → `PATCH /v1/trips/{id}` avec `{title: newTitle}`.

### Dates

Tap sur la plage de dates dans le hero → `showTripDateRangePicker` (date_range_picker_sheet.dart) → verification des activites hors-plage (dialog de confirmation si oui) → `UpdateTripDates` → `PATCH /v1/trips/{id}` avec `{startDate, endDate}`.

### Voyageurs

Tap sur le stat "Voyageurs" → `showTravelersEditSheet` (travelers_edit_sheet.dart) → `UpdateTripTravelers` → `PATCH /v1/trips/{id}` avec `{nbTravelers}`.

## API Backend

### Endpoints utilises

| Methode | Path | Description | Acces |
|---------|------|-------------|-------|
| `GET` | `/v1/trips/{id}` | Detail du trip + flight order | Owner + Viewer |
| `GET` | `/v1/trips/{id}/home` | Donnees page home du trip (stats, features, sections) | Owner + Viewer |
| `GET` | `/v1/trips/{id}/activities` | Liste des activites | Owner + Viewer |
| `GET` | `/v1/trips/{id}/flights` | Vols manuels | Owner + Viewer |
| `GET` | `/v1/trips/{id}/accommodations` | Hebergements | Owner + Viewer |
| `GET` | `/v1/trips/{id}/baggage` | Checklist bagages | Owner + Viewer |
| `GET` | `/v1/trips/{id}/budget/summary` | Resume budget | Owner + Viewer (expenses masquees pour Viewer) |
| `GET` | `/v1/trips/{id}/shares` | Partages | Owner + Viewer |
| `PATCH` | `/v1/trips/{id}` | Update trip (titre, dates, voyageurs, etc.) | Owner only |
| `PATCH` | `/v1/trips/{id}/status` | Transition de statut | Owner only |
| `DELETE` | `/v1/trips/{id}` | Suppression du trip | Owner only |
| `POST` | `/v1/trips/{id}/activities/suggest` | Suggestions IA pour un jour | Owner only |
| `POST` | `/v1/trips/{id}/activities` | Creation d'activite | Owner only |
| `PATCH` | `/v1/trips/{id}/activities/{id}` | Update activite | Owner only |
| `DELETE` | `/v1/trips/{id}/activities/{id}` | Suppression activite | Owner only |
| `POST` | `/v1/trips/{id}/budget` | Ajout depense budget | Owner only |

### Schema TripDetailResponse

```json
{
  "trip": TripResponse,
  "flightOrder": { "id": str, "amadeusFlightOrderId": str, "status": str } | null
}
```

### Schema TripHomeResponse

```json
{
  "trip": TripResponse,
  "stats": { "baggageCount": int, "totalExpenses": float, "nbTravelers": int, "daysUntilTrip": int?, "tripDuration": int? },
  "features": [{ "id": str, "label": str, "icon": str, "route": str, "enabled": bool }],
  "sections": [{ "sectionId": str, "count": int, "previewItems": [str] }]
}
```

Note : pour les Viewers, `totalExpenses` est force a 0 cote API (`routes.py` L188).

### Transitions de statut valides (API)

```python
VALID_TRANSITIONS = {
    "DRAFT":   ["PLANNED"],
    "PLANNED": ["ONGOING"],
    "ONGOING": ["COMPLETED"],
}
```

Toute transition invalide retourne une erreur 400 `INVALID_STATUS_TRANSITION`.

### Notifications envoyees

Lors de la transition `ONGOING → COMPLETED` via API, une notification bulk `TRIP_ENDED` est envoyee a tous les participants avec deep link vers l'ecran feedback.

## Tests existants

| Fichier | Couverture |
|---------|-----------|
| `test/trip_detail/bloc/trip_detail_bloc_test.dart` | Events, states, chargement, mutations optimistes |
| `test/trip_detail/helpers/trip_detail_completion_test.dart` | Calcul de completion (6 segments) |
| `test/trip_detail/view/trip_detail_page_test.dart` | Montage de la page, BlocProvider |

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Section Carte incomplete | `TripSectionCard` pour la carte affiche "Bientot disponible" (`trip_detail_view.dart` L570-578). `MapRoute` existe mais la section dans le detail est un placeholder sans donnees. | P1 |
| Endpoint `GET /{id}/home` non utilise cote Flutter | L'API expose `TripHomeResponse` avec stats, features et sections (`routes.py` L172-196) mais le `TripDetailBloc` ne l'appelle jamais — il reconstruit tout depuis 7 appels separes. Duplication de logique. | P2 |
| Pas de gestion d'erreur granulaire pour les sections differees | Dans `_onLoadDeferredSections` (`trip_detail_bloc.dart` L106-146), tous les echecs sont silencieusement ignores (`dataOrNull ?? []`). Aucun feedback utilisateur si un appel echoue. | P1 |
| Rollback non signale a l'utilisateur | Lors d'un rollback apres echec API (ex: `_onDeleteFlight` L526-529), l'etat est restaure mais aucun snackbar ou feedback n'informe l'utilisateur de l'echec. Pattern repete dans 10+ handlers. | P1 |
| Test widget absent pour `TripDetailView` | `trip_detail_page_test.dart` existe mais ne teste que le montage. Aucun test pour les interactions (edit title, date picker, status transitions, sections collapsibles). | P2 |
| Test absent pour le drag & drop d'activites | `MoveActivityToDay` est teste dans le bloc test mais il n'y a pas de test widget pour le `DragTarget` dans `_DayChipRow` de `trip_timeline_section.dart`. | P2 |
| Test absent pour les suggestions IA inline | `SuggestActivitiesForDay` et `_InlineSuggestions` ne sont pas couverts par des tests widget. | P2 |
| Pas de role EDITOR | Le systeme ne supporte que OWNER et VIEWER (`trip_access.py`). Un role EDITOR (peut modifier sans supprimer) manque pour les cas d'usage collaboratifs. | P2 |
| Budget Viewer masquage partiel | L'API masque `totalExpenses` pour les viewers (`routes.py` L188) mais les items individuels de budget restent accessibles via l'endpoint budget items. Incoherence de politique d'acces. | P1 |
| Offline : aucune queue de mutations | Les updates optimistes ne sont pas persistes localement. Si l'app est fermee pendant un rollback en attente, la mutation est perdue. | P2 |
| Duplex `FlightOrder` non exploite | L'endpoint `GET /{id}` retourne un `flightOrder` (reservation Amadeus) dans `TripDetailResponse`, mais le Flutter ne l'affiche nulle part dans la vue detail. | P2 |
