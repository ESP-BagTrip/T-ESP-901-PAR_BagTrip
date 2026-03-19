# Sprint 2 — Creation de Trip Unifiee

> **Objectif** : Implementer le wizard complet de creation de voyage (6 steps) avec un seul BLoC unifie, remplacant les deux anciens flows (manuel + AI).
> **Dependances** : Sprint 1 (fondation, composants, routes, API validation)
> **Ref design** : Tripsy creation, Hopper flexible dates, Airbnb search

**Ce sprint inclut** : les animations du wizard (transitions entre steps, celebration), les haptics, et les skeleton/shimmer de la generation SSE. Le polish n'est pas differe.

---

## 2.1 — Architecture : PlanTripBloc

### Philosophie

Un seul BLoC remplace `TripCreationBloc` + `CreateTripAiBloc`. State Freezed. Toutes les 6 etapes dans un seul flow.

### Events

```dart
// Navigation
NextStep()
PreviousStep()
GoToStep(int step)

// Step 1 — Dates
SetDateMode(DateMode)          // exact, month, flexible
SetExactDates(DateTime start, DateTime end)
SetMonthPreference(int month, int year)
SetFlexibleDuration(DurationPreset)

// Step 2 — Travelers + Budget
SetTravelers(int count)
SetBudgetPreset(BudgetPreset)

// Step 3 — Destination
SearchDestination(String query)
SelectManualDestination(LocationResult)
RequestAiSuggestions()
SelectAiDestination(AiDestination)

// Step 4 — Proposals (si AI)
SwipeProposal(int index)

// Step 5 — Generation
StartGeneration()
StreamEvent(GenerationEvent)
GenerationComplete(TripPlan)
GenerationError(String message)
RetryGeneration()

// Step 6 — Review
CreateTrip()
BackToProposals()          // "Voir d'autres destinations"
```

### State (Freezed)

```dart
@freezed
abstract class PlanTripState with _$PlanTripState {
  const factory PlanTripState({
    @Default(0) int currentStep,
    // Step 1
    @Default(DateMode.exact) DateMode dateMode,
    DateTime? startDate,
    DateTime? endDate,
    int? preferredMonth,
    int? preferredYear,
    DurationPreset? flexibleDuration,
    // Step 2
    @Default(1) int nbTravelers,
    BudgetPreset? budgetPreset,
    // Step 3
    @Default([]) List<LocationResult> searchResults,
    @Default(false) bool isSearching,
    LocationResult? selectedManualDestination,
    @Default([]) List<AiDestination> aiSuggestions,
    @Default(false) bool isLoadingAiSuggestions,
    AiDestination? selectedAiDestination,
    // Step 5
    @Default({}) Map<String, StepStatus> generationSteps,
    @Default(0.0) double generationProgress,
    String? generationMessage,
    TripPlan? generatedPlan,
    String? generationError,
    // Step 6
    @Default(false) bool isCreating,
    // Meta
    @Default(false) bool isManualFlow, // true si dest manuelle (skip step 4)
  }) = _PlanTripState;
}
```

### Models

```dart
enum DateMode { exact, month, flexible }
enum DurationPreset { weekend, oneWeek, twoWeeks, threeWeeks }
enum BudgetPreset { backpacker, comfortable, premium, noLimit }
enum StepStatus { pending, inProgress, completed, error }

@freezed
abstract class AiDestination with _$AiDestination {
  const factory AiDestination({
    required String city,
    required String country,
    String? iataCode,
    double? lat,
    double? lon,
    String? matchReason,
    String? weatherSummary,
    String? imageUrl,
    @Default([]) List<String> topActivities,
    (double, double)? estimatedBudgetRange,
  }) = _AiDestination;
  factory AiDestination.fromJson(Map<String, dynamic> json) => _$AiDestinationFromJson(json);
}
```

### Taches

- [ ] **BL1 — Creer `PlanTripBloc`**
  - Fichier : `bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart`
  - Implementer tous les events ci-dessus
  - State Freezed avec `copyWith`
  - `close()` override pour cancel les subscriptions SSE
  - **Test** : `plan_trip_bloc_test.dart` — navigation entre steps, chaque event modifie le bon champ

- [ ] **BL2 — Creer les models**
  - `bagtrip/lib/plan_trip/models/` : `date_mode.dart`, `budget_preset.dart`, `duration_preset.dart`, `ai_destination.dart`, `trip_plan.dart`
  - Tous Freezed avec `fromJson`
  - **Test** : JSON round-trip pour chaque model

