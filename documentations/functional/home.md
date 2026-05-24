# Page d'accueil (Home)

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

La Home de BagTrip est une page mobile contextuelle : son rendu change selon l'etat du portefeuille de voyages de l'utilisateur (aucun voyage, voyage en cours, voyages a venir uniquement). Elle alimente deux usages :

- mode "compagnon" quand un voyage est en cours : hero immersif avec destination, plage de dates, anneau de completion, activite mise en avant, meteo ;
- mode "gestionnaire" sinon : greeting time-aware, banniere de reprise (si un ongoing est mis en arriere-plan par l'utilisateur), liste des prochains voyages, CTA de creation.

Cote backend, la Home n'a pas d'endpoint dedie. Elle agrege trois appels paralleles a `GET /v1/trips?status=...` (un par statut), plus `GET /v1/users/me`, plus en mode compagnon `GET /v1/trips/{id}/activities` et `GET /v1/trips/{id}/weather`. Les jobs serveur effectuent les memes transitions de statut que le client (en bulk quotidien) pour garder la liste coherente.

## Cote Backend

Module : `api/src/api/trips/routes.py` + `api/src/services/trips_service.py`.

### Endpoints consommes par la Home

| Methode | Path | Role |
|---------|------|------|
| GET | `/v1/trips?status=<status>&page=<n>&limit=<n>` | Liste paginee filtree par statut (`ongoing` / `planned` / `completed`) |
| GET | `/v1/trips/grouped` | Variante non paginee : dict `{ongoing, planned, completed}` (utilise par `LoadTrips` historique) |
| GET | `/v1/users/me` | Utilisateur courant (greeting + fallback) |
| GET | `/v1/trips/{id}/activities` | Activites du voyage actif (timeline du jour) |
| GET | `/v1/trips/{id}/weather` | Resume meteo destination (Amadeus + meteo) |
| PATCH | `/v1/trips/{id}/status` | Transition manuelle (DRAFT->PLANNED->ONGOING->COMPLETED) |

Le service `TripsService.get_trips_by_user_paginated` fait union_all entre les trips possedes (`Trip.user_id`) et ceux partages via `TripShare` (role VIEWER/EDITOR), ordonnes par `created_at DESC`. Le filtre `status` accepte des alias historiques (`draft`, `planning`, `planned` pour le bucket `planned`, `active` pour `ongoing`, `archived` pour `completed`) pour rester compatible avec les anciens enregistrements.

### Grouping serveur

`TripsService.get_grouped_trips` recharge toute la liste puis dispatch en trois buckets selon `Trip.status`. La Home n'utilise plus cet endpoint en runtime (couteux : pas de pagination), elle prefere trois appels pagines en parallele avec `limit=5`.

### Pagination

`PaginationParams` (`api/src/api/common/pagination.py`) injecte `page` (>=1) et `limit` (1..100, defaut 20). La reponse `TripPaginatedResponse` ramene `items`, `total`, `page`, `limit`, `totalPages` (camelCase via alias generator). Le mobile envoie `limit=5` pour les fetchs Home et `limit=20` pour le tab manager.

### Completion percentage

`_enrich_with_completion` est appele sur toutes les listes Home. Le calcul (`TripsService.compute_completion_batch`) est en quatre segments (flights / accommodations / activities / baggage), chacun 0-100, agreges en moyenne. `flights_tracking` ou `accommodations_tracking` en `SKIPPED` force le segment a 100 (utilisateur reserve hors-app). VALIDATED et MANUAL comptent comme "fait", SUGGESTED ne compte pas.

### Transitions de statut automatiques

`TripsService.auto_transition_statuses` (job quotidien) :

- PLANNED -> ONGOING quand `start_date <= today` ;
- ONGOING -> COMPLETED quand `end_date < today` ;
- envoie `TRIP_STARTED` aux participants au demarrage, `TRIP_ENDED` a la cloture.

Les transitions manuelles passent par `update_trip_status` avec garde sur `VALID_TRANSITIONS`. La cloture manuelle ONGOING->COMPLETED declenche aussi `TRIP_ENDED` (route trips/routes.py L323-336).

### Controle d'acces

`TripAccess` (`api/src/api/auth/trip_access.py`) injecte `(trip, role)` pour toute route `/{tripId}/...`. Pas d'acces -> 404 (ne fuite pas l'existence du trip). Le champ `role` est ramene dans `TripResponse.role` (OWNER / EDITOR / VIEWER) et lu par la Home pour adapter l'affichage.

