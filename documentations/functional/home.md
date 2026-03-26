# Page d'accueil (Home)

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

La page d'accueil de BagTrip est une page contextuelle qui adapte entierement son contenu en fonction de l'etat de l'utilisateur et de ses voyages. Elle repose sur un `HomeBloc` persistant (monte dans le `MultiBlocProvider` app-level de `main.dart`) qui orchestre la detection automatique de mode et les transitions de statut des voyages.

Cote API, les donnees sont recuperees via l'endpoint pagine `GET /v1/trips?status=<status>&limit=5` (3 appels paralleles pour `ongoing`, `planned`, `completed`) et `GET /v1/users/me` pour l'utilisateur courant.

## Architecture BLoC

**Fichiers** : `bagtrip/lib/home/bloc/home_bloc.dart`, `home_event.dart`, `home_state.dart`

### Events

| Event | Declencheur | Description |
|-------|-------------|-------------|
| `LoadHome` | `HomePage.build()` si `state is HomeInitial` | Chargement initial |
| `RefreshHome` | Pull-to-refresh, retour de navigation | Rafraichissement sans shimmer |
| `ConfirmTripCompletion` | Dialog de fin de voyage — bouton "Confirmer" | Marque le voyage comme `completed` via API, navigue vers `PostTripRoute` |
| `DismissTripCompletion` | Dialog de fin de voyage — bouton "Plus tard" | Enregistre un dismiss local (24h cooldown), programme une notification rappel |

### States (sealed class)

| State | Condition | Vue affichee |
|-------|-----------|--------------|
| `HomeInitial` | Etat par defaut avant chargement | `LoadingView` |
| `HomeLoading` | Pendant le fetch initial | `LoadingView` |
| `HomeError` | Echec auth ou tous les appels trips echouent | `ErrorView` avec retry |
| `HomeNewUser` | `totalTrips == 0` et aucun voyage ongoing | `OnboardingHomeView` |
| `HomeActiveTrip` | Au moins 1 voyage ongoing | `ActiveTripHomeView` |
| `HomeTripManager` | Des voyages existent mais aucun ongoing | `TripManagerHomeView` |

### Decision tree (dans `_fetchAndEmitContextualState`)

1. Fetch en parallele : user, ongoing trips, planned trips, completed trips
2. Si erreur auth → `HomeError`
3. Si tous les appels trips echouent → `HomeError`
4. Auto-detection `planned → ongoing` via `trip_mode_detector.dart`
5. Auto-detection `ongoing → completed` (endDate passee) via `trip_end_detector.dart`
6. Si `totalTrips == 0` et aucun ongoing → `HomeNewUser`
7. Si ongoing non vide → fetch activites du jour + meteo → `HomeActiveTrip`
8. Sinon → `HomeTripManager`

## Detection automatique de mode

### Planned → Ongoing (`trip_mode_detector.dart`)

Le helper `detectAndTransitionTrips` identifie les voyages `planned` dont la `startDate <= today` et la `endDate >= today` (ou null). Il effectue la transition :
- **Online** : appel API `PATCH /v1/trips/{id}/status` avec `{"status": "ONGOING"}` pour chaque candidat, en parallele
- **Offline** : transition optimiste locale (le voyage apparait comme ongoing sans appel API)

Les voyages nouvellement transitionnes declenchent le scheduling de notifications ongoing via `TripNotificationScheduler.scheduleOngoingNotifications`.

### Ongoing → Completed (`trip_end_detector.dart`)

Le helper `detectEndedTrips` identifie les voyages `ongoing` dont la `endDate < today`. Il filtre ceux qui ont ete dismisses recemment (< 24h) via `PostTripDismissalStorage` (Hive). Le premier voyage detecte est propose a l'utilisateur via un dialog adaptatif (`showAdaptiveAlertDialog`).

### Cote API : transitions automatiques (`TripsService.auto_transition_statuses`)

Un job quotidien cote serveur effectue les memes transitions en bulk :
- `PLANNED → ONGOING` quand `start_date <= today`
- `ONGOING → COMPLETED` quand `end_date < today`
- Envoie des notifications `TRIP_ENDED` aux participants des voyages completes

Les transitions valides cote API sont : `DRAFT → PLANNED`, `PLANNED → ONGOING`, `ONGOING → COMPLETED`.

## Etat 1 : Onboarding (HomeNewUser)

**Vue** : `bagtrip/lib/home/view/onboarding_home_view.dart`

Affichee lorsque l'utilisateur n'a aucun voyage. Contenu :

1. **Icone de bienvenue** : gradient primary→secondary, icone avion, ombre portee
2. **Greeting personnalise** : `homeGreeting(name)` si nom connu, sinon `homeWelcomeTitle`
3. **Sous-titre** : `homeWelcomeSubtitle`
4. **CTA principal** (`_WelcomeCta`) : bouton gradient pleine largeur, navigue vers `PlanTripRoute`
5. **Section inspiration** : titre "INSPIRATION" + carousel horizontal de 6 destinations hardcodees (`InspirationDestination.all` dans `models/inspiration_destination.dart`)

