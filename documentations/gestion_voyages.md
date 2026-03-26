# Gestion des voyages — BagTrip

## Vue d'ensemble

Le module de gestion des voyages permet aux utilisateurs de creer, organiser et suivre leurs voyages via une interface mobile avec liste groupee par statut, page d'accueil par voyage et machine a etats pour les transitions de statut. Les voyages sont persistes en backend (PostgreSQL) et geres cote mobile via le pattern BLoC.

```
┌──────────┐         ┌──────────────┐         ┌──────────────┐
│  Mobile   │────────>│  Backend API │────────>│  PostgreSQL  │
│  Flutter  │<────────│  FastAPI     │<────────│              │
└──────────┘         └──────────────┘         └──────────────┘
     │                      │
     │                      ├── Table trips (enrichie)
     │                      └── TripsService (CRUD + status + home)
     │
     ├── TripService (client HTTP)
     ├── TripManagementBloc (state management)
     └── Modeles : Trip, TripGrouped, TripHome
```

### Machine a etats des statuts

```
  ┌───────┐        ┌──────────┐        ┌────────┐        ┌───────────┐
  │ draft │──────> │ planning │──────> │ active │──────> │ completed │
  └───────┘        └──────────┘        └────────┘        └───────────┘
       ^                │                                       │
       └────────────────┘                                       v
                                                         ┌──────────┐
                                                         │ archived │
                                                         └──────────┘
```

| Transition | De | Vers |
|:----------:|:--:|:----:|
| Planifier | draft | planning |
| Annuler planification | planning | draft |
| Demarrer | planning | active |
| Terminer | active | completed |
| Archiver | completed | archived |

Toute transition non listee retourne une erreur `INVALID_STATUS_TRANSITION` (HTTP 400).

---

## Backend (api/)

### Table trips

```sql
CREATE TABLE trips (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(id),
    title             VARCHAR,
    origin_iata       VARCHAR(3),
    destination_iata  VARCHAR(3),
    start_date        DATE,
    end_date          DATE,
    status            VARCHAR,            -- draft | planning | active | completed | archived
    description       TEXT,
    cover_image_url   VARCHAR,
    destination_name  VARCHAR,
    nb_travelers      INTEGER DEFAULT 1,
    archived_at       TIMESTAMPTZ,        -- date d'archivage (set automatiquement)
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX ix_trips_user_id ON trips (user_id);
```

Le modele SQLAlchemy est dans `api/src/models/trip.py`. Les 5 nouvelles colonnes (`description`, `cover_image_url`, `destination_name`, `nb_travelers`, `archived_at`) sont ajoutees via une migration idempotente dans `api/src/migrations/migrate_trips_table.py`. La migration convertit egalement les anciens statuts `planned` en `planning`.

### Endpoints

Tous sous le prefixe `/v1/trips`. Toutes les routes requierent un access token valide (`Authorization: Bearer <token>`).

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/v1/trips` | Creer un nouveau voyage |
| GET | `/v1/trips` | Lister tous les voyages de l'utilisateur |
| GET | `/v1/trips/grouped` | Voyages groupes par statut |
| GET | `/v1/trips/{tripId}` | Details d'un voyage avec aggregations |
| GET | `/v1/trips/{tripId}/home` | Donnees page d'accueil voyage (trip + stats + features) |
| PATCH | `/v1/trips/{tripId}` | Mettre a jour un voyage |
| PATCH | `/v1/trips/{tripId}/status` | Changer le statut (avec validation transitions) |
| DELETE | `/v1/trips/{tripId}` | Supprimer un voyage |

> **Note** : La route `/grouped` est declaree **avant** `/{tripId}` dans le routeur FastAPI, sinon `grouped` serait interprete comme un UUID.

#### POST /v1/trips

Cree un voyage avec le statut initial `draft`.

**Body** :
```json
{
  "title": "Voyage a Tokyo",
  "description": "Voyage culturel de 2 semaines",
  "destinationName": "Tokyo, Japon",
  "nbTravelers": 2,
  "originIata": "CDG",
  "destinationIata": "NRT",
  "startDate": "2026-05-01",
  "endDate": "2026-05-15",
  "coverImageUrl": "https://example.com/tokyo.jpg"
}
```

Tous les champs sont optionnels.

**Reponse** (201) :
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Voyage a Tokyo",
  "description": "Voyage culturel de 2 semaines",
  "destinationName": "Tokyo, Japon",
  "nbTravelers": 2,
  "originIata": "CDG",
  "destinationIata": "NRT",
  "startDate": "2026-05-01",
  "endDate": "2026-05-15",
  "coverImageUrl": "https://example.com/tokyo.jpg",
  "status": "draft",
  "archivedAt": null,
  "createdAt": "2026-03-13T10:30:00Z",
  "updatedAt": "2026-03-13T10:30:00Z"
}
```

