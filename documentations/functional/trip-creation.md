# Creation de voyage - Wizard de planification

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip cree un voyage via un wizard 6 etapes (5 en flow manuel) qui guide
l'utilisateur des contraintes (dates, voyageurs, budget) jusqu'a un plan genere
par un agent multi-agent LangGraph et confirme par l'utilisateur. Cote mobile,
l'experience est portee par un `PlanTripBloc` unique couple a un `PageView` sans
swipe, qui consomme un flux Server-Sent Events ouvert sur
`/v1/ai/plan-trip/stream`. Le serveur centralise toute la logique : orchestration
LangGraph, persistance du DRAFT trip, creation des sous-entites (activites,
transports, hebergements, bagages, budget) et livraison d'un `tripId` dans l'event
terminal `complete`. L'endpoint `POST /v1/trips` reste disponible pour la creation
manuelle "vide" mais le chemin nominal des deux flows passe par le pipeline SSE.

Deux variantes coexistent :

- **Flow IA "Inspire-moi"** : l'utilisateur ne sait pas ou aller. Le bloc tire le
  pipeline en mode `destinations_only`, affiche un carousel de propositions, et
  bascule sur le pipeline complet a la selection.
- **Flow manuel** : l'utilisateur tape sa destination (`aviation_data` offline,
  Amadeus indirect). Le wizard saute l'etape propositions et la destination est
  forcee dans la payload SSE.

Quota IA, persistance et redirection vers la page detail sont identiques dans les
deux cas.

## Cote Backend

### POST /v1/trips (creation manuelle)

Defini dans `api/src/api/trips/routes.py:47`. Cree un trip "vide" a partir d'un
`TripCreateRequest`. Point d'entree historique conserve pour les imports manuels :

- Auth via `Depends(get_current_user)`.
- Validation Pydantic : `destinationName` ou `destinationIata` requis,
  `startDate <= endDate`, `startDate >= today`.
- Cover image auto-fetch via `unsplash_client.fetch_cover_image` si absente
  (fallback gradient).
- `TripsService.create_trip(...)` insere le `Trip` en `DRAFT`, ajoute le createur
  comme premier `TripTraveler` (`traveler_type=ADULT`), commit, refresh.
- Reponse `TripResponse` 201 enrichie d'un `completionPercentage` (0 a la
  creation), role `OWNER`.

Champs : `title`, `originIata`, `destinationIata`, `destinationName`, `startDate`,
`endDate`, `description`, `nbTravelers`, `coverImageUrl`, `budgetTarget`, `origin`
(`MANUAL`/`AI`), `dateMode` (`EXACT`/`MONTH`/`FLEXIBLE`).

### POST /v1/ai/plan-trip/stream

`api/src/api/ai/plan_trip_routes.py` - seul endpoint SSE. La route parse
`PlanTripRequest`, verifie le quota via `Depends(require_ai_quota)` et delegue a
`TripPlannerService.stream_plan`.

`require_ai_quota` (`api/src/api/auth/plan_guard.py`) appelle
`PlanService.check_ai_generation_quota` : reconciliation Stripe -> lecture de
`PLAN_LIMITS[plan]["ai_generations_per_month"]` -> auto-reset si mois ecoule ->
raise `AppError("AI_QUOTA_EXCEEDED", 402)` si epuise. Compteur incremente
seulement a la fin d'un run reussi (`increment_ai_generation`).

`TripPlannerService.stream_plan(request, user_id, db)` :

- `mode == "destinations_only"` -> `InspireOrchestrator.stream(...)` emet
  `progress`, `destinations`, `done`. Rien n'est persiste.
- Sinon -> `FullPlanOrchestrator.stream(...)` emet `progress`, `destinations`,
  `weather`, `activities`, `accommodations`, `transport`, `baggage`, `budget`,
  parfois `warning`. Le `complete` interne porte un `trip_draft` (dict) intercepte
  par le service.
- Reconstruction d'un `TripDraftCommand` typed via `_trip_draft_from_dict`, puis
  passe deterministe `schedule_activities(cmd)` (assignation jours + creneaux
  morning/afternoon/evening via `_TIME_OF_DAY_MAP` 9:00/14:00/19:00).
