# Mode In-Trip (En Voyage)

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

Le mode In-Trip est le coeur de l'experience utilisateur pendant un voyage. Lorsqu'un trip passe au statut `ONGOING`, la home page se transforme en tableau de bord temps reel : hero card du voyage actif, timeline du jour avec now indicator, activite en cours/a venir, actions rapides contextuelles, previsions meteo, et navigation GPS vers les lieux d'activite. Ce mode est gere par le `HomeBloc` au niveau app (persiste entre navigations) et repose sur plusieurs helpers de detection et de classification.

## Detection automatique du mode voyage

### Cote mobile (Flutter)

Le `HomeBloc` (`bagtrip/lib/home/bloc/home_bloc.dart`) orchestre la detection au chargement :

1. **Fetch parallele** : trips ongoing, planned, completed + utilisateur courant
2. **Detection PLANNED -> ONGOING** : `detectAndTransitionTrips()` (`bagtrip/lib/home/helpers/trip_mode_detector.dart`)
   - Compare `startDate <= today` et `endDate >= today` pour chaque trip PLANNED
   - Online : appelle `tripRepository.updateTripStatus(trip.id, 'ongoing')` en parallele
   - Offline : transition optimiste locale (le trip est traite comme ONGOING sans appel API)
   - Resultat : `TripModeDetectionResult` avec `transitionedTrips` et `failedTrips`
3. **Detection fin de voyage** : `detectEndedTrips()` (`bagtrip/lib/home/helpers/trip_end_detector.dart`)
   - Detecte les trips ONGOING dont `endDate < today`
   - Filtre ceux qui ont ete dismisses recemment (via `PostTripDismissalStorage`)
   - Le premier trip detecte comme termine est mis en `pendingCompletionTrip`
4. **Scheduling des notifications** : quand un trip transite vers ONGOING, les notifications locales sont schedulees en fire-and-forget via `TripNotificationScheduler`

### Cote API (Backend)

Le `trip_status_job.py` (`api/src/jobs/trip_status_job.py`) est un scheduler async qui tourne une fois par nuit (a minuit UTC) :

- Appelle `TripsService.auto_transition_statuses(db)` qui effectue deux updates bulk SQL :
  - `PLANNED -> ONGOING` : `start_date <= today`
  - `ONGOING -> COMPLETED` : `end_date < today`
- Envoie des notifications `TRIP_ENDED` pour les trips nouvellement completes
- Le scheduler utilise `_seconds_until_midnight_utc()` pour calculer le prochain run

La double detection (mobile + API) assure la coherence : le mobile detecte en temps reel a l'ouverture de l'app, le job backend rattrape les transitions pour les utilisateurs qui n'ouvrent pas l'app.

## Arbre de decision du HomeBloc

Le `HomeBloc._fetchAndEmitContextualState()` emet un des 3 states :

| State | Condition | Affichage |
|-------|-----------|-----------|
| `HomeNewUser` | Aucun trip (total = 0) et pas d'ongoing | Ecran d'onboarding |
| `HomeActiveTrip` | Au moins un trip ONGOING | Dashboard in-trip |
| `HomeTripManager` | Des trips existent mais aucun ONGOING | Gestionnaire de voyages |

Pour `HomeActiveTrip`, le bloc selectionne le trip ONGOING avec la `startDate` la plus ancienne (`_pickEarliestTrip`), puis fetch en parallele les activites et la meteo du trip actif.

## Timeline du jour

### Classification des activites

Le helper `classifyTodayActivities()` (`bagtrip/lib/home/helpers/today_activities.dart`) prend la liste complete des activites du trip et retourne un `TodayActivitiesResult` :