#### GET /v1/trips/grouped

Retourne les voyages de l'utilisateur groupes par statut. Les statuts `draft` et `planned` (legacy) sont regroupes sous `planning`.

**Reponse** (200) :
```json
{
  "active": [],
  "planning": [
    {
      "id": "...",
      "title": "Voyage a Tokyo",
      "status": "draft",
      "destinationName": "Tokyo, Japon",
      "nbTravelers": 2,
      "startDate": "2026-05-01",
      "endDate": "2026-05-15",
      "createdAt": "2026-03-13T10:30:00Z",
      "updatedAt": "2026-03-13T10:30:00Z"
    }
  ],
  "completed": [],
  "archived": []
}
```

#### GET /v1/trips/{tripId}/home

Retourne les donnees pour la page d'accueil d'un voyage : le trip, des statistiques calculees et la liste des feature tiles.

**Reponse** (200) :
```json
{
  "trip": { "...": "TripResponse complet" },
  "stats": {
    "baggageCount": 0,
    "totalExpenses": 0.0,
    "nbTravelers": 2,
    "daysUntilTrip": 49,
    "tripDuration": 14
  },
  "features": [
    { "id": "baggage", "label": "Bagages", "icon": "luggage", "route": "baggage", "enabled": false },
    { "id": "budget", "label": "Budget", "icon": "wallet", "route": "budget", "enabled": false },
    { "id": "accommodation", "label": "Hébergement", "icon": "hotel", "route": "accommodation", "enabled": false },
    { "id": "activities", "label": "Activités", "icon": "hiking", "route": "activities", "enabled": false },
    { "id": "transport", "label": "Transport", "icon": "directions_car", "route": "transport", "enabled": false },
    { "id": "map", "label": "Carte", "icon": "map", "route": "map", "enabled": false }
  ]
}
```

Les statistiques sont calculees dynamiquement :
- `daysUntilTrip` : nombre de jours avant `startDate` (0 si passe)
- `tripDuration` : `endDate - startDate` en jours
- `nbTravelers` : depuis le champ du trip (defaut 1)
- `baggageCount` et `totalExpenses` : toujours 0 pour l'instant (futures sprints)

Les 6 feature tiles sont toutes `enabled: false` — elles seront activees dans les sprints suivants.

#### PATCH /v1/trips/{tripId}/status

Change le statut d'un voyage avec validation de la machine a etats.

**Body** :
```json
{
  "status": "planning"
}
```

**Reponse** (200) : `TripResponse` avec le nouveau statut.

**Erreurs** :
- `404` : voyage non trouve ou non propriete de l'utilisateur
- `400 INVALID_STATUS_TRANSITION` : transition non autorisee (ex: `draft` → `completed`)

Si le nouveau statut est `archived`, le champ `archivedAt` est automatiquement rempli avec la date courante UTC.

### TripsService

`api/src/services/trips_service.py` expose des methodes statiques :

| Methode | Description |
|---------|-------------|
| `create_trip(db, user_id, ...)` | Creer un trip avec statut `draft` |
| `get_trips_by_user(db, user_id)` | Lister les trips d'un utilisateur (tri par date creation desc) |
| `get_trip_by_id(db, trip_id, user_id)` | Recuperer un trip (verifie propriete) |
| `update_trip(db, trip_id, user_id, ...)` | Mise a jour partielle des champs |
| `get_grouped_trips(db, user_id)` | Grouper les trips par statut (dict avec 4 cles) |
| `update_trip_status(db, trip_id, user_id, new_status)` | Changement de statut avec validation transitions |
| `get_trip_home(db, trip_id, user_id)` | Donnees Trip Home (trip + stats calculees + feature tiles) |
| `delete_trip(db, trip_id, user_id)` | Suppression d'un trip |

La table de transitions valides est definie dans `VALID_TRANSITIONS` :

```python
VALID_TRANSITIONS = {
    "draft": ["planning"],
    "planning": ["active", "draft"],
    "active": ["completed"],
    "completed": ["archived"],
}
```

### Fichiers cles — Backend

