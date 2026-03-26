# Post-Trip (Apres Voyage)

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

Le module Post-Trip couvre l'experience utilisateur apres la fin d'un voyage : detection automatique de la fin du trip, transition vers le statut COMPLETED, page de souvenirs avec statistiques, formulaire de feedback (note, points forts/faibles, recommandation, note IA), liste des avis, et suggestion IA de prochain voyage basee sur l'historique des feedbacks. Ce module implique des composants Flutter (PostTripBloc, FeedbackBloc) et des services API (FeedbackService, PostTripAIService, TripsService).

## Transition vers COMPLETED

### Detection automatique (mobile)

Le `HomeBloc` detecte la fin d'un voyage via `detectEndedTrips()` (`bagtrip/lib/home/helpers/trip_end_detector.dart`) :

1. Filtre les trips ONGOING dont `endDate < today`
2. Exclut les trips recemment dismisses (via `PostTripDismissalStorage`)
3. Le premier trip detecte est mis dans `pendingCompletionTrip` du state `HomeActiveTrip`

Le `ActiveTripHomeView` affiche un dialogue adaptatif (`showAdaptiveAlertDialog`) proposant :
- **Confirmer** : `ConfirmTripCompletion` -> appelle `tripRepository.updateTripStatus(tripId, 'completed')`, annule les notifications locales, nettoie le dismiss storage, emet un `completedTripId` pour navigation vers le post-trip
- **Reporter** : `DismissTripCompletion` -> enregistre le dismiss, schedule une notification locale de rappel a 24h via `TripNotificationScheduler.scheduleCompletionReminder()`

### Transition automatique (backend)

Le job `trip_status_job.py` (`api/src/jobs/trip_status_job.py`) effectue un update bulk SQL chaque nuit a minuit UTC :
- `ONGOING -> COMPLETED` : tous les trips dont `end_date < today`
- Envoie des notifications `TRIP_ENDED` aux participants
- Le job redimensionne automatiquement le delai jusqu'au prochain minuit UTC via `_seconds_until_midnight_utc()`

### Protection post-completion

Le `ActivityService._check_trip_not_completed()` empeche toute modification des activites sur un trip COMPLETED (erreur 403 `TRIP_COMPLETED`).

## Page de souvenirs (Post-Trip)

### PostTripBloc

`PostTripBloc` (`bagtrip/lib/post_trip/bloc/post_trip_bloc.dart`) charge les statistiques du voyage en parallele :

1. `_tripRepository.getTripById(tripId)` — details du trip
2. `_activityRepository.getActivities(tripId)` — toutes les activites
3. `_budgetRepository.getBudgetSummary(tripId)` — resume budget

Le state `PostTripLoaded` expose :

| Champ | Description |
|-------|-------------|
| `trip` | Objet Trip complet |
| `totalDays` | Nombre de jours (endDate - startDate + 1) |
| `activitiesCompleted` | Nombre d'activites marquees `isBooked` |
| `totalActivities` | Nombre total d'activites |
| `budgetSpent` | Total depense |
| `budgetTotal` | Budget total prevu |
| `destinationName` | Nom de destination ou titre du trip |
| `categoriesExplored` | Set de categories d'activites uniques |
| `hasAiActivities` | True si au moins une activite est SUGGESTED |

### Page / View

- **`PostTripPage`** (`bagtrip/lib/post_trip/view/post_trip_page.dart`) : cree le `BlocProvider` et fire `LoadPostTripStats`
- **`PostTripView`** (`bagtrip/lib/post_trip/view/post_trip_view.dart`) : `CustomScrollView` avec :

1. **SliverAppBar** : cover image du trip avec `FlexibleSpaceBar`, titre "Souvenirs"
2. **Titre + destination** : nom du voyage et destination
3. **Grille statistiques 2x2** : 4 `_StatCard` avec animations `StaggeredFadeIn`
   - Jours de voyage (icone calendrier)
   - Activites completees X/Y (icone check)
   - Budget depense en EUR (icone wallet)
   - Categories explorees (icone explore, exclut `OTHER`)