---

## 2.2 — Step 1 : Dates

### Design

Segment control 3 modes (Dates exactes / Par mois / Flexible). Le picker s'adapte au mode selectionne. Texte resume sous le picker. Bouton "Continuer" conditionnel.

### Taches

- [ ] **S1-1 — Creer `PlanTripFlowPage`**
  - Fichier : `bagtrip/lib/plan_trip/view/plan_trip_flow_page.dart`
  - Wrapper avec `BlocProvider<PlanTripBloc>`
  - `PageView` (pas `IndexedStack`) pour permettre les transitions animees
  - `StepIndicator` en haut (6 dots)
  - Header resume compact (expandable tap)
  - Back button avec confirmation si donnees saisies
  - **Animations** : slide left/right entre steps (spring curve 300ms)
  - **Test** : Navigation entre steps, indicator correct, back confirmation

- [ ] **S1-2 — Creer `StepDatesView`**
  - Fichier : `bagtrip/lib/plan_trip/view/step_dates_view.dart`
  - Segment 3 modes
  - Mode exact : `AdaptiveDatePicker` range
  - Mode mois : `MonthGridPicker` (4x3, mois passes desactives)
  - Mode flexible : `DurationChipSelector` (2x2)
  - Resume text dynamique ("15-22 avril" / "En juin" / "Un week-end")
  - Bouton "Continuer" active ssi selection valide
  - **Haptic** : `AppHaptics.light()` a la selection du mode
  - **Test** : 3 modes fonctionnent, selection callback, bouton enabled/disabled

- [ ] **S1-3 — Creer `MonthGridPicker`**
  - Fichier : `bagtrip/lib/plan_trip/widgets/month_grid_picker.dart`
  - Grid 4x3, 12 mois, selection unique
  - Mois passes grisees et non-selectionnables
  - **Test** : Selection, mois passe disabled, callback

- [ ] **S1-4 — Creer `DurationChipSelector`**
  - Fichier : `bagtrip/lib/plan_trip/widgets/duration_chip_selector.dart`
  - Grid 2x2 : Weekend (2-3j), 1 semaine, 2 semaines, 3 semaines
  - Icone + label + sous-texte
  - Selection unique
  - **Test** : Selection unique, callback

---

## 2.3 — Step 2 : Travelers + Budget

### Design

Stepper voyageurs (1-10 avec bounce animation) + 4 cards budget + estimation dynamique + lien "Je verrai plus tard".

### Taches

- [ ] **S2-1 — Creer `StepTravelersAndBudgetView`**
  - Fichier : `bagtrip/lib/plan_trip/view/step_travelers_budget_view.dart`
  - Stepper + budget cards + estimation dynamique + "Plus tard" link + "Continuer"
  - **Test** : Stepper inc/dec, selection budget, estimation correcte

- [ ] **S2-2 — Creer `TravelerStepper`**
  - Fichier : `bagtrip/lib/plan_trip/widgets/traveler_stepper.dart`
  - Composant controle avec bounce animation sur le chiffre
  - Min 1, max 10
  - **Haptic** : `AppHaptics.light()` a chaque increment
  - **Test** : Bornes respectees, animation

- [ ] **S2-3 — Budget estimation helper**
  - Fichier : `bagtrip/lib/plan_trip/helpers/budget_estimation.dart`
  - Mapping `BudgetPreset → (minPerDay, maxPerDay)` EUR
  - Calcul : `(nbTravelers * dailyMin * days, nbTravelers * dailyMax * days)`
  - **Test** : Combinaisons variees

---

## 2.4 — Step 3 : Destination

### Design

Champ recherche (debounce 300ms) + bouton gradient "Inspire-moi" + separateur "OU" + liste resultats.

### Taches

- [ ] **S3-1 — Creer `StepDestinationView`**
  - Fichier : `bagtrip/lib/plan_trip/view/step_destination_view.dart`
  - Search field + "Inspire-moi" gradient CTA + "OU" separator + resultats
  - Selection manuelle → `isManualFlow = true`, skip step 4, go step 5
  - "Inspire-moi" → go step 4
  - **Haptic** : `AppHaptics.medium()` sur "Inspire-moi"
  - **Test** : Search fires event, inspire fires event, selection navigue

- [ ] **S3-2 — Search destination avec debounce**
  - Reutiliser la logique `LocationService` (Amadeus Location API)
  - `transformer: restartable()` pour debounce
  - **Test** : Resultats retournes, debounce fonctionne, erreurs mappees