Les destinations d'inspiration sont : Tokyo, Barcelona, Marrakech, Bali, New York, Santorini. Chaque carte affiche le drapeau, le nom, le pays, et un gradient de couleurs. Le tap pre-remplit le formulaire de creation de voyage via `PlanTripRoute($extra: LocationResult(...))`.

## Etat 2 : Voyage actif (HomeActiveTrip)

**Vue** : `bagtrip/lib/home/view/active_trip_home_view.dart`

Affichee lorsqu'au moins un voyage est en cours. Le voyage le plus proche (par `startDate`) est selectionne via `_pickEarliestTrip`.

### Donnees supplementaires fetchees

- `ActivityRepository.getActivities(tripId)` — toutes les activites du voyage
- `WeatherRepository.getWeather(tripId)` → `GET /v1/trips/{tripId}/weather` — meteo via Amadeus + OpenWeather

### Sections affichees (CustomScrollView)

1. **Greeting** : "Bonjour, {prenom}" ou fallback generique
2. **Hero card** (`ActiveTripHero`) : image de couverture ou gradient placeholder, nom de destination, pill "Jour X/Y", meteo (temperature + description). Tap → navigation vers `TripHomeRoute`
3. **Programme du jour** (header "AUJOURD'HUI") : timeline des activites du jour ou `ElegantEmptyState` si vide
4. **Section demain** (conditionnelle) : si des activites existent pour demain, affichage collapsible (3 max puis "Voir tout"). Badge "Dernier jour !" si `isTomorrowLastDay`
5. **Quick Actions** : 3 boutons contextuels resolus par `contextual_actions_helper.dart`
6. **PlanTripCta** : toujours present en bas, permet de creer un nouveau voyage

### Timeline du jour (`today_activities.dart`)

Le helper `classifyTodayActivities` classe les activites :
- **allDay** : activites sans `startTime`
- **timed** : activites avec `startTime`, triees chronologiquement
- **currentActivity** : activite dont `startTime <= now < endTime`
- **nextActivity** : premiere activite dont `startTime > now`
- **nowIndicator** : position du marqueur "maintenant" dans la timeline
- **tomorrowActivities** : activites du lendemain

Un `TodayTickCubit` emet `DateTime.now()` toutes les 60 secondes pour rafraichir l'indicateur de temps courant, les badges "En cours" (pulsation animee), et le calcul des minutes restantes.

### Quick Actions contextuelles (`contextual_actions_helper.dart`)

5 regles de priorite selectionnent 3 actions parmi 12 types possibles :

| Priorite | Condition | Actions |
|----------|-----------|---------|
| 1 | Activite en cours | Navigate, Expense, Photo |
| 2 | Matin + activite a venir | Schedule, Weather, Check-out |
| 3 | Gap apres-midi + activite a venir | Next activity, AI Suggestion, Map |
| 4 | Soir, plus d'activites | Today expenses, Tomorrow, Budget |
| 5 | Fallback | Schedule, Weather, Budget |

**Actions non implementees** (callback `() {}`) : Weather, Photo, AI Suggestion, Tomorrow.

### Navigation GPS (`map_launcher.dart`)

Le helper `launchMapNavigation` gere :
- **iOS** : si Google Maps installe → action sheet proposant Apple Maps ou Google Maps ; sinon Apple Maps directement
- **Android** : intent `geo:` puis fallback Google Maps web

### Quick Expense Sheet

Bottom sheet modale (`quick_expense_sheet.dart`) permettant l'ajout rapide d'une depense. Gere par `QuickExpenseCubit`. Champs : montant (EUR), categorie (food/transport/activity/other), note optionnelle. Appel API : `POST /v1/trips/{tripId}/budget` via `BudgetRepository.createBudgetItem`.

### Dialog de fin de voyage

Quand `pendingCompletionTrip` est non-null, un dialog adaptatif est affiche automatiquement au premier build :
- **Confirmer** → `ConfirmTripCompletion` → API `PATCH /v1/trips/{id}/status` → navigation vers `PostTripRoute`
- **Plus tard** → `DismissTripCompletion` → dismiss stocke localement (24h) + notification de rappel

## Etat 3 : Gestionnaire de voyages (HomeTripManager)

**Vue** : `bagtrip/lib/home/view/trip_manager_home_view.dart`

Affichee lorsque l'utilisateur a des voyages mais aucun n'est en cours.

### Sections affichees (CustomScrollView)

1. **Greeting** : identique aux autres etats
2. **NextTripHero** (conditionnel, `shared_home_widgets.dart → NextTripHero`) : carte gradient avec destination, countdown "Dans X jours", barre de completion du voyage, chevron. Tap → `TripHomeRoute`
3. **PlanTripCta** : carte secondaire pour creer un nouveau voyage
4. **Section "MES VOYAGES"** : controle segmente a 3 onglets (Ongoing / Planned / Completed) + `TabBarView`
5. **Carousel completed** (conditionnel, `completed_trips_carousel.dart`) : `PageView` horizontal avec filtre grayscale, dots de pagination

### Listes de voyages paginee