4. **CTA "Donner un avis"** : `FilledButton.icon` qui navigue vers `FeedbackRoute`
5. **CTA "Planifier le prochain"** : `OutlinedButton.icon` qui navigue vers `PlanTripRoute`
6. **Bottom padding** adaptatif iOS (100px) / Android (32px)

## Feedback (Avis)

### FeedbackBloc

`FeedbackBloc` (`bagtrip/lib/feedback/bloc/feedback_bloc.dart`) gere 3 events :

| Event | Description |
|-------|-------------|
| `LoadFeedbacks` | Charge les feedbacks existants du trip |
| `SubmitFeedback` | Soumet un nouveau feedback |
| `RequestPostTripSuggestion` | Demande une suggestion IA de prochain voyage |

States specifiques :
- `FeedbackLoaded` : liste de `TripFeedback`
- `FeedbackSubmitted` : confirmation de soumission
- `PostTripSuggestionLoading/Loaded/Error` : pour la suggestion IA

### Formulaire de feedback

`FeedbackFormView` (`bagtrip/lib/feedback/view/feedback_form_view.dart`) :

**Champs du formulaire :**
- **Note globale** (1-5 etoiles, `IconButton` avec tooltip accessible)
- **Points forts** (TextField multi-ligne, optionnel)
- **Points faibles** (TextField multi-ligne, optionnel)
- **Recommandation** (`SwitchListTile.adaptive`, defaut true)
- **Note experience IA** (1-5 etoiles, visible uniquement si `showAiRating = true`)

**Comportement :**
- Si l'utilisateur a deja soumis un feedback (`currentUserId` match), affiche la vue en lecture seule (`_ReadOnlyFeedbackView`)
- Apres soumission, un `AppSnackBar.showSuccess` est affiche
- En bas du formulaire, la section `_PostTripSuggestionSection` propose de decouvrir la suggestion IA

### Vue en lecture seule

`_ReadOnlyFeedbackView` affiche le feedback soumis dans une `Card` bleue avec icone check, les etoiles en lecture seule, les textes, et la section suggestion IA en dessous.

### Liste des feedbacks

`FeedbackListView` (`bagtrip/lib/feedback/view/feedback_list_view.dart`) affiche tous les feedbacks du trip dans une `ListView` avec :
- Etoiles de note
- Date de soumission
- Points forts/faibles
- Icone pouce (recommande ou non)
- `ElegantEmptyState` si aucun feedback

Note : les labels "Points forts", "A ameliorer", "Recommande", "Ne recommande pas" sont en francais en dur dans ce fichier au lieu d'utiliser l10n.

### Modele TripFeedback

`bagtrip/lib/models/feedback.dart` (Freezed) : `id`, `tripId`, `userId`, `overallRating` (int), `highlights`, `lowlights`, `wouldRecommend` (bool), `aiExperienceRating` (int?), `createdAt`.

## Suggestion IA post-voyage

### Declenchement

1. L'utilisateur soumet un feedback ou consulte son feedback existant
2. Un bouton "Decouvrir votre prochain voyage" apparait dans `_PostTripSuggestionSection`
3. Avant l'appel IA, une verification premium est effectuee : si l'utilisateur est `isFree`, `PremiumPaywall.show()` est affiche
4. Sinon, `RequestPostTripSuggestion` est fire dans le `FeedbackBloc`
5. Le bloc appelle `_aiRepository.getPostTripSuggestion()`

### API Backend

**Route** : `POST /v1/ai/post-trip-suggestion` (`api/src/api/ai/post_trip_routes.py`)

**Acces** : `require_ai_quota` + `require_premium`

**Service** : `PostTripAIService.suggest_next_trip()` (`api/src/services/post_trip_ai_service.py`)

**Logique :**
1. Recupere les 10 derniers feedbacks de l'utilisateur avec les trips associes (join Feedback + Trip)
2. Construit un prompt avec l'historique : destination, note, points forts/faibles, recommandation
3. Appelle le LLM avec un system prompt qui demande une reponse JSON structuree
4. Le LLM retourne une suggestion avec : destination, pays, duree, budget, description, `highlightsMatch` (ce qui a plu retrouve dans la suggestion), et liste d'activites proposees
5. Le quota IA est incremente

