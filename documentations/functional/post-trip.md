# Post-Trip (Apres Voyage)

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

Le module Post-Trip couvre l'experience apres la fin d'un voyage : transition automatique du trip vers `COMPLETED` (cron nuit + fallback mobile), page de souvenirs avec statistiques (jours, activites realisees, budget depense, categories explorees), formulaire de feedback (note globale, points forts/faibles, recommandation, note experience IA) puis suggestion IA "prochain voyage" basee sur un pipeline RAG (embedding BGE-M3 des feedbacks + cosine match sur un catalogue de destinations curee + narration LLM strict-schema). Le feedback est ouvert a tout utilisateur (owner et viewers) sur un trip termine ; la suggestion IA est gated premium ET consomme du quota IA via `require_ai_quota`.

Acteurs impliques : `FeedbackService` + `FeedbackRepository` (CRUD), `PostTripSuggester` (RAG, narration LLM), `TripsService.auto_transition_statuses` (cron), `PlanService.increment_ai_generation` (quota). Cote mobile : `PostTripBloc` (souvenirs), `FeedbackBloc` (form + suggestion), `FeedbackRepository`, `AiRepository.getPostTripSuggestion()`.

## Cote Backend

### Modele Feedback et transition trip

Table `feedbacks` (`api/src/models/feedback.py`) : `id`, `trip_id` (FK trips), `user_id` (FK users), `overall_rating` (int 1-5, requis), `highlights` (text nullable), `lowlights` (text nullable), `would_recommend` (bool, requis), `ai_experience_rating` (int 1-5 nullable), `created_at`. Contrainte d'unicite `(trip_id, user_id)` : un meme utilisateur ne peut soumettre qu'un feedback par trip (owner OU viewer comptent comme un seul feedback chacun, en parallele).

La bascule automatique `ONGOING -> COMPLETED` est portee par `trip_status_scheduler` (`api/src/jobs/trip_status_job.py`). Boucle async qui tourne au boot puis chaque nuit a minuit UTC (delai recalcule via `_seconds_until_midnight_utc()`), sous lock Redis distribue (`redis_lock("job:trip_status", ttl_seconds=600)`) pour eviter les bulk UPDATE concurrents en multi-workers. La logique SQL est dans `TripsService.auto_transition_statuses(db)` qui retourne le tuple `(planned->ongoing, ongoing->completed)`. Une notification `TRIP_ENDED` est ensuite dispatchee aux participants. En parallele du meme tick, `run_stale_draft_gc(max_age_hours=24)` purge les trips en `DRAFT` abandonnes par les wizards SSE (try/except isole pour ne pas annuler la transition de statut).

Apres bascule en `COMPLETED`, `ActivityService._check_trip_not_completed()` bloque toute mutation des activites avec 403 `TRIP_COMPLETED` — meme verrou attendu sur les autres domaines (transport, hotels, budget) qui partagent le snapshot trip.

### Routes feedback

| Methode | Endpoint | Description | Acces |
|---------|----------|-------------|-------|
| `POST` | `/v1/trips/{tripId}/feedback` | Soumettre un feedback | Owner + Viewers (via `TripAccess`) |
| `GET` | `/v1/trips/{tripId}/feedback` | Lister tous les feedbacks du trip | Owner + Viewers |

Implementation `api/src/api/feedback/routes.py` : routes minces qui delegguent a `FeedbackService`, parsing via les schemas Pydantic et `AppError -> HTTPException` via `create_http_exception`.

### Schemas (`api/src/api/feedback/schemas.py`)

- `FeedbackCreateRequest` : `overallRating` (1-5, requis), `highlights` (str?), `lowlights` (str?), `wouldRecommend` (bool, requis), `aiExperienceRating` (1-5, optionnel).
- `FeedbackResponse` : mapping complet avec aliases snake_case (`trip_id`, `user_id`, `overall_rating`, `would_recommend`, `ai_experience_rating`, `created_at`), `model_config = ConfigDict(from_attributes=True, populate_by_name=True)`.
- `FeedbackListResponse` : `items: list[FeedbackResponse]`.

### Service (`api/src/services/feedback_service.py`)