- [ ] **S3-3 — Event `RequestAiSuggestions`**
  - Collecter les infos steps 1-2 + preferences de personnalisation
  - Appeler `POST /v1/ai/plan-trip/stream` mode `"destinations_only"`
  - Parser les events SSE type `destinations`
  - **Test** : Params corrects, parsing SSE, check quota

- [ ] **S3-4 — Refactorer `LocationService`**
  - Fichier : `bagtrip/lib/service/location_service.dart`
  - S'assurer qu'il retourne des `LocationResult` avec `iataCode`, `city`, `country`, `flag`
  - Ajouter un cache memoire (`Map`) pour les recherches recentes (eviter les re-fetches Amadeus)
  - **Test** : Unit test — cache hit, cache miss, erreurs

---

## 2.5 — Step 4 : Visualisation & Selection (AI flow only)

### Design

`PageView` carousel de propositions IA. Chaque card : image hero (60%), contenu dessous. Page indicator. Hint "Swipe" auto-dismiss.

### Taches

- [ ] **S4-1 — Creer `StepAiProposalsView`**
  - Fichier : `bagtrip/lib/plan_trip/view/step_ai_proposals_view.dart`
  - `PageView.builder` avec cards, page indicator, bouton "Choisir"
  - Hint "Swipe pour voir les autres →" auto-dismiss apres 3s
  - **Haptic** : `AppHaptics.light()` a chaque swipe
  - **Test** : Cards affichees, swipe fonctionne, selection fire event

- [ ] **S4-2 — Creer `AiDestinationCard`**
  - Fichier : `bagtrip/lib/plan_trip/widgets/ai_destination_card.dart`
  - Image hero + gradient overlay + match reason (italique) + badges meteo/budget + chips activites + CTA "Choisir" + badge IA sparkle
  - **Test** : Golden test light/dark, interactions

- [ ] **S4-3 — Images de destinations**
  - Assets pour top 20 destinations (Paris, Barcelona, Tokyo, etc.)
  - Fallback : image generique continent avec overlay texte
  - Placeholder : skeleton shimmer
  - **Test** : Asset loading, fallback

- [ ] **S4-4 — Animation de selection**
  - Scale 1.05 (200ms spring) → overlay vert avec checkmark → fade autres cards → slide step 5 apres 800ms
  - **Haptic** : `AppHaptics.success()`
  - **Test** : Smooth visuel

---

## 2.6 — Step 5 : Generation IA (SSE Streaming)

### Design

Centrage sur la progression. Lottie animation (assistant au travail). Checklist 6 etapes. Barre de progression. Messages contextuels. Etat erreur avec retry. Timeout 60s.

### Taches

- [ ] **S5-1 — Creer `StepGenerationView`**
  - Fichier : `bagtrip/lib/plan_trip/view/step_generation_view.dart`
  - Lottie animation + checklist animee + barre de progression + messages contextuels
  - Etat erreur avec bouton "Reessayer"
  - Timeout 60s avec message
  - **Skeleton** : shimmer sur les sections en attente
  - **Test** : Affichage initial, progression, completion, erreur

- [ ] **S5-2 — Creer `StreamingChecklist`**
  - Fichier : `bagtrip/lib/plan_trip/widgets/streaming_checklist.dart`
  - Liste de steps avec status (pending/inProgress/completed/error)
  - Spring animation sur les checkmarks
  - **Test** : 4 status par step, transitions animees

- [ ] **S5-3 — SSE streaming dans PlanTripBloc**
  - Consommer le stream SSE `POST /v1/ai/plan-trip/stream`
  - Emettre `StreamEvent` pour chaque event SSE recu
  - Construire le `TripPlan` incrementalement
  - Gerer les erreurs et retry
  - Cancel le stream dans `close()`
  - **Test** : Progression stream, completion, erreur, retry, cancel

- [ ] **S5-4 — Adapter le flow selon le type de destination**
  - Destination manuelle → envoyer `destinationName` + `destinationIata`
  - Destination AI → envoyer la destination selectionnee avec ses donnees
  - Skip les etapes deja completees
  - **Test** : Params differents par mode

---

## 2.7 — Step 6 : Review & Validation

### Design

`CustomScrollView` avec `SliverAppBar` collapsable sur hero. Sections : vols, hebergement, activites par jour, bagages, budget. CTA "Creer mon voyage" + lien "Voir d'autres destinations".

### Taches