- `PlanDraftService.create_draft_from_command(db, user, cmd)` cree le `Trip`
  (`origin=TripOrigin.AI`, `status=DRAFT`, `date_mode=EXACT`) via
  `TripsService.create_trip`, puis insere : `Activity` (`validation_status=SUGGESTED`),
  `Accommodation` (source `amadeus`/`estimated`), `ManualFlight` pour chaque
  `TransportLeg` OUTBOUND/RETURN (mode FLIGHT/TRAIN), `BaggageItem`, `BudgetItem`
  pour transport/accommodation/food/activity.
- Emit du `complete` final `{"tripId", "status", "tripDraft"}` puis
  `PlanService.increment_ai_generation(db, user)`.
- `try / except / finally` garantit l'emission d'un `error` en cas d'exception et
  d'un `done` final dans tous les cas, meme si le client coupe la connexion.

### GET /v1/travel/locations

`api/src/api/travel/routes.py:38`. Recherche de lieux par mot-cle pour le wizard.
Query : `subType` (`CITY,AIRPORT` ou `CITY`) et `keyword`. Sert
`aviation_data_service.search_by_keyword` sans appel reseau Amadeus (donnees
offline), ce qui permet a la barre de l'etape 2 de debouncer agressivement.
Reponse `LocationSearchResult` (`locations[]` : name, iataCode, city, countryCode,
countryName, subType). L'inspiration Amadeus est consommee indirectement par
`InspireOrchestrator`, pas par la mobile en direct.

## Cote Mobile

### PlanTripBloc - state et events

`bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart` centralise tout. State freezed
unique (`PlanTripState`) avec getters calcules :

| Getter | Role |
|---|---|
| `nbTravelers` | `nbAdults + nbChildren + nbBabies` |
| `areDatesValid` | switch sur `dateMode` |
| `isDestinationValid` | `selectedManualDestination != null || selectedAiDestination != null` |
| `tripDurationDays` | direct (exact) ou preset (flexible/month) |
| `effectiveDurationDays` | `tripDurationDays ?? 7` (toujours non-null pour SSE) |
| `representativeDates` | `(start, end)` resolu pour tous modes (15 du mois en `month`, J+30 en `flexible`) |
| `totalSteps` | 5 (manuel) / 6 (IA) |

Events (sealed) : `loadPersonalization`, `nextStep`/`previousStep`/`goToStep`,
`setDateMode`/`setExactDates`/`setMonthPreference`/`setFlexibleDuration`,
`setTravelerCounts`/`setBudgetPreset`/`setOriginCity`/`searchOrigin`,
`searchDestination`/`selectManualDestination`/`requestAiSuggestions`/
`selectAiDestination`, `swipeProposal`, `startGeneration`/`retryGeneration`,
`createTrip`/`backToProposals`/`updateReviewDates`.

### Etape 0 - Dates (`StepDatesView`)

`FlexibleDatePicker` avec 3 modes :

- **exact** : `startDate` + `endDate`, validation `endDate >= startDate`.
- **month** : `preferredMonth` (1-12) + `preferredYear`.
- **flexible** : `flexibleDuration` (`weekend=3`, `oneWeek=7`, `twoWeeks=14`,
  `threeWeeks=21`).

Bouton "Continuer" actif si `state.areDatesValid`.

### Etape 1 - Voyageurs et budget (`StepTravelersBudgetView`)

- **Ville d'origine** : champ texte, `searchOrigin` -> 
  `LocationService.searchLocationsByKeyword(query, 'CITY')` (max 6). Pre-fill par
  geolocalisation appareil (`GeoLocationService.getNearestCity`) au montage.
  Obligatoire pour le flow IA.
- **Voyageurs** : `TravelerStepper` -> `setTravelerCounts(adults, children,
  babies)`. Categories clampees 0-10 (1-10 pour adults).
- **Budget** : 4 presets via `BudgetChipSelector` : `backpacker` (< 50 EUR/j/p),
  `comfortable` (50-150), `premium` (150-500), `noLimit`. Le clic calcule
  `targetBudget = estimateBudget(preset, nbTravelers, days).max` stocke en state
  et envoye comme contrainte numerique a l'agent.

### Etape 2 - Destination (`StepDestinationView`)

Deux interactions :

- **Recherche manuelle** : `TextField` avec debounce 300 ms (Timer), min 2 chars.
  Dispatch `searchDestination(query)` ->
  `LocationService.searchLocationsByKeyword(query, 'CITY,AIRPORT')` (max 8). La
  selection emit `selectManualDestination(loc)`, met `isManualFlow = true`, permet
  d'avancer a l'etape 4 (3 sautee).