**Schema de reponse** (`api/src/api/ai/post_trip_schemas.py`) :

```
PostTripSuggestion:
  destination: str
  destinationCountry: str
  durationDays: int
  budgetEur: int
  description: str
  highlightsMatch: list[str]
  activities: list[PostTripActivity]
    - title, description, category, estimatedCost
```

### Affichage de la suggestion

`_PostTripSuggestionCard` dans `feedback_form_view.dart` affiche :
- Icone "auto_awesome" + titre "Prochain voyage"
- Destination + pays en gros
- Chips duree et budget
- Description (3 lignes max)
- Tags `highlightsMatch` en chips

`PostTripSuggestionView` (`bagtrip/lib/feedback/view/post_trip_suggestion_view.dart`) est une vue dediee avec en plus :
- Section "Bases sur vos preferences" avec chips check
- Section "Activites proposees" avec cards ListTile
- Bouton "Creer ce voyage" (actuellement fait juste `Navigator.pop()`)

## API Feedback

### Routes (`api/src/api/feedback/routes.py`)

| Methode | Endpoint | Description | Acces |
|---------|----------|-------------|-------|
| `POST` | `/v1/trips/{tripId}/feedback` | Creer un feedback | Owner + Viewer |
| `GET` | `/v1/trips/{tripId}/feedback` | Lister les feedbacks | Owner + Viewer |

### Schemas (`api/src/api/feedback/schemas.py`)

- `FeedbackCreateRequest` : `overallRating` (1-5, requis), `highlights`, `lowlights`, `wouldRecommend` (requis), `aiExperienceRating` (1-5, optionnel)
- `FeedbackResponse` : mapping complet avec aliases snake_case
- `FeedbackListResponse` : `items: list[FeedbackResponse]`

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| CTA "Creer ce voyage" non-fonctionnel | Le bouton dans `PostTripSuggestionView` fait juste `Navigator.pop()` au lieu de pre-remplir un formulaire de creation de trip avec les donnees de la suggestion (`bagtrip/lib/feedback/view/post_trip_suggestion_view.dart` l.104-106) | P1 |
| Strings en dur dans FeedbackListView | "Points forts", "A ameliorer", "Recommande", "Ne recommande pas", "Aucun avis" sont en francais en dur au lieu d'utiliser l10n (`bagtrip/lib/feedback/view/feedback_list_view.dart` l.17, l.57, l.61, l.82, l.84) | P1 |
| Pas de pagination feedback | L'endpoint `GET /feedback` ne supporte pas la pagination — renvoie tous les feedbacks d'un coup (`api/src/api/feedback/routes.py`) | P2 |
| Pas de suppression/edition de feedback | Un feedback soumis ne peut ni etre modifie ni supprime — pas d'endpoint UPDATE ou DELETE | P2 |
| Pas de galerie photos | La page de souvenirs n'affiche pas de photos du voyage — fonctionnalite mentionnee nulle part dans le code post-trip | P1 |
| Statistiques activites "completed" trompeuses | `activitiesCompleted` est base sur `isBooked` qui signifie "reserve" et non "fait" — pas de champ "done" sur le modele Activity (`bagtrip/lib/post_trip/bloc/post_trip_bloc.dart` l.61) | P1 |
| Navigation post-completion | Apres `ConfirmTripCompletion`, le `completedTripId` est emis dans le state mais la navigation vers la page post-trip n'est pas geree dans `ActiveTripHomeView` — le flux continue vers `RefreshHome()` (`bagtrip/lib/home/bloc/home_bloc.dart` l.273-286) | P1 |
| Tests feedback | Pas de tests pour `FeedbackBloc` ou `PostTripBloc` dans le repertoire test | P1 |
| Couleur en dur | La couleur `Color(0xFFF0F7FF)` est utilisee en dur dans `FeedbackFormView` au lieu d'un token design system (`bagtrip/lib/feedback/view/feedback_form_view.dart` l.237, l.354) | P2 |