- [ ] **S6-1 — Creer `StepReviewView`**
  - Fichier : `bagtrip/lib/plan_trip/view/step_review_view.dart`
  - ScrollView avec toutes les sections + hero parallax + CTAs
  - **Skeleton** : shimmer pendant le chargement du plan
  - **Test** : Toutes les sections rendues, CTA fonctionne

- [ ] **S6-2 — Creer `FlightPreviewCard`**
  - Style boarding pass
  - **Test** : Golden test

- [ ] **S6-3 — Creer `AccommodationPreviewCard`**
  - Image + nom + etoiles + prix + source badge
  - **Test** : Golden test

- [ ] **S6-4 — Creer `DayActivitiesTab`**
  - Tab bar par jour + grid d'activity cards
  - **Test** : Correct nombre de jours, activites par jour

- [ ] **S6-5 — Creer `BudgetBreakdownChart`**
  - Bar chart horizontal avec categories colorees. Total en bas.
  - **Animation** : stagger fade in au chargement
  - **Test** : Valeurs correctes, couleurs par categorie

- [ ] **S6-6 — Event `CreateTrip`**
  - Collecter toutes les donnees du flow
  - Appeler `POST /v1/ai/plan-trip/accept` (AI) ou `POST /v1/trips` (manuel)
  - Naviguer vers `TripDetailRoute(tripId)` au succes
  - Fire `RefreshHome` dans HomeBloc
  - **Haptic** : `AppHaptics.success()` + confetti animation
  - **Test** : Payload correct, navigation on success, error handling

---

## 2.8 — Changements API (integres a ce sprint)

- [ ] **API-1 — Nouveau endpoint `POST /v1/trips/plan`**
  - Endpoint unifie remplacant l'ancien flow
  - Schema `PlanTripUnifiedRequest` avec support des 3 modes de dates
  - Deprecation marker sur les anciens endpoints
  - **Test** : `test_plan_trip_unified.py` — 5 scenarios

- [ ] **API-2 — Support mode `destinations_only`**
  - Param `mode: "destinations_only"` pour le stream SSE
  - Execute uniquement la recherche de destinations, retour rapide (< 10s)
  - **Test** : `test_destinations_only_mode.py`

- [ ] **API-3 — Passer `travelStyle` + `season` aux prompts IA**
  - Deja dans le schema mais pas utilise → injecter dans les prompts
  - **Test** : Prompts contiennent les champs

- [ ] **API-4 — Retry partiel sur echec IA**
  - Retry (1x) chaque node parallele
  - Si echec : continuer mais marquer la section comme `"unavailable"` + warning SSE
  - **Test** : `test_partial_retry.py`

- [ ] **API-5 — `suggested_day` intelligent**
  - Prompt LLM : assigner chaque activite a un jour + time_of_day (morning/afternoon/evening)
  - **Test** : Activities ont `suggested_day` + `time_of_day` valides

- [ ] **API-6 — Persister `origin_iata` et `destination_iata` dans `/accept`**
  - Fichier : `api/src/api/ai/plan_trip_routes.py`
  - Actuellement seul `destination_name` est persiste. Ajouter `origin_iata` et `destination_iata` depuis la suggestion
  - Impact : permet la recherche de vols depuis le trip cree par l'IA
  - **Test** : `test_accept_iata_persistence.py` — trip cree via AI a les IATA codes

- [ ] **API-7 — Persister les items bagages IA (pas les 6 hardcodes)**
  - Fichier : `api/src/api/ai/plan_trip_routes.py`
  - Remplacer les 6 items hardcodes en francais par les items generes par l'IA
  - Fallback : si l'IA n'a pas genere de bagages, utiliser les 6 par defaut en i18n (via accept-language header)
  - **Test** : `test_accept_baggage_items.py` — items = ceux de l'IA, pas les hardcodes

- [ ] **API-8 — Permettre la selection de destination dans le flow AI**
  - Fichier : `api/src/agent/graph.py` + `api/src/agent/nodes/destination_research.py`
  - Le noeud `assemble` prend actuellement le 1er resultat automatiquement
  - Ajouter un param `selectedDestinationIndex` dans la request `/accept`
  - **Test** : `test_accept_destination_selection.py` — la destination choisie est utilisee

- [ ] **API-9 — Ajouter `date_mode` et `budget_preset` au schema `PlanTripRequest`**
  - Fichier : `api/src/api/ai/plan_trip_schemas.py`
  - Ajouter `dateMode: str` (exact / month / flexible), `budgetPreset: str | None` (backpacker / comfortable / premium / noLimit)
  - Mapping interne budget → fourchettes de prix pour guider l'IA
  - **Test** : Schema accepte les nouveaux champs, les rejette si invalides