| Fichier | Role |
|---------|------|
| `api/src/models/trip.py` | Modele SQLAlchemy Trip (13 colonnes + relations) |
| `api/src/migrations/migrate_trips_table.py` | Migration idempotente (5 colonnes + conversion statuts) |
| `api/src/api/trips/schemas.py` | Schemas Pydantic (CRUD + status + home + grouped) |
| `api/src/api/trips/routes.py` | 8 endpoints API trips |
| `api/src/services/trips_service.py` | Logique metier (CRUD + machine a etats + stats) |

---

## Mobile (bagtrip/)

### Navigation

La tab "Voyages" est accessible depuis la bottom bar (3eme onglet, icone `luggage_outlined`).

```
/trips                              → TripsListPage (liste groupee)
/trips/:tripId                      → TripHomePage (page d'accueil du voyage)
/trips/planifier                    → PlanifierPage (choix IA ou manuel)
/trips/planifier/manual             → PlanifierManualPage
/trips/planifier/manual/transport   → PlanifierManualTransportPage
/trips/planifier/manual/flight-search → PlanifierManualFlightPage
/trips/planifier/create-trip-ai     → CreateTripAiFlowPage
```

La `BottomTabBar` utilise l'enum `NavigationTab.trips` (ex-`planifier`). Le `AppShell` mappe l'index de la branche GoRouter vers le bon onglet via `_shellTabOrder`.

### Modeles Dart

**Trip** (`bagtrip/lib/models/trip.dart`) :

```dart
enum TripStatus { draft, planning, active, completed, archived }

class Trip {
  final String id;
  final String userId;
  final String? title;
  final String? originIata;
  final String? destinationIata;
  final DateTime? startDate;
  final DateTime? endDate;
  final TripStatus status;
  final String? description;
  final String? destinationName;
  final int? nbTravelers;
  final String? coverImageUrl;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

Le `fromJson` supporte les deux formats de cle (camelCase et snake_case) pour compatibilite.

**TripGrouped** (`bagtrip/lib/models/trip_grouped.dart`) :

```dart
class TripGrouped {
  final List<Trip> active;
  final List<Trip> planning;
  final List<Trip> completed;
  final List<Trip> archived;
}
```

**TripHome** (`bagtrip/lib/models/trip_home.dart`) :

```dart
class TripHomeStats {
  final int baggageCount;
  final double totalExpenses;
  final int nbTravelers;
  final int? daysUntilTrip;
  final int? tripDuration;
}

class TripFeatureTile {
  final String id;
  final String label;
  final String icon;
  final String route;
  final bool enabled;
}