| Champ | Description |
|-------|-------------|
| `allDayActivities` | Activites sans `startTime` (journee entiere) |
| `timedActivities` | Activites avec `startTime`, triees chronologiquement |
| `currentActivity` | Activite dont `startTime <= now && endTime > now` (ou la derniere commencee sans `endTime`) |
| `nextActivity` | Premiere activite dont `startTime > now` |
| `nowIndicatorIndex` | Position dans la liste des activites temporisees ou inserer le marqueur "Maintenant" |
| `minutesUntilNext` | Minutes restantes avant la prochaine activite |
| `tomorrowActivities` | Activites du lendemain (apercu) |
| `isTomorrowLastDay` | Vrai si demain = `endDate` du trip |

### Now Indicator

Le `NowIndicatorRow` (`bagtrip/lib/home/widgets/now_indicator_row.dart`) est un trait rouge horizontal avec un point rouge et le label "Maintenant" (localise via `l10n.timelineNow`). Il est insere dans la liste de la timeline a la position `nowIndicatorIndex` calculee par le helper.

### Tick temps reel

Le `TodayTickCubit` (`bagtrip/lib/home/cubit/today_tick_cubit.dart`) emet un nouveau `DateTime.now()` toutes les 60 secondes via un `Timer.periodic`. Ce tick rafraichit :
- La position du now indicator
- L'activite en cours / a venir
- Les minutes restantes avant la prochaine activite
- Les actions rapides contextuelles

Un haptic feedback (`AppHaptics.medium()`) est declenche quand l'activite en cours change.

### Rendu de la timeline

`ActiveTripHomeView` (`bagtrip/lib/home/view/active_trip_home_view.dart`) construit un `CustomScrollView` avec :

1. **Greeting** : "Bonjour {prenom}" avec `StaggeredFadeIn`
2. **Hero card** : `ActiveTripHero` avec cover image, destination, jour X/Y, meteo
3. **Header "Programme du jour"** : en majuscules, style B612
4. **Timeline** : `SliverList` combinant :
   - Activites all-day en haut
   - Activites temporisees avec now indicator intercale
   - Chaque activite est un `TimelineActivityRow`
5. **Section demain** : collapsible, avec badge "Dernier jour" si applicable
6. **Actions rapides** : `QuickActionsBar` contextuel
7. **CTA "Planifier un voyage"** : en bas

## Composants de la timeline

### TimelineActivityRow

`bagtrip/lib/home/widgets/timeline_activity_row.dart` — widget avec animation pulse pour l'activite en cours :

| Prop | Effet visuel |
|------|-------------|
| `isCurrent` | Fond `primaryContainer`, bordure primaire, badge "En cours" pulse anime, point plein avec ring pulse |
| `isNext` | Fond teinte, badge "dans X min" en pill, point plein primaire |
| `isPast` | Opacite reduite (0.6), point vide avec bordure legere |
| normal | Fond surface, point vide |

Chaque row affiche : heure ou "Toute la journee", titre, icone categorie, et un bouton "Naviguer" si un lieu est defini.

Le **pulse** de l'activite en cours utilise un `AnimationController` avec `repeat(reverse: true)` qui anime l'opacite (0.4 -> 1.0) et l'echelle (1.0 -> 1.4) du point et du badge.

### ActiveTripHero

`bagtrip/lib/home/widgets/active_trip_hero.dart` — carte hero cliquable qui navigue vers `TripHomeRoute` :

- Cover image du trip avec gradient overlay
- Nom de destination
- Pill "Jour X / Y"
- Icone + texte meteo (rain/snow/cloud/sunny avec detection par keyword)
- `Hero` tag pour transition animate

## Actions rapides contextuelles

### Logique de resolution

`resolveContextualActions()` (`bagtrip/lib/home/helpers/contextual_actions_helper.dart`) retourne 3 `QuickActionType` selon le contexte :

| Priorite | Condition | Actions |
|----------|-----------|---------|
| 1 | Activite en cours | navigate, expense, photo |
| 2 | Matin (< 12h) + activite a venir | todaySchedule, weather, checkOut |
| 3 | Apres-midi gap + activite a venir | nextActivity, aiSuggestion, map |
| 4 | Soir (>= 18h) + plus d'activite | todayExpenses, tomorrow, budget |
| 5 | Fallback | todaySchedule, weather, budget |

