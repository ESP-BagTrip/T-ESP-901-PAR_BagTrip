# Mode In-Trip (en voyage)

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

Le mode "in-trip" est l'experience compagnon de BagTrip pendant qu'un voyage est en cours. Des qu'un trip bascule au statut `ONGOING`, la home page se reconfigure automatiquement : hero du voyage actif (cover, jour X/Y, meteo de la destination), timeline du jour avec marqueur "Maintenant", navigation vers le programme complet, et liste compacte des prochains voyages. Le mode planning (wizard IA, dashboard de tous les trips) cede sa place a un tableau de bord oriente "ici et maintenant".

Trois conditions co-existent pour amener un utilisateur dans ce mode :

1. cote backend, le job nocturne `trip_status_scheduler` reecrit les statuts en masse selon les dates,
2. cote mobile, le `HomeBloc` detecte localement le passage `PLANNED -> ONGOING` a chaque ouverture,
3. les notifications `TRIP_STARTED` / `TRIP_ENDED` informent l'utilisateur de la transition.

## Detection automatique

### Job backend `trip_status_scheduler`

Le scheduler vit dans `api/src/jobs/trip_status_job.py`. Demarre par le lifespan FastAPI (`src/main.py` l.97-99), il boucle une fois sur startup puis dort jusqu'a minuit UTC (`_seconds_until_midnight_utc()`).

Chaque tick passe par un `redis_lock("job:trip_status", ttl_seconds=600)` pour eviter que plusieurs workers ne rejouent les updates bulk en parallele. Le corps execute `TripsService.auto_transition_statuses(db)` qui realise deux `UPDATE ... SET status` SQL :

| Transition | Condition |
|---|---|
| `PLANNED -> ONGOING` | `start_date IS NOT NULL AND start_date <= today` |
| `ONGOING -> COMPLETED` | `end_date IS NOT NULL AND end_date < today` |

Avant chaque update, le service capture la liste des trips concernes (`starting_trips`, `completing_trips`) pour pouvoir dispatcher les notifications apres commit :

- `NotificationType.TRIP_STARTED` (`data.screen = tripHome`) pour les trips qui demarrent,
- `NotificationType.TRIP_ENDED` (`data.screen = feedback`) pour les trips qui se terminent.

Le meme tick declenche `gc_stale_drafts(max_age_hours=24)` (SMP-324) pour purger les `Trip(status=DRAFT)` orphelins crees par les utilisateurs qui ferment le wizard SSE sans confirmer. Les deux passes sont independantes (try/except disjoints) pour qu'une erreur de purge ne casse pas la transition de statut.

### Detection mobile redondante