class TripHome {
  final Trip trip;
  final TripHomeStats stats;
  final List<TripFeatureTile> features;
}
```

### TripService

`bagtrip/lib/service/trip_service.dart` expose :

| Methode | Endpoint | Description |
|---------|----------|-------------|
| `createTrip({...})` | POST /trips | Creer un voyage avec tous les champs |
| `getTrips()` | GET /trips | Lister les voyages |
| `getGroupedTrips()` | GET /trips/grouped | Voyages groupes par statut |
| `getTripHome(tripId)` | GET /trips/$tripId/home | Donnees page d'accueil voyage |
| `updateTripStatus(tripId, status)` | PATCH /trips/$tripId/status | Changer le statut |
| `getTripById(tripId)` | GET /trips/$tripId | Details d'un voyage |
| `updateTrip(tripId, updates)` | PATCH /trips/$tripId | Mise a jour partielle |
| `deleteTrip(tripId)` | DELETE /trips/$tripId | Supprimer un voyage |

### TripManagementBloc

`bagtrip/lib/trips/bloc/trip_management_bloc.dart` gere l'etat des voyages via le pattern BLoC. Le bloc est fourni globalement dans `main.dart` via `MultiBlocProvider`.

**Events** :

| Event | Description |
|-------|-------------|
| `LoadTrips` | Charger les voyages groupes par statut |
| `CreateTrip` | Creer un nouveau voyage (title, description?, destinationName?, nbTravelers?, startDate?, endDate?) |
| `LoadTripHome` | Charger les donnees de la page d'accueil d'un voyage |
| `UpdateTripStatus` | Changer le statut d'un voyage (tripId, status) |
| `ArchiveTrip` | Raccourci pour archiver un voyage (appelle updateTripStatus avec "archived") |

**States** :

| State | Description |
|-------|-------------|
| `TripManagementInitial` | Etat initial |
| `TripManagementLoading` | Chargement en cours |
| `TripManagementLoaded` | Voyages groupes charges (`TripGrouped`) |
| `TripManagementError` | Erreur avec message |
| `TripHomeLoading` | Chargement page d'accueil voyage |
| `TripHomeLoaded` | Page d'accueil chargee (`TripHome`) |
| `TripCreated` | Voyage cree (`Trip`) |

Apres un `UpdateTripStatus` ou `ArchiveTrip` reussi, le bloc re-dispatch automatiquement `LoadTrips` pour rafraichir la liste.

### Widgets

| Widget | Fichier | Description |
|--------|---------|-------------|
| `TripStatusBadge` | `trips/widgets/trip_status_badge.dart` | Badge colore par statut (active=vert, planning=bleu, completed=gris, archived=muted) |
| `TripCard` | `trips/widgets/trip_card.dart` | Carte voyage : titre, destination, dates, badge statut, nb voyageurs, onTap |
| `TripHeader` | `trips/widgets/trip_header.dart` | Header Trip Home : gradient, titre, destination, dates, countdown "J-X" |
| `TripFeatureTileWidget` | `trips/widgets/trip_feature_tile.dart` | Tuile grille : icone, label, etat active/desactive, "Bientot" si disabled |

### Pages

**TripsListPage** (`bagtrip/lib/pages/trips_list_page.dart`) :
- Wrapper `BlocProvider.value` + dispatch `LoadTrips`
- Vue : `DefaultTabController` avec 3 onglets :
  - "En cours" → trips `active`
  - "Planifies" → trips `planning` + `draft`
  - "Archives" → trips `completed` + `archived`
- Pull-to-refresh (re-dispatch `LoadTrips`)
- FAB "+" → navigation vers `/trips/planifier`
- Empty state par onglet si aucun voyage

**TripHomePage** (`bagtrip/lib/pages/trip_home_page.dart`) :
- Accepte `tripId`, dispatch `LoadTripHome(tripId: tripId)`
- Vue : `CustomScrollView` avec :
  - `TripHeader` (gradient, titre, countdown)
  - Row de stats (nb voyageurs, jours restants, duree)
  - `GridView.count(crossAxisCount: 2)` de `TripFeatureTileWidget`
  - Bouton "Terminer le voyage" (dispatch `UpdateTripStatus(status: "completed")`)
- `BlocConsumer` listener : navigue vers `/trips` apres changement de statut reussi

### Fichiers cles — Mobile

| Fichier | Role |
|---------|------|
| `bagtrip/lib/models/trip.dart` | Modele Trip + enum TripStatus |
| `bagtrip/lib/models/trip_grouped.dart` | Modele TripGrouped (4 listes par statut) |
| `bagtrip/lib/models/trip_home.dart` | Modeles TripHome, TripHomeStats, TripFeatureTile |
| `bagtrip/lib/service/trip_service.dart` | Client HTTP trips (8 methodes) |
| `bagtrip/lib/trips/bloc/trip_management_bloc.dart` | BLoC gestion voyages |
| `bagtrip/lib/trips/bloc/trip_management_event.dart` | 5 events |
| `bagtrip/lib/trips/bloc/trip_management_state.dart` | 7 states |
| `bagtrip/lib/trips/view/trips_list_view.dart` | Vue liste avec 3 onglets |
| `bagtrip/lib/trips/view/trip_home_view.dart` | Vue page d'accueil voyage |
| `bagtrip/lib/trips/widgets/trip_card.dart` | Widget carte voyage |
| `bagtrip/lib/trips/widgets/trip_status_badge.dart` | Widget badge statut |
| `bagtrip/lib/trips/widgets/trip_header.dart` | Widget header Trip Home |
| `bagtrip/lib/trips/widgets/trip_feature_tile.dart` | Widget tuile feature |
| `bagtrip/lib/pages/trips_list_page.dart` | Page liste voyages (wrapper BLoC) |
| `bagtrip/lib/pages/trip_home_page.dart` | Page Trip Home (wrapper BLoC) |
| `bagtrip/lib/components/bottom_tab_bar.dart` | Bottom bar avec onglet "Voyages" |
| `bagtrip/lib/navigation/app_router.dart` | Routes /trips et sous-routes |
| `bagtrip/lib/navigation/app_shell.dart` | Shell avec mapping NavigationTab.trips |
| `bagtrip/lib/main.dart` | TripManagementBloc fourni globalement |