## Cote Mobile

Module : `bagtrip/lib/home/`.

### Layering BLoC

Deux BLoCs cohabitent. Le decoupage est volontaire : la Home a sa propre logique de detection contextuelle, distincte de la liste paginee multi-onglets.

| BLoC | Scope | Role |
|------|-------|------|
| `HomeBloc` | app-level (`MultiBlocProvider` dans `main.dart`) | Detection contextuelle, mode compagnon vs gestionnaire, dialogs de fin de voyage, sync offline |
| `TripManagementBloc` | app-level egalement | Listes paginees par status pour le tab manager et la page `trips_list_view` |

`HomeBloc` est garde vivant entre navigations pour eviter le re-fetch complet a chaque retour sur Home. `HomePage.build()` ne dispatch `LoadHome` que si `state is HomeInitial` (premiere visite), et lance en parallele trois `LoadTripsByStatus(status: ...)` sur `TripManagementBloc` pour pre-remplir les onglets.

### HomeBloc — events et states

Fichier : `lib/home/bloc/home_bloc.dart` (+ part files `home_event.dart`, `home_state.dart`).

Events publics :

| Event | Source | Effet |
|-------|--------|-------|
| `LoadHome` | `HomePage.build` (premier appel) | Emit `HomeLoading` puis fetch contextuel |
| `RefreshHome` | Pull-to-refresh, `HomeView._refreshData` | Refetch sans shimmer plein ecran (shimmer top 3px) |
| `ConfirmTripCompletion` | Dialog de fin de voyage | PATCH status -> `completed`, emit intermediate avec `completedTripId` puis refresh + navigation `PostTripRoute` |
| `DismissTripCompletion` | Dialog "Plus tard" | Stocke un dismiss 24h via `PostTripDismissalStorage` (Hive) |
| `PreferIdleHomeOverview` | Banniere "Voyages & accueil" depuis le hero actif | Force le retour en `HomeIdle` malgre un ongoing existant |
| `ResumeActiveTripHome` | Banniere de reprise sur `HomeIdle` | Reactive le mode compagnon |
| `CompleteActiveTrip` | Sheet de cloture explicite | PATCH status puis refresh |
| `ResetHome` | Logout | Repasse a `HomeInitial` |
| `_ConnectivityRestored` | Listener interne sur `ConnectivityService` | Replay des transitions PLANNED->ONGOING faites offline |

States (sealed) :

- `HomeInitial` / `HomeLoading` -> `LoadingView` ;
- `HomeError(error)` -> `ErrorView` avec retry ;
- `HomeIdle(user, upcomingTrips, completedTrips, nextTrip, nextTripCompletion, backgroundOngoingTrip)` -> `IdleHomeView` (greeting + liste prochains voyages + CTA) ;
- `HomeActiveTrip(activeTrip, todayActivities, weatherSummary, weatherData, allActivities, upcomingTrips, pendingCompletionTrip, completedTripId)` -> `ActiveTripHomeView` (hero immersif + highlight + prochains voyages).

### Decision tree (`_fetchAndEmitContextualState`)

1. Fetch parallele : `getCurrentUser`, trois `getTripsPaginated(status, limit=5)`.
2. `userResult` AuthenticationError -> `HomeError`.
3. Les trois listes trips en `Failure` -> `HomeError`.
4. `detectAndTransitionTrips` : pour chaque trip `planned` dont `startDate <= now <= endDate`, PATCH status ONGOING (en parallele). Offline -> transition optimiste locale et stockage de l'id dans `_pendingOfflineTransitions` pour replay.
5. `detectEndedTrips` : isole les ongoing dont `endDate < today` non encore dismisses (< 24h). Le premier devient `pendingCompletionTrip` (declenche le dialog).
6. `totalTrips == 0 && ongoing vide` -> `HomeIdle` (mode "nouvel utilisateur").
7. Sinon si ongoing non vide ET pas `_preferIdleDespiteOngoing` -> fetch activites + meteo du trip choisi (`_pickEarliestTrip`) puis `HomeActiveTrip`.
8. Sinon -> `HomeIdle` avec `nextTrip` = premier upcoming par startDate.