- **Inspire-moi** : bouton gradient -> `requestAiSuggestions(locale)`. Le bloc
  charge `PersonalizationStorage` (travelTypes, budget, companions, constraints),
  calcule la saison via `startDate`/`preferredMonth`, valide `originCity` (sinon
  `ValidationError`), et appelle `AiRepository.getInspiration(...)`.

`AiRepositoryImpl.getInspiration` ouvre en realite un
`planTripStream(mode: 'destinations_only')` et renvoie le premier payload
`destinations` (ou `complete`). Les villes sont mappees en `AiDestination` (city,
country, iata, matchReason, imageUrl, weatherSummary, topActivities). Le listener
de la view emit `goToStep(3)` automatiquement.

### Etape 3 - Propositions IA (`StepAiProposalsView`)

Carousel des `AiDestination`. Chaque `AiDestinationCard` montre image hero, ville,
pays, raison du match, chips meteo + budget, top activites. Clic "Choisir" :
animation 800 ms scale+overlay+fade puis `swipeProposal(currentPage)` qui
selectionne la destination et bascule a l'etape 4.

### Etape 4 - Generation SSE (`StepGenerationView`)

Auto-declenchement : `BlocConsumer.listener` dans `PlanTripFlowPage` emet
`startGeneration(locale)` quand `currentStep == 4 && generationSteps.isEmpty`.

Le bloc :

1. Verifie `user.aiGenerationsRemaining` localement. Si <= 0 ->
   `generationError: 'AI generation quota exceeded'`.
2. Initialise `generationSteps` avec 5 cles en `pending` : `destinations`,
   `activities`, `accommodations`, `baggage`, `budget`.
3. Charge `travelTypes`/`companions`/`constraints` depuis
   `PersonalizationStorage`.
4. `_cancelSseStream()` annule toute souscription precedente.
5. Ouvre `AiRepository.planTripStream(...)` avec `durationDays`, `departureDate`,
   `returnDate`, `nbTravelers`, `originCity`, `destinationCity`,
   `destinationIata`, `budgetPreset`, `targetBudget`, `dateMode`,
   `preferredMonth`, `preferredYear`, `travelTypes`, `companions`,
   `constraints`, `locale`.
6. Attend sur un `Completer<void>` pour garder `emit` valide.

Mapping des events par `_handleSseEvent` :

| event | progress | mutations |
|---|---|---|
| `progress` | inchange | met a jour `generationMessage` |
| `destinations` | 0.2 | `destinations=completed`, `activities=inProgress` |
| `activities` | 0.4 | `activities=completed`, `accommodations=inProgress` |
| `accommodations` | 0.6 | `accommodations=completed`, `baggage=inProgress` |
| `baggage` | 0.8 | `baggage=completed`, `budget=inProgress` |
| `budget` | 0.9 | `budget=completed` |
| `weather`, `transport` | inchange | no-op (state preserve) |
| `warning` | inchange | append a `generationWarnings` |
| `complete` | 1.0 | `pendingTripId`, `generatedPlan=_tripPlanFromDraft(tripDraft)`, `currentStep=5` |
| `error` | inchange | `generationError` |
| `done` | 1.0 | fallback advance a step 5 si pas de plan |

`_tripPlanFromDraft` convertit le `tripDraft` snake_case en `TripPlan` Freezed :
extraction du vol OUTBOUND/RETURN, prix par nuit hotel, agregation budget par
categorie, highlights, descriptions, items bagage, data meteo brut.

UI : avatar IA pulsant (2400 ms boucle), titre anime (timer 420 ms),
`AnimatedSwitcher` sur la checklist, timeout client a 300 secondes. Retry annule
le stream et emit `retryGeneration(locale)`. Back/close declenche
`backToProposals` -> `_cancelSseStream()` + reset des champs generation.

### Etape 5 - Review (`StepReviewView`)