---

## Tests Sprint 2

### Tests unitaires

| Test | Module | Scenarios |
| --- | --- | --- |
| `plan_trip_bloc_test.dart` | PlanTripBloc | Navigation, dates 3 modes, travelers, budget, search, AI suggestions |
| `plan_trip_bloc_generation_test.dart` | PlanTripBloc | SSE stream, completion, error, retry |
| `plan_trip_bloc_creation_test.dart` | PlanTripBloc | CreateTrip event, payload, navigation |
| `budget_estimation_test.dart` | Budget helper | Combinaisons nbTravelers x preset x duration |
| `date_mode_test.dart` | DateMode model | Exact, month, flexible |
| `ai_destination_test.dart` | AiDestination model | fromJson round-trip |
| `location_service_cache_test.dart` | LocationService | Cache hit, cache miss, erreurs |

### Tests widgets

| Test | Widget | Scenarios |
| --- | --- | --- |
| `step_dates_view_test.dart` | StepDatesView | 3 modes, selection, bouton conditionnel |
| `step_travelers_budget_test.dart` | StepTravelersBudgetView | Stepper, budget cards, estimation |
| `step_destination_test.dart` | StepDestinationView | Search, "Inspire-moi", selection |
| `step_ai_proposals_test.dart` | StepAiProposalsView | Cards, swipe, selection |
| `step_generation_test.dart` | StepGenerationView | Progression, completion, erreur |
| `step_review_test.dart` | StepReviewView | Sections, CTA |
| `month_grid_picker_test.dart` | MonthGridPicker | Selection, mois passe disabled |
| `traveler_stepper_test.dart` | TravelerStepper | Bornes, animation |
| `ai_destination_card_test.dart` | AiDestinationCard | Golden light/dark |
| `streaming_checklist_test.dart` | StreamingChecklist | 4 status, animations |
| `flight_preview_card_test.dart` | FlightPreviewCard | Golden test |
| `budget_breakdown_test.dart` | BudgetBreakdownChart | Valeurs, couleurs |

### Tests integration

| Test | Scenario |
| --- | --- |
| `trip_creation_manual_e2e_test.dart` | Dates exact → 2 travelers → Search "Lisbon" → Generation → Review → Create |
| `trip_creation_ai_e2e_test.dart` | Dates flexible → "Inspire-moi" → Select proposal → Generation → Review → Create |
| `trip_creation_back_nav_test.dart` | Avancer 4 steps → back → donnes preservees → re-avancer |

### Tests API

| Test | Module |
| --- | --- |
| `test_plan_trip_unified.py` | Endpoint unifie (5 scenarios) |
| `test_destinations_only_mode.py` | Mode destination rapide |
| `test_partial_retry.py` | Retry partiel sur echec |
| `test_accept_iata_persistence.py` | IATA persiste a la creation |
| `test_accept_baggage_items.py` | Items bagages IA persistes |
| `test_accept_destination_selection.py` | Destination choisie par l'utilisateur |
| `test_plan_trip_schema.py` | date_mode + budget_preset valides |

---

## Criteres d'acceptation Sprint 2

- [ ] Wizard accessible depuis la Home (toutes les vues)
- [ ] Step 1 : 3 modes de dates fonctionnent
- [ ] Step 2 : Stepper (1-10) + budget preset + estimation dynamique
- [ ] Step 3 : Search avec debounce + "Inspire-moi" declenche l'IA
- [ ] Step 4 : Carousel de propositions IA, l'utilisateur choisit (pas auto-selectionne)
- [ ] Step 5 : SSE streaming avec checklist animee + skeleton loading
- [ ] Step 6 : Review avec vols, hebergement, activites par jour, bagages, budget
- [ ] "Voir d'autres destinations" revient au carousel sans re-fetch
- [ ] Trip cree a les IATA codes (flow AI)
- [ ] Items bagages IA persistes (pas 6 hardcodes)
- [ ] Home refresh apres creation
- [ ] Redirect vers TripDetailRoute (pas HomeRoute)
- [ ] Transitions animees entre steps (slide + spring)
- [ ] Haptics sur les interactions cles
- [ ] "Creer mon voyage" → confetti + haptic success
- [ ] Back/forward preservent les donnees
- [ ] Dark mode fonctionne
- [ ] `flutter analyze` = 0 issues
- [ ] Tous les tests passent
- [ ] i18n EN + FR pour tous les textes