Le `HomeBloc` (`bagtrip/lib/home/bloc/home_bloc.dart`) ne fait pas confiance au seul job nocturne. A chaque `LoadHome`, il appelle `detectAndTransitionTrips()` (`home/helpers/trip_mode_detector.dart`) qui compare `startDate <= today <= endDate` sur tous les trips `PLANNED`, puis envoie en parallele un `updateTripStatus(tripId, 'ongoing')` pour chaque match. En offline, la transition reste purement locale (le trip est traite comme ONGOING sans appel API ; le sync reverse n'existe pas encore).

Cette double detection garantit que l'utilisateur voit le mode in-trip des l'ouverture de l'app, meme s'il debarque a 8h du matin et que le scheduler backend n'a pas encore tourne dans son fuseau.

## Cote Backend

### Endpoint meteo `GET /v1/trips/{tripId}/weather`

Defini dans `api/src/api/trips/routes.py` (l.368-421), il prend l'`access: TripAccess` (ownership ou role partage), resout les coordonnees de la destination via `resolve_iata_code(destination_name)` (lookup Amadeus), puis appelle `get_weather(lat, lon, start, end)`.

La fenetre temporelle est bornee :

- `start = max(trip.start_date, today)` (pas de meteo retroactive),
- `end = min(trip.end_date, today + 7 jours)` (open-meteo ne previsionne pas au-dela),
- garde-fou `end = start` si la fenetre est inversee.

La reponse est un `WeatherResponse` aplati (`avg_temp_c`, `min_temp_c`, `max_temp_c`, `description`, `rain_probability`, `source`). Le champ `source` permet au client de distinguer une vraie previsions Open-Meteo (`open-meteo`) d'un fallback climatique (`estimated_climate_zone`).

### Integration Open-Meteo

`src/agent/tools/weather.py` heberge l'appel HTTP. Open-Meteo est gratuit et sans cle API, ce qui evite tout secret a gerer. Cache idempotent (`idempotency_cache.get("get_weather", ...)`) cale sur la cle `(lat, lon, start, end)` pour eviter de re-frapper l'API a chaque ouverture de la home.

En cas d'echec HTTP (status != 200, timeout, exception), `_fallback_weather(start_date, latitude=...)` retourne une estimation par zone climatique (tropical / subtropical / tempere / subarctique) modulee par l'hemisphere. Le `source` devient `estimated_climate_zone` pour que le client puisse afficher un disclaimer si besoin.

### Endpoints lies au mode in-trip

| Endpoint | Role en mode in-trip |
|---|---|
| `GET /v1/trips?status=ongoing` | Liste utilisee par le `HomeBloc` pour selectionner l'active trip |
| `PATCH /v1/trips/{id}/status` | Cible des transitions optimistes mobile (PLANNED -> ONGOING, ONGOING -> COMPLETED) |
| `GET /v1/trips/{id}/activities` | Toutes les activites, classifiees mobile-side pour la timeline |
| `GET /v1/trips/{id}/weather` | Carte meteo du hero |

## Cote Mobile

### Selection de l'active trip

`HomeBloc._fetchAndEmitContextualState()` emet trois states :

| State | Condition | Affichage |
|---|---|---|
| `HomeNewUser` | Aucun trip | Onboarding |
| `HomeActiveTrip` | >=1 trip ONGOING | Mode in-trip |
| `HomeTripManager` | Trips existants, aucun ONGOING | Gestionnaire |

Quand plusieurs trips sont ONGOING (cas rare), le bloc selectionne le plus ancien par `startDate` via `_pickEarliestTrip`. Le bloc fetch ensuite, en parallele, les activites du trip et sa meteo.

### Timeline du jour

`classifyTodayActivities()` (`home/helpers/today_activities.dart`) prend la liste complete et retourne un `TodayActivitiesResult` :

| Champ | Description |
|---|---|
| `allDayActivities` | Activites sans `startTime` (toute la journee) |
| `timedActivities` | Activites avec `startTime`, triees |
| `currentActivity` | `startTime <= now AND (endTime > now OU endTime null)` |
| `nextActivity` | Premiere activite avec `startTime > now` |
| `nowIndicatorIndex` | Position du marqueur "Maintenant" dans la liste |
| `minutesUntilNext` | Minutes avant la prochaine activite |
| `tomorrowActivities` | Apercu du lendemain |
| `isTomorrowLastDay` | Vrai si demain = `endDate` |

La classification couvre les vols (les `ManualFlight` exposes en activites cote home) et les check-in / check-out d'hebergement quand ils sont presents dans la timeline derivee.

### Now indicator

`NowIndicatorRow` (`home/widgets/now_indicator_row.dart`) est un trait horizontal + label "Maintenant" (cle l10n `timelineNow`). Il est insere a la position calculee, repositionne a chaque tick.

Le `TodayTickCubit` (`home/cubit/today_tick_cubit.dart`) emet un nouveau `DateTime.now()` toutes les 60 secondes via `Timer.periodic`. Chaque tick re-classifie les activites et met a jour la position du marqueur, l'activite en cours et `minutesUntilNext`. Un haptic `AppHaptics.medium()` est declenche quand l'activite courante change.

### Weather card

`ActiveTripWeatherCard` (`home/widgets/active_trip_weather_card.dart`) est une pill semi-transparente dans le hero. Elle affiche :

- un glyphe condition (soleil, nuage, pluie, lune selon l'heure locale a la destination via `nowInDestination(destinationTimezone)`),
- la fourchette `min - max` en degres,
- le fallback `l10n.activeTripWeatherUnavailable` si la meteo n'a pas pu etre resolue.

Le repository sous-jacent est `WeatherRepositoryImpl` (`service/weather_service.dart`) qui appelle `GET /v1/trips/{id}/weather`. Il est wrappe par `CachedWeatherRepository` (`service/cached_weather_repository.dart`) :

- TTL 1h dans la box Hive `weather`,
- online : appel reseau + ecriture cache,
- offline : lecture cache, `Failure(UnknownError("No cached weather data available"))` si aucun snapshot.

### Hero et transition UI

`ActiveTripHomeView` (`home/view/active_trip_home_view.dart`) construit le layout `HomeTwoZoneLayout` :

- zone top : `_ActiveTripHeroCard` cliquable (navigation vers `ActiveTripProgrammeView`) avec cover, ring de completion, jour X/Y, weather card,
- zone bottom : liste compacte des prochains trips (`HomeTripListSection`) + `CreateTripCard`.

L'utilisateur tape le hero pour ouvrir le programme detaille (timeline complete avec now indicator). Le `home_page.dart` declenche `LoadHome` une seule fois (check `state is HomeInitial`) pour preserver l'etat entre les navigations shell.

## Flux

### Transition automatique cote backend

```
00:00 UTC -> trip_status_scheduler tick
            -> redis_lock("job:trip_status") acquise
              -> capture starting_trips (PLANNED, start_date <= today)
              -> UPDATE trips SET status='ONGOING' WHERE ...
              -> capture completing_trips (ONGOING, end_date < today)
              -> UPDATE trips SET status='COMPLETED' WHERE ...
              -> commit
              -> dispatch TRIP_STARTED notifs
              -> dispatch TRIP_ENDED notifs
            -> gc_stale_drafts (DRAFT > 24h)
            -> sleep jusqu'au prochain minuit UTC
```

### Ouverture de l'app pendant un voyage

```
user ouvre /home
  -> HomePage check state is HomeInitial -> dispatch LoadHome
  -> HomeBloc fetch trips (ongoing, planned, completed) + user en parallele
  -> detectAndTransitionTrips()
       -> pour chaque PLANNED, si start <= today <= end : updateTripStatus('ongoing') en // 
  -> detectEndedTrips()
       -> pour chaque ONGOING avec end < today : pendingCompletionTrip
  -> _pickEarliestTrip(ongoing)
  -> en parallele : fetch activities + fetch weather (cache 1h)
  -> emit HomeActiveTrip(trip, activities, weather, upcomingTrips, ...)
  -> ActiveTripHomeView rendu (hero + weather pill + upcoming list)
  -> TodayTickCubit demarre (tick 60s)
```

### Affichage du programme detaille

```
tap sur hero -> ActiveTripProgrammeView
  -> classifyTodayActivities(activities, now=tick)
  -> rendu : header "Programme du jour" + all-day + timed avec NowIndicatorRow
  -> chaque TimelineActivityRow porte un etat (past / current pulse / next / normal)
  -> section "Demain" collapsible + badge "Dernier jour" si applicable
```

## Ce qu'il manque

| Element | Description | Priorite |
|---|---|---|
| Sync offline -> online | Les transitions PLANNED->ONGOING optimistes en offline ne sont jamais rejouees au retour du reseau (`trip_mode_detector.dart` l.46) | P1 |
| Timezone destination | `classifyTodayActivities` compare les heures en local device, pas en timezone destination — decalage si le device n'a pas change de fuseau (`today_activities.dart` l.35-36) | P1 |
| Activite sans `endTime` | Une activite avec `startTime` mais sans `endTime` reste "en cours" indefiniment, pas de timeout (`today_activities.dart` l.63-72) | P2 |
| Carte meteo enrichie | Pas de page meteo detaillee (jour par jour, alertes) — la pill du hero est l'unique surface | P2 |
| Navigation jours | Pas de swipe horizontal entre jours du voyage — seuls "aujourd'hui" et un apercu "demain" sont accessibles | P2 |
| Fenetre weather > 7j | `GET /weather` cape a `today + 7` jours ; pour les voyages longs on ne montre jamais la meteo de la fin | P3 |
| Source weather visible | Le client recoit `source` (`open-meteo` vs `estimated_climate_zone`) mais ne l'expose pas a l'utilisateur — pas de disclaimer "estime" | P3 |
| Lock pour mobile detection | Si l'utilisateur ouvre l'app simultanement sur deux devices, deux `PATCH /status` sont envoyes — backend tolere (idempotent) mais genere du bruit log | P3 |