### Hero card

Deux variantes du meme template (`HomeTripListCard` pour les list cards, `_ActiveTripHeroCard` pour le hero compagnon, plus une carte `HomeTripListCard` reutilisee par `HomeTripListSection`) :

- image cover via `OptimizedImage.tripCover` (fallback `HomeTripHeroCoverFallback` gradient) ;
- pill statut/countdown en haut a gauche (`HomeTripHeroEyebrowPill` pour ongoing, `HomeTripHeroCountdownPill` "Dans X jours" sinon) ;
- pill voyageurs a cote si `nbTravelers > 0` ;
- `CompletionRing` (anneau circulaire) en haut a droite ;
- destination en `dMSerifDisplay` 30pt + date range en `dMSans` 16pt en bas a gauche ;
- tap sur le hero compagnon -> `ActiveTripProgrammeView` (push), tap sur une card de liste -> `TripHomeRoute(tripId).push`.

Sous le hero compagnon, un panneau blanc affiche l'activite mise en avant via `resolveHomeHighlightActivity` (`TimelineActivityRow` en mode `bare`), ou le fallback `l10n.homeNoActivitiesToday`.

### Chips bar / filtres status

La Home elle-meme n'expose pas de chips de filtre (la liste affiche uniquement les `upcomingTrips`). Le filtre par statut vit dans `trips_list_view.dart` via un `DefaultTabController` a trois onglets (Ongoing / Planned / Completed), brancher sur `TripManagementBloc` qui memorise les `TripTabData` par status (items, currentPage, totalPages, isLoadingMore). Pagination cumulative via `LoadMoreTripsByStatus` (concatene `[...tabData.trips, ...data.items]`).

### Layout (`HomeTwoZoneLayout`)

Deux zones :

- **Top zone** : fond `ColorName.primaryDark`, status bar absorbe quand `_extendsBehindStatusBar(state)` (active trip ou idle), contient `HomeGreetingHeader` (greeting + subtitle) puis les `topChildren` (hero ou banniere de reprise).
- **Bottom zone** : feuille blanche `ColorName.surfaceLight`, radius top 32, hauteur minimale 42% viewport, contient `bottomChildren` (liste prochains voyages, `CreateTripCard`). Padding bottom integre la `BottomTabBar` iOS via `BottomTabBar.visualHeight(context)`.

`AnimatedSwitcher` 500 ms (`AppAnimations.springCurve` entree, `easeIn` sortie) + fade + slide vertical 5% pour toutes les transitions de state.

### Transitions visuelles

- `HomeIdle -> HomeActiveTrip` : `BlocListener` haptic `success`.
- `HomeActiveTrip` avec `completedTripId` non null : haptic + navigation push vers `PostTripRoute(tripId)`.
- Pull-to-refresh : flag `_topShimmer` active une barre shimmer 3px en haut pendant 750 ms minimum.

### Banniere de reprise

Sur `HomeIdle`, si `backgroundOngoingTrip != null`, un `_OngoingTripResumeBanner` apparait avant le greeting subtitle. Tap -> `ResumeActiveTripHome` qui repasse en mode compagnon. La banniere existe uniquement quand l'utilisateur a explicitement choisi `PreferIdleHomeOverview` depuis le hero actif.

## Etats home

| Etat | Condition | UI |
|------|-----------|----|
| Loading | `HomeInitial` ou `HomeLoading` | `LoadingView` plein ecran |
| Error | Auth ratee ou 3 listes trips KO | `ErrorView` + retry |
| Nouvel utilisateur | `totalTrips == 0 && ongoing.isEmpty` | `IdleHomeView` : greeting "bienvenue", subtitle vide, `CreateTripCard` centree (`isFirstTrip: true`) |
| Compagnon (voyage actif) | `ongoing.isNotEmpty && !_preferIdleDespiteOngoing` | `ActiveTripHomeView` : hero immersif `_ActiveTripHeroCard` + section "Prochains voyages" + `CreateTripCard` |
| Gestionnaire (idle avec voyages) | `ongoing.isEmpty && (planned ou completed non vides)` | `IdleHomeView` : greeting time-aware + liste prochains voyages + `CreateTripCard` standard |
| Idle override | `ongoing.isNotEmpty && _preferIdleDespiteOngoing` | `IdleHomeView` + `_OngoingTripResumeBanner` en topChildren |
| Dialog fin de voyage | `HomeActiveTrip.pendingCompletionTrip != null` | Dialog adaptatif "Confirmer" / "Plus tard" superpose au hero |