### QuickActionsBar

`bagtrip/lib/home/widgets/quick_actions_bar.dart` — barre de 3 boutons circulaires avec gradient primaire/secondaire. Chaque bouton lance :
- Navigation vers une route (schedule, budget, accommodations, map)
- Ouverture de la bottom sheet depense rapide
- Lancement GPS vers le lieu de l'activite courante/suivante
- Stub pour certaines actions (weather, photo, aiSuggestion, tomorrow)

### Quick Expense Sheet

`QuickExpenseSheet` (`bagtrip/lib/home/widgets/quick_expense_sheet.dart`) permet d'ajouter une depense rapidement via le `QuickExpenseCubit`.

## Navigation Maps

`launchMapNavigation()` (`bagtrip/lib/home/helpers/map_launcher.dart`) gere le lancement de la navigation GPS :

| Plateforme | Comportement |
|-----------|-------------|
| iOS avec Google Maps | Action sheet proposant Apple Maps ou Google Maps |
| iOS sans Google Maps | Apple Maps directement (`maps:?q=...`) |
| Android | Intent `geo:0,0?q=...`, fallback Google Maps web |

Le lieu est URI-encode et passe en query string. La detection de Google Maps se fait via `canLaunchUrl`.

## Detection de fin de voyage

### Dialog de completion

Quand `pendingCompletionTrip` est non-null dans `HomeActiveTrip`, le `ActiveTripHomeView` affiche un `showAdaptiveAlertDialog` proposant :
- **Confirmer** (`ConfirmTripCompletion`) : met le trip en COMPLETED via l'API, annule les notifications locales, navigue vers le post-trip
- **Reporter** (`DismissTripCompletion`) : enregistre le dismiss dans `PostTripDismissalStorage`, schedule une notification de rappel a 24h

Le dialog n'est affiche qu'une seule fois par trip via le flag `_completionDialogShown`.

### Section demain - Dernier jour

Si `isTomorrowLastDay` est vrai (demain = endDate), un badge warning "Dernier jour" est affiche dans le header de la section demain.

### Section demain - Collapsible

`_CollapsibleTomorrowSection` affiche les 3 premieres activites du lendemain avec un bouton "Voir tout (N)" anime (chevron rotation). Les activites supplementaires s'affichent/masquent avec une animation.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Actions rapides stubs | `weather`, `photo`, `aiSuggestion` et `tomorrow` dans `QuickActionsBar` ont des callbacks vides `() {}` — pas de fonctionnalite (`bagtrip/lib/home/widgets/quick_actions_bar.dart` l.62, l.80, l.88, l.103) | P1 |
| Timezone utilisateur | `classifyTodayActivities()` compare les heures en heure locale du device, pas en timezone de la destination — decalage possible si le device n'a pas change de fuseau (`bagtrip/lib/home/helpers/today_activities.dart` l.35-36) | P1 |
| Meteo stub | La meteo est affichee si disponible mais il n'y a pas de page meteo detaillee — le bouton "Meteo" dans les actions rapides ne fait rien | P2 |
| Pas de swipe entre jours | La timeline ne montre que "aujourd'hui" et un apercu de "demain" — pas de navigation horizontale entre les jours du voyage | P2 |
| Transition offline non-syncee | En mode offline, la transition PLANNED->ONGOING est optimiste mais n'est jamais syncronisee quand la connexion revient (`bagtrip/lib/home/helpers/trip_mode_detector.dart` l.46) | P1 |
| Tests unitaires helpers | Pas de tests pour `classifyTodayActivities`, `detectAndTransitionTrips`, `detectEndedTrips` dans le repertoire test | P1 |
| Activite en cours sans endTime | Si une activite a un `startTime` mais pas de `endTime`, elle est consideree "en cours" indefiniment jusqu'a la prochaine activite — pas de timeout automatique (`bagtrip/lib/home/helpers/today_activities.dart` l.63-72) | P2 |