`FeedbackService.create_feedback()` :
1. Verifie que `trip.status == TripStatus.COMPLETED`, sinon 400 `TRIP_NOT_COMPLETED`.
2. Revalide `1 <= overall_rating <= 5` (400 `INVALID_RATING`).
3. Verifie l'unicite `(trip_id, user_id)` en lecture, double-check via `IntegrityError` au commit (race-safe). Renvoie 409 `FEEDBACK_EXISTS` dans les deux cas.
4. Persiste puis `db.refresh(feedback)`.

`get_feedbacks_by_trip()` : `ORDER BY created_at DESC`, sans pagination (renvoie tous les feedbacks d'un coup).
`get_user_feedback()` : helper pour recuperer le feedback courant de l'utilisateur (utilise par la vue read-only cote mobile).

### Suggestion IA post-voyage

**Route** : `POST /v1/ai/post-trip-suggestion` (`api/src/api/ai/post_trip_routes.py`). Deux dependances gates : `require_ai_quota` (decremente le quota generation IA) + `require_premium` (free = 402 `PREMIUM_REQUIRED`). Locale resolue depuis `Accept-Language`.

**Service** : `PostTripSuggester.suggest_next_trip()` (`api/src/services/post_trip_suggester.py`) — pipeline RAG deterministe, LLM narratif uniquement :

1. **Fetch feedbacks** : 10 derniers `(Feedback, Trip)` de l'utilisateur (jointure, `ORDER BY created_at DESC LIMIT 10`). Si vide -> 400 `NO_FEEDBACK_HISTORY`.
2. **Bootstrap catalog** : si `destination_catalog` est vide, `bootstrap_destination_catalog(db)` (couteux la premiere fois, ensuite cache permanent).
3. **Compose corpus** : `_compose_user_corpus()` concatene highlights/lowlights ponderes. Feedback positif (`rating >= 4 AND would_recommend`) : highlights repetes 2x + "loved {destination}". Feedback negatif : lowlights prefixes `avoid:` pour que l'embedding s'eloigne des themes downvotes.
4. **Embed** : `LLMRouter.embed([corpus])` via BGE-M3 (OVH). Echec -> 502 `POST_TRIP_EMBED_FAILED`.
5. **Cosine match** : ranking de tous les `DestinationCatalog` (en excluant les IATA deja visites). Si `match_score < 0.35` : log warn `low confidence` mais on ship quand meme le top-1.
6. **Narration LLM** : la destination est lockee (le LLM ne choisit jamais). `_narrate()` envoie un prompt strict-schema (`response_format=json_schema`, `temperature=0.4`, `max_tokens=900`) qui renvoie `description`, `highlights_match` (2-6 strings), `activities` (3-6 items avec `title`, `description`, `category`, `estimated_cost`). JSON invalide -> 502 `POST_TRIP_INVALID_JSON`.
7. **PlanService.increment_ai_generation(db, current_user)** : quota IA decremente uniquement si la requete a abouti.

Le prompt systeme est genere via `render("post_trip_suggestion", locale=...)` (template Jinja2 EN/FR).

**Schema reponse** (`api/src/api/ai/post_trip_schemas.py`) :
```
PostTripSuggestionResponse:
  suggestion:
    destination: str
    destinationCountry: str
    durationDays: int
    budgetEur: int
    description: str
    highlightsMatch: list[str]
    activities: list[PostTripActivity]  # title, description, category, estimatedCost
```

## Cote Mobile

### PostTripPage (souvenirs)

`PostTripPage` (`bagtrip/lib/post_trip/view/post_trip_page.dart`) : cree le `BlocProvider<PostTripBloc>` et fire `LoadPostTripStats(tripId)`.

`PostTripBloc` (`bagtrip/lib/post_trip/bloc/post_trip_bloc.dart`) charge en parallele via `Future.wait([...])` :
- `_tripRepository.getTripById(tripId)`
- `_activityRepository.getActivities(tripId)`
- `_budgetRepository.getBudgetSummary(tripId)`

Le state `PostTripLoaded` expose : `trip`, `totalDays` (endDate - startDate + 1), `activitiesCompleted` (compte des activites avec `isDone == true`), `totalActivities`, `budgetSpent`, `budgetTotal`, `destinationName`, `categoriesExplored` (Set), `hasAiActivities` (presence d'au moins une activite `ValidationStatus.suggested`). Si la recuperation du trip echoue -> `PostTripError`; les autres echecs degradent silencieusement (compte = 0).

`PostTripView` (`bagtrip/lib/post_trip/view/post_trip_view.dart`) — `CustomScrollView` avec :
1. **SliverAppBar** (height 200, pinned) : `FlexibleSpaceBar` avec cover image (`OptimizedImage.tripCover`) ou primaryContainer en fallback, titre "Souvenirs".
2. **Header** : `trip.title` + `destinationName` (police `FontFamily.b612`).
3. **Grille 2x2** de `_StatCard` (icon + label, primaryContainer rounded `AppRadius.large16`) animees via `StaggeredFadeIn` : jours, X/Y activites realisees, budget en EUR, categories explorees (exclut `ActivityCategory.other`).
4. **CTA "Donner un avis"** (`FilledButton.icon`) -> `FeedbackRoute(tripId).push(context)`.
5. **CTA "Planifier le prochain"** (`ProgressionCtaButton`) -> `PlanTripRoute().push(context)`.
6. **Bottom padding adaptatif** : 100px iOS pour la tab bar, `AppSpacing.space32` Android.

### Formulaire de feedback

`FeedbackBloc` (`bagtrip/lib/feedback/bloc/feedback_bloc.dart`) gere 3 events : `LoadFeedbacks`, `SubmitFeedback`, `RequestPostTripSuggestion`. Repositories injectes : `FeedbackRepository`, `AiRepository`, `AuthRepository`.

`FeedbackFormView` (`bagtrip/lib/feedback/view/feedback_form_view.dart`) :
- **Champs** : rating 1-5 (IconButton etoiles, `tooltip: l10n.starRatingTooltip(...)`), highlights (TextField 3 lignes), lowlights (TextField 3 lignes), wouldRecommend (`SwitchListTile.adaptive`, default true), aiExperienceRating optionnel si `widget.showAiRating == true`.
- **Detection feedback existant** : si `currentUserId` matche un feedback present dans `widget.feedbacks`, bascule sur `_ReadOnlyFeedbackView` (Card `infoBackgroundLight`, icone check, etoiles read-only, texts + section suggestion en bas).
- **Submit** : dispatch `SubmitFeedback(...)`, listener affiche `AppSnackBar.showSuccess(feedbackThanks)` ou `showError(toUserFriendlyMessage(error, l10n))`. Apres `Success`, le bloc re-fire `LoadFeedbacks` pour rafraichir.

### Section suggestion IA + paywall premium

`_PostTripSuggestionSection` (interne au formulaire) :
- Visible si `hasSubmitted == true` ou apres un `FeedbackSubmitted` ou `PostTripSuggestionPremiumRequired` (l'utilisateur peut donc retenter apres avoir vu le paywall).
- Bouton "Decouvrir votre prochain voyage" (`ProgressionCtaButton`, icone `auto_awesome_rounded`) -> dispatch `RequestPostTripSuggestion`.
- **Gate premium cote bloc** : `_onRequestPostTripSuggestion` lit `_authRepository.getCurrentUser()` ; si `user.isFree`, emit `PostTripSuggestionPremiumRequired` (pas d'appel reseau). Sinon emit `PostTripSuggestionLoading` puis `_aiRepository.getPostTripSuggestion()`.
- **Listener UI** : `listenWhen: current is PostTripSuggestionPremiumRequired` declenche `PremiumPaywall.show(context)`.

Resultats :
- `PostTripSuggestionLoading` : `CircularProgressIndicator.adaptive` centre.
- `PostTripSuggestionLoaded` : `_PostTripSuggestionCard` avec destination + pays, chips duree/budget, description (3 lignes max ellipsis), chips `highlightsMatch`.
- `PostTripSuggestionError` : Card `errorBackgroundLight` avec message friendly et bouton retry.

`PostTripSuggestionView` (`bagtrip/lib/feedback/view/post_trip_suggestion_view.dart`) — vue dediee avec en plus : section "Bases sur vos preferences" (chips check), section "Activites proposees" (ListTile cards), bouton "Creer ce voyage" (actuellement un simple `Navigator.pop()`).

### Liste des feedbacks

`FeedbackListView` (`bagtrip/lib/feedback/view/feedback_list_view.dart`) : `ListView.builder` qui rend chaque feedback dans une Card (etoiles + date `dd/MM/yyyy` via `intl`, highlights/lowlights prefixes via `l10n.feedbackHighlightsPrefix` / `feedbackLowlightsPrefix`, icone thumb_up/down + label recommande/non recommande). `ElegantEmptyState` si aucun feedback. Utile principalement en vue partage : un trip avec plusieurs viewers peut accumuler plusieurs feedbacks distincts.

### Modele Flutter (`models/feedback.dart`)

`TripFeedback` (Freezed + `json_serializable`) expose : `id`, `tripId`, `userId`, `overallRating`, `highlights`, `lowlights`, `wouldRecommend`, `aiExperienceRating`, `createdAt`. Mapping snake_case via `@JsonKey(name: ...)`. Le repository `FeedbackRepository` (interface dans `bagtrip/lib/repositories/feedback_repository.dart`) expose `submitFeedback(...)` et `getFeedbacks(...)`, tous deux en `Future<Result<...>>` conformement a la regle architecture.

## Flux

1. **Trip se termine** : le scheduler nuit bascule `ONGOING -> COMPLETED` (job redis-locke) ET dispatch la notification `TRIP_ENDED` aux participants. Cote mobile, en complement, `HomeBloc.detectEndedTrips()` peut proposer un dialogue adaptatif "Voyage termine ?" pour les trips dont `end_date < today` qui n'ont pas encore basculer (fallback temps reel entre deux ticks du cron, dismiss persiste pour 24h).
2. **Verrouillage post-COMPLETED** : toute mutation d'activite est bloquee cote backend (403 `TRIP_COMPLETED`). Le trip reste navigable en read-only. Les notifications locales d'activites planifiees sont annulees cote mobile.
3. **Page souvenirs** : l'utilisateur ouvre `PostTripPage`. `PostTripBloc.LoadPostTripStats` charge trip + activites + budget en parallele ; stats agregees affichees, 2 CTA disponibles (donner un avis, planifier le prochain).
4. **Feedback** : CTA "Donner un avis" -> `FeedbackFormView`. Si deja soumis, vue read-only (`_ReadOnlyFeedbackView`). Sinon, submit -> `POST /v1/trips/{id}/feedback` -> emit `FeedbackSubmitted` + snackbar success + auto `LoadFeedbacks` pour rafraichir.
5. **Suggestion IA** : apres submit (ou en read-only), bouton "Decouvrir prochain voyage" -> dispatch `RequestPostTripSuggestion`. Si `user.isFree` -> emit `PostTripSuggestionPremiumRequired` + `PremiumPaywall.show()`. Sinon `POST /v1/ai/post-trip-suggestion` -> pipeline RAG `PostTripSuggester` -> `_PostTripSuggestionCard` avec destination, chips, description et highlightsMatch.
6. **Replanification** : CTA "Planifier le prochain" -> `PlanTripRoute` (wizard standard). La data de la suggestion n'est pas (encore) injectee comme draft.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| CTA "Creer ce voyage" non-fonctionnel | `PostTripSuggestionView` fait juste `Navigator.pop()` au lieu de pre-remplir un wizard de creation a partir des champs `destination`, `durationDays`, `budgetEur`, `activities` | P1 |
| Pas de pagination feedback | `GET /v1/trips/{id}/feedback` renvoie tous les feedbacks d'un coup, pas de `PaginationParams` ni de `Page[T]` | P2 |
| Pas d'edition ni de suppression de feedback | Aucun endpoint PATCH/DELETE — un feedback soumis est immuable | P2 |
| Pas de galerie photos / souvenirs | Pas de modele Memory ou Photo, pas d'upload S3 dans la page souvenirs ; statistiques uniquement | P1 |
| Strings "Recommande" en dur (legacy) | Verifier que tous les labels passent par `AppLocalizations` (cf. l10n keys `feedbackRecommends`, `feedbackNotRecommends`) | P3 |
| Tests | Pas de tests dedies pour `FeedbackBloc`, `PostTripBloc`, `PostTripSuggester` (RAG pipeline) ni les routes feedback | P1 |
| Navigation post-completion | Apres `ConfirmTripCompletion` dans `HomeBloc`, `completedTripId` est emis mais aucune navigation auto vers `PostTripPage` — l'utilisateur doit y revenir manuellement | P1 |
| Faible confidence non remontee | `PostTripSuggester` log `low_confidence` quand `match_score < 0.35` mais ne le surface pas dans la reponse API ; l'UI ne peut pas warn l'utilisateur | P3 |
| Couleurs / cards en dur | `Color(0xFFF0F7FF)` etait utilise dans `FeedbackFormView` ; verifier la suppression complete au profit de `AppColors.infoBackgroundLight` | P3 |