## Flux

### Premier chargement (cold start)

1. `main.dart` instancie `HomeBloc` et `TripManagementBloc` dans le `MultiBlocProvider` app-level.
2. `AppShell` navigue vers `/home`. `HomePage.build` voit `state is HomeInitial`, dispatch `LoadHome` + trois `LoadTripsByStatus`.
3. `HomeBloc` emit `HomeLoading`, lance `Future.wait` sur user + 3 trips pagines.
4. `detectAndTransitionTrips` regle les PLANNED arrives a `startDate`. Online -> PATCH bulk. Offline -> optimiste + queue.
5. `detectEndedTrips` filtre ongoing termines, sort la dismissal storage 24h.
6. Decision tree -> emit du state final. La vue switch via `AnimatedSwitcher`.

### Pull-to-refresh

`HomeView._onPullRefresh` set `_topShimmer = true`, dispatch `RefreshHome` (refetch sans `HomeLoading`) + recharge les trois tabs `TripManagementBloc`. Min 750 ms d'animation pour que la barre soit perceptible.

### Confirmation cloture voyage

1. `_showCompletionDialog` rend un dialog adaptatif avec `pendingCompletionTrip`.
2. Tap "Confirmer" -> `ConfirmTripCompletion(tripId)` -> PATCH `/v1/trips/{id}/status {status: completed}`.
3. `HomeBloc` emit intermediate `HomeActiveTrip(completedTripId: ...)` -> le listener pousse `PostTripRoute(tripId)`.
4. `RefreshHome` redispatch, le trip passe en bucket `completed`, on retombe sur `HomeIdle` ou un autre `HomeActiveTrip`.

### Reprise online

`ConnectivityService.onConnectivityChanged` emit `true` -> handler `_onConnectivityRestored` iter sur `_pendingOfflineTransitions`, PATCH chaque id, retire les succes de la queue, redispatch `RefreshHome` si au moins une sync a passe.

## Ce qu'il manque

| Item | Description | Priorite |
|------|-------------|----------|
| Endpoint Home agrege | Les trois `getTripsPaginated` paralleles + user + activities + weather pourraient etre un seul `/v1/home` cote API (5 round-trips reduits a 1, gain perceptible offline-first et reseau mobile). | P1 |
| Chips de filtre Home | La Home n'expose pas de filtre status, il faut quitter vers `trips_list_view` pour voir un bucket precis (completed notamment). Une chips bar inline aiderait. | P2 |
| Offline write queue persistante | `_pendingOfflineTransitions` vit en memoire du `HomeBloc` ; un kill de l'app entre la transition optimiste et le `_ConnectivityRestored` perd la queue. `OfflineWriteQueue` existe dans le core mais n'est pas branchee ici. | P1 |
| Test widget dialog fin de voyage | Le dialog adaptatif `_showCompletionDialog` n'a pas de test widget dedie (couvert indirectement via `home_bloc_test`). | P2 |
| `daysUntilNextTrip` ignore les timezones | Calcul sur `DateTime.now()` local au lieu de `nowInDestination(trip.destinationTimezone)`, ce qui peut afficher "Dans 0 jour" un peu trop tot/tard selon le decalage. | P3 |
| Pas de cache local Home | Aucune lecture/ecriture sur `CacheService` pour le payload Home (contrairement a trip detail). Premier launch offline = `HomeError` direct. | P2 |
| `LoadTrips` non utilise en runtime | L'event existe et appelle `getGroupedTrips`, mais aucun ecran ne le dispatch. Dette technique a nettoyer. | P3 |