Le composant `_TripListContent` utilise `PaginatedList<Trip>` avec pagination via `TripManagementBloc` (events `LoadTripsByStatus`, `LoadMoreTripsByStatus`). Chaque `TripCard` offre : tap → detail, share → partage, archive → completion.

### Completion du prochain voyage (`trip_completion.dart`)

Calcul simplifie (5 champs, 20% chacun) :
- `startDate` non-null
- `endDate` non-null
- `destinationName` non-null et non-vide
- `nbTravelers > 0`
- `budgetTotal > 0`

### Notifications plannifiees

Pour chaque voyage `planned`, le bloc schedule un rappel de packing via `TripNotificationScheduler.schedulePackingReminder`.

## Transitions entre etats

Les transitions visuelles utilisent `AnimatedSwitcher` (500ms, `springCurve` en entree, `easeIn` en sortie) avec fade + slide vertical (5% offset).

Un `BlocListener` detecte la transition `HomeTripManager → HomeActiveTrip` pour declencher un haptic de succes.

Un second `BlocListener` detecte `completedTripId` non-null dans `HomeActiveTrip` pour naviguer vers `PostTripRoute` avec haptic.

## API Backend

### Endpoints utilises par la Home

| Methode | Path | Description |
|---------|------|-------------|
| `GET` | `/v1/trips?status=ongoing&limit=5` | Voyages en cours (pagine) |
| `GET` | `/v1/trips?status=planned&limit=5` | Voyages planifies (pagine) |
| `GET` | `/v1/trips?status=completed&limit=5` | Voyages termines (pagine) |
| `GET` | `/v1/users/me` | Utilisateur courant |
| `GET` | `/v1/trips/{id}/activities` | Activites du voyage actif |
| `GET` | `/v1/trips/{id}/weather` | Meteo de la destination |
| `PATCH` | `/v1/trips/{id}/status` | Transition de statut (planned→ongoing, ongoing→completed) |

### Schema TripPaginatedResponse

```json
{
  "items": [TripResponse],
  "total": int,
  "page": int,
  "limit": int,
  "totalPages": int
}
```

### Schema WeatherResponse

```json
{
  "avg_temp_c": float,
  "description": string,
  "rain_probability": int,
  "source": string
}
```

L'endpoint meteo resout les coordonnees via Amadeus (`resolve_iata_code`), puis interroge l'API meteo pour une plage allant de `max(start_date, today)` a `min(end_date, today + 7j)`.

### Controle d'acces

L'acces aux trips utilise le systeme `TripAccess` (`api/src/api/auth/trip_access.py`) :
- **OWNER** : `trip.user_id == current_user.id`
- **VIEWER** : partage existant dans `TripShare`
- Si aucun acces → 404 (ne revele pas l'existence du trip)

## Tests existants

| Fichier | Couverture |
|---------|-----------|
| `test/blocs/home_bloc_test.dart` | Events, states, decision tree |
| `test/blocs/home_bloc_parallel_test.dart` | Appels paralleles |
| `test/home/view/home_view_test.dart` | Routing entre vues |
| `test/home/view/onboarding_home_view_test.dart` | Vue onboarding |
| `test/home/view/trip_manager_home_view_test.dart` | Vue gestionnaire |
| `test/home/view/active_trip_home_view_test.dart` | Vue voyage actif |

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Quick Action "Weather" | Le callback est `() {}` (noop) dans `quick_actions_bar.dart` L62-63. Aucune vue meteo detaillee n'est accessible depuis la home. | P1 |
| Quick Action "Photo" | Le callback est `() {}` (noop) dans `quick_actions_bar.dart` L80. Aucune integration camera/galerie. | P1 |
| Quick Action "AI Suggestion" | Le callback est `() {}` (noop) dans `quick_actions_bar.dart` L89. Devrait proposer des suggestions IA contextuelles. | P2 |
| Quick Action "Tomorrow" | Le callback est `() {}` (noop) dans `quick_actions_bar.dart` L104. Devrait naviguer vers un apercu des activites du lendemain. | P2 |
| Dark mode des destinations d'inspiration | Les gradients dans `inspiration_destination.dart` (L41, L48) utilisent des `Color()` en dur (`0xFFE67E22`, `0xFF27AE60`, etc.) au lieu de `AppColors.*`. | P2 |
| Carousel completed : absence de `onArchive` | Dans `completed_trips_carousel.dart`, le `TripCard.large` n'a pas de callback `onArchive`, contrairement au `TripCard` standard dans `_LegacyTripList`. | P2 |
| Offline : pas de sync queue pour les transitions ratees | `trip_mode_detector.dart` fait une transition optimiste offline mais ne stocke pas les transitions a rejouer quand la connexion revient. Les `failedTrips` sont traites comme des transitions reussies cote UI (L136-143 de `home_bloc.dart`). | P1 |
| Test : dialog de fin de voyage | Aucun test widget pour le dialog `_showCompletionDialog` dans `active_trip_home_view.dart`. | P2 |
| Test : quick actions contextuelles | Aucun test unitaire pour `resolveContextualActions` dans `contextual_actions_helper.dart`. | P2 |