Lecture seule du `TripPlan` (`state.generatedPlan`), sans appel serveur. Sections :
`ReviewCinematicHero` (cover, dates, duree, voyageurs), `ReviewDayTimeline`
(activites schedulees jour par jour), `ReviewRecommendationSection` (repas,
transports locaux), `ReviewBudgetReveal` (total, per-person, ventilation),
`ReviewDecisionInline` (CTA primaire "Creer mon voyage", secondaire "Voir
d'autres destinations").

Le CTA primaire emit `createTrip`. Le handler ne fait **aucun appel reseau** : le
draft est deja persiste, le `pendingTripId` est simplement promu en
`createdTripId`. Si manquant -> `ServerError`. Sinon `PlanTripFlowPage` ecoute la
transition, haptic success + SnackBar + refresh `HomeBloc`/`TripManagementBloc` +
`TripHomeRoute(tripId).go(context)`.

Le CTA secondaire emit `backToProposals` (etape 2 manuel / 3 IA, reset du plan).

## Flux

### Flow IA complet (Inspire-moi)

```
User -> StepDates : setDateMode/setExactDates
User -> StepTravelersBudget : origineVille / voyageurs / budget
User -> StepDestination : "Inspire-moi"
  Bloc -> AiRepository.getInspiration(originCity, ...)
    POST /v1/ai/plan-trip/stream {mode: 'destinations_only'}
    require_ai_quota -> InspireOrchestrator.stream
    SSE: progress -> destinations -> done
  Bloc -> emit aiSuggestions[]
  View -> goToStep(3)
User -> StepAiProposals : swipe + "Choisir"
  Bloc -> swipeProposal -> selectedAiDestination + currentStep=4
View -> auto-fire startGeneration(locale)
  POST /v1/ai/plan-trip/stream {mode: 'full', originCity, destinationCity, destinationIata, ...}
  FullPlanOrchestrator.stream
  SSE: progress -> destinations -> weather -> activities -> accommodations
        -> transport -> baggage -> budget -> complete(tripDraft)
  _trip_draft_from_dict -> schedule_activities
  PlanDraftService.create_draft_from_command
    INSERT Trip(DRAFT, AI), Activities, ManualFlights, Accommodation, BaggageItem, BudgetItem
    COMMIT
  emit complete {tripId, status, tripDraft}
  PlanService.increment_ai_generation
  finally: emit done
  Bloc -> pendingTripId + generatedPlan + currentStep=5
User -> StepReview : "Creer mon voyage"
  Bloc -> createdTripId = pendingTripId
  View -> TripHomeRoute(tripId).go(context)
```

### Flow manuel

Identique a partir de l'etape 2 mais l'utilisateur tape sa ville :

```
User -> StepDestination : tape "Lisbonne" -> selectManualDestination -> isManualFlow=true
User -> "Continuer" -> nextStep (saut step 3 -> step 4)
View -> auto-fire startGeneration(locale)
  Meme pipeline SSE 'full' avec destinationCity/destinationIata forces.
User -> StepReview -> createTrip -> redirect TripHomeRoute
```

### Annulation et retry

- Back/close sur etape 4 -> `backToProposals` -> annulation `_sseSubscription` +
  reset generation.
- Erreur SSE / timeout 300 s -> `retryGeneration` -> annulation + relance.
- `PlanTripBloc.close()` -> annulation systematique pour ne pas fuir une
  souscription.

## Ce qu'il manque

- **Persistance du brouillon cote mobile** : si l'utilisateur quitte avant
  l'etape 5, le `PlanTripBloc` est detruit et le state perdu, alors qu'un `Trip`
  DRAFT existe en DB. Pas de logique pour reprendre un wizard.
- **Cleanup des DRAFTs orphelins** : un trip cree par
  `PlanDraftService.create_draft_from_command` reste en DB meme si l'utilisateur
  ne valide jamais l'etape 5. Pas de job de purge cote API.
- **Quota IA decrement avant validation step 5** : compteur incremente des le
  `complete` SSE, donc un draft jamais valide consomme un quota. A documenter
  cote produit.
- **Image de couverture sur l'etape 4-5** : la cover Unsplash est fetchee cote
  backend mais n'est pas restituee dans le `tripDraft` SSE. La review utilise un
  helper local (`_resolveCoverUrl`).
- **Coverage des events `weather`/`transport`** : no-op cote mobile alors que
  les payloads pourraient enrichir la timeline (meteo jour par jour).
- **Validation step 1 imprecise** : le bouton "Continuer" est toujours actif,
  meme sans interaction utilisateur. Les defaults (1 adulte, pas de budget)
  passent silencieusement.
- **Pas de mode hors-ligne** : le wizard exige une connexion (search + SSE).
  Aucun fallback ni file d'attente.
- **Acceptation partielle** : pas d'option pour valider seulement certaines
  parties du plan IA (garder activites, discarder vols). L'utilisateur edite a
  posteriori dans le trip detail.
