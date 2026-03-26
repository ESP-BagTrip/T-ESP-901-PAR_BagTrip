# Creation de voyage — Wizard multi-etapes

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

La creation de voyage dans BagTrip repose sur un wizard multi-etapes orchestre par un `PlanTripBloc` (BLoC pattern). Le wizard guide l'utilisateur a travers 6 etapes (ou 5 en mode manuel) et supporte deux parcours distincts : un **flow manuel** (l'utilisateur choisit sa destination) et un **flow IA** (l'IA suggere des destinations puis genere un itineraire complet). Le tout culmine soit en creation directe d'un trip via l'API REST, soit en generation IA streamee via SSE puis acceptation du plan.

## Architecture

### Fichiers cles

| Couche | Fichier | Role |
|--------|---------|------|
| Page | `bagtrip/lib/plan_trip/view/plan_trip_flow_page.dart` | Point d'entree, `BlocProvider`, `PageView` avec 6 pages |
| BLoC | `bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart` | Logique metier, orchestration des etapes |
| State | `bagtrip/lib/plan_trip/bloc/plan_trip_state.dart` | Etat immutable (Freezed) avec computed getters |
| Events | `bagtrip/lib/plan_trip/bloc/plan_trip_event.dart` | 17 events couvrant navigation + data |
| Models | `bagtrip/lib/plan_trip/models/` | `TripPlan`, `DateMode`, `BudgetPreset`, `DurationPreset`, `LocationResult`, `AiDestination`, `StepStatus`, `BudgetRange` |

### Pattern de navigation

Le wizard utilise un `PageView` avec `NeverScrollableScrollPhysics` (pas de swipe manuel). La navigation se fait uniquement via les events `PlanTripNextStep`, `PlanTripPreviousStep`, et `PlanTripGoToStep`. Le `BlocConsumer.listener` anime la transition avec `PageController.animateToPage()` (courbe spring, duree `AppAnimations.wizardTransition`).

**Le flow manuel saute l'etape 3** (propositions IA) : quand `isManualFlow == true`, `_onNextStep` passe de l'etape 2 directement a l'etape 4, et `_onPreviousStep` fait le chemin inverse. Le total d'etapes est 5 en manuel vs 6 en IA.

## Etape 0 — Dates (`StepDatesView`)

L'utilisateur choisit ses dates via un `FlexibleDatePicker` qui supporte 3 modes :

| Mode (`DateMode`) | Donnees capturees | Validation |
|---|---|---|
| `exact` | `startDate` + `endDate` (DateTime) | Les deux dates non-nulles, `endDate >= startDate` |
| `month` | `preferredMonth` (int 1-12) + `preferredYear` (int) | Les deux non-nuls |
| `flexible` | `flexibleDuration` (`DurationPreset`) | Preset selectionne |

### Presets de duree (`DurationPreset`)

| Enum | Jours calcules |
|------|----------------|
| `weekend` | 3 |
| `oneWeek` | 7 |
| `twoWeeks` | 14 |
| `threeWeeks` | 21 |

Un badge resume dynamique s'affiche quand les dates sont valides (format localise via `intl`). Le bouton "Continuer" n'est actif que si `areDatesValid == true`.

### Duree calculee (`tripDurationDays`)

La propriete computee `tripDurationDays` dans le state retourne :
- En mode `exact` : `endDate.difference(startDate).inDays`
- En mode `flexible` : la valeur du preset (3/7/14/21)
- En mode `month` : `null` (pas de duree determinable)

## Etape 1 — Voyageurs et budget (`StepTravelersBudgetView`)

### Voyageurs

Un `TravelerStepper` (widget custom avec animation bounce) permet de selectionner de 1 a 10 voyageurs. La valeur est stockee dans `nbTravelers` (defaut : 1).

### Budget

Un `BudgetChipSelector` affiche 4 presets toggle (re-cliquer deselectionne) :

| Preset (`BudgetPreset`) | Fourchette/jour/personne (Flutter) | Fourchette/jour/personne (API) |
|---|---|---|
| `backpacker` | 30-60 EUR | < 50 EUR |
| `comfortable` | 80-150 EUR | 50-150 EUR |
| `premium` | 200-400 EUR | 150-500 EUR |
| `noLimit` | 400-1000 EUR | illimite |

**Estimation locale** : quand un preset, un nombre de voyageurs et une duree sont disponibles, un `_BudgetEstimationBadge` affiche l'estimation totale calculee par la fonction pure `estimateBudget()` dans `bagtrip/lib/plan_trip/helpers/budget_estimation.dart`. Formule : `nbTravelers * minPerDay * days` a `nbTravelers * maxPerDay * days`.

Le budget est **optionnel** : un lien "Passer" (`budgetSkipLabel`) permet de continuer sans selectionner de preset.

## Etape 2 — Destination (`StepDestinationView`)

Cette etape offre deux parcours :

### Recherche manuelle

- Champ de recherche avec **debounce 300ms** (minimum 2 caracteres)
- Appel a `LocationService.searchLocationsByKeyword(query, 'CITY,AIRPORT')` qui interroge l'API Amadeus
- Resultats affiches sous forme de `_LocationResultTile` avec drapeau emoji (genere via unicode), nom, pays, et code IATA
- La selection d'un resultat fire `PlanTripSelectManualDestination`, met `isManualFlow = true` et affiche un badge de confirmation + bouton "Continuer"

### "Inspire-moi" (flow IA)

- Bouton gradient `_InspireMeButton` qui fire `PlanTripRequestAiSuggestions`
- Le bloc charge les preferences de personnalisation via `PersonalizationStorage` (SharedPreferences par utilisateur : travelTypes, budget, companions, constraints)
- Calcul de la saison a partir de `startDate` ou `preferredMonth`
- Appel a `_aiRepository.getInspiration(...)`

**ATTENTION** : La methode `getInspiration()` dans `AiRepositoryImpl` retourne actuellement `const Success([])` (stub). Le commentaire indique : "Legacy endpoint removed -- AI planning now uses planTripStream()." Par consequent, le bouton "Inspire-moi" ne produit jamais de suggestions. Voir section "Ce qu'il manque".

Quand des suggestions IA arrivent (si l'implementation fonctionnait), un `BlocConsumer.listener` navigue automatiquement vers l'etape 3.

### Separateur

Les deux options sont separees par un `_OrSeparator` avec le texte "OU".

## Etape 3 — Propositions IA (`StepAiProposalsView`)

Accessible uniquement en flow IA. Affiche les destinations suggerees dans un `DestinationCarousel` avec les cartes `AiDestinationCard`.

### AiDestinationCard

Chaque carte contient :
- Image hero (via `OptimizedImage` ou placeholder paysage)
- Badge "IA" en haut a droite
- Ville + pays en overlay bas de l'image
- Raison du match (`matchReason`)
- Chips meteo + budget estime
- Jusqu'a 3 activites suggerees en pills

### Interaction de selection

- Hint "swipe to discover" visible 3 secondes
- Bouton "Choisir cette destination" (`_ChooseButton`)
- Au clic : animation en 3 phases (scale up 5% -> overlay vert -> fade des autres cartes), duree 800ms
- A la fin de l'animation : fire `PlanTripSwipeProposal(currentPage)` qui selectionne la destination et avance a l'etape 4

## Etape 4 — Generation IA (`StepGenerationView`)

La generation demarre automatiquement a l'arrivee sur l'etape (le `BlocConsumer.listener` dans `PlanTripFlowPage` fire `PlanTripStartGeneration` quand `currentStep == 4` et `generationSteps.isEmpty`).

### Verification de quota

Avant de lancer le stream SSE, le bloc verifie `user.aiGenerationsRemaining`. Si le quota est epuise, une erreur est emise sans appel reseau.

### SSE Streaming

Le bloc appelle `_aiRepository.planTripStream()` qui ouvre une connexion SSE POST vers `/v1/ai/plan-trip/stream`. Les parametres envoyes incluent `travelTypes`, `budgetRange`, `durationDays`, `companions`, `constraints`, `departureDate`, `returnDate`.

### Checklist de progression

Le state maintient un `Map<String, StepStatus> generationSteps` avec 5 cles :

| Cle | Icone | Progression |
|-----|-------|-------------|
| `destinations` | `place_outlined` | 20% |
| `activities` | `local_activity_outlined` | 40% |
| `accommodations` | `hotel_outlined` | 60% |
| `baggage` | `luggage_outlined` | 80% |
| `budget` | `account_balance_wallet_outlined` | 90% |

Chaque `StepStatus` (enum `pending`, `inProgress`, `completed`, `error`) est affiche avec un `AnimatedSwitcher` et des icones distinctes (cercle vide, spinner, check vert, erreur rouge).

### Avatar IA pulsant

Un `_PulsingAiAvatar` avec `AnimationController` en boucle (1500ms, reverse) cree un effet de halo respirant autour de l'icone `auto_awesome`.

### Gestion d'erreurs et timeout

- **Timeout client** : 60 secondes sans progres -> affichage d'un etat d'erreur
- **Erreur SSE** : event `error` dans le stream -> idem
- **Retry** : bouton "Reessayer" qui annule l'abonnement SSE, puis fire `PlanTripStartGeneration` a nouveau

### Event `complete`

Quand l'event SSE `complete` arrive avec `tripPlan`, le bloc appelle `_tripPlanFromSseData()` pour convertir le JSON en `TripPlan` (model Freezed). Le state passe a `currentStep: 5`.

## Etape 5 — Review (`StepReviewView`)

### Hero SliverAppBar

En-tete extensible (260px) avec gradient + overlay sombre, affichant :
- Ville et pays de destination
- Chips "frosted glass" : duree, budget, meteo

### Sections de contenu

1. **Points forts** (`highlights`) : chips colorees des 4 premieres activites
2. **Vol** (`FlightPreviewCard`) : route, details, prix, source (amadeus/estimated)
3. **Hebergement** (`AccommodationPreviewCard`) : nom, sous-titre, prix, source
4. **Itineraire jour par jour** (`DayActivitiesTab`) : onglets par jour avec activites, descriptions, categories
5. **Essentiels de voyage** : checklist interactive (case a cocher avec `lineThrough`)
6. **Budget detaille** (`BudgetBreakdownChart`) : repartition visuelle du budget

### Actions

- **"Creer mon voyage"** (`_CreateTripButton`) : animation press-scale (0.97), spinner pendant la creation
- **"Voir d'autres destinations"** : retour a l'etape 2 (manuel) ou 3 (IA), reset du plan genere

### Flow manuel vs IA

| | Flow manuel | Flow IA |
|---|---|---|
| Etape 3 | Sautee | Carousel de propositions |
| Etape 4 | Generation declenchee mais sans destination IA | Generation via SSE |
| Creation | `_createManualTrip()` via `TripRepository.createTrip()` | `_createAiTrip()` via `AiRepository.acceptInspiration()` |
| Endpoint | `POST /trips` (REST classique) | `POST /v1/ai/plan-trip/accept` |

### Acceptation du plan IA (backend)

L'endpoint `POST /v1/ai/plan-trip/accept` (`AcceptPlanRequest`) :
1. Resout la destination (primaire ou alternative via `selectedDestinationIndex`)
2. Recupere une image de couverture via Unsplash
3. Cree le trip via `TripsService.create_trip()` avec origin="AI"
4. Cree les activites avec scheduling intelligent (`suggested_day` + `time_of_day` -> `TIME_OF_DAY_MAP`)
5. Cree les items bagages (IA ou fallback i18n en/fr)
6. Commit en DB et retourne l'id du trip

## Composants partages

| Widget | Fichier | Usage |
|--------|---------|-------|
| `PremiumStepIndicator` | `design/widgets/premium_step_indicator.dart` | Indicateur d'avancement en haut du wizard |
| `StepHeader` | `design/widgets/step_header.dart` | Resume compact des choix precedents (dates, voyageurs, budget, destination) |
| `FlexibleDatePicker` | `design/widgets/flexible_date_picker.dart` | Picker 3 modes (exact, month, flexible) |
| `BudgetChipSelector` | `design/widgets/budget_chip_selector.dart` | Selection de chips budget |
| `DestinationCarousel` | `design/widgets/destination_carousel.dart` | Carousel horizontal pour les propositions IA |

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| `getInspiration()` stub | `bagtrip/lib/service/ai_service.dart:23-33` — La methode retourne `const Success([])`. Le bouton "Inspire-moi" de l'etape 2 ne produit jamais de suggestions. Il faudrait soit reimplementer l'appel vers un endpoint fonctionnel (ex: `plan-trip/stream` en mode `destinations_only`), soit supprimer le bouton. | P0 |
| Pas de validation de l'etape 1 | `bagtrip/lib/plan_trip/view/step_travelers_budget_view.dart` — Le bouton "Continuer" est toujours actif (`enabled` non conditionne). L'utilisateur peut continuer sans avoir interagi avec le stepper ni le budget. C'est voulu pour le budget (optionnel), mais le nombre de voyageurs n'est jamais valide explicitement. | P2 |
| `originCity` non transmis au SSE | `bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart:357-596` — La methode `_buildSseParams()` ne transmet pas `originCity` (la ville de depart de l'utilisateur). Le champ existe dans `PlanTripRequest` et `TripPlanState` cote API mais n'est jamais renseigne cote mobile. Sans ville de depart, les recherches de vols ne peuvent pas etre faites. | P1 |
| `travelTypes`, `companions`, `constraints` non transmis au SSE | `bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart:577-596` — `_buildSseParams()` ne transmet que `durationDays`, `departureDate`, `returnDate`, et `budgetRange`. Les preferences de personnalisation (travelTypes, companions, constraints) ne sont pas incluses dans les parametres SSE, meme si l'API les supporte. | P1 |
| Pas de mode `destinations_only` cote mobile | L'API supporte `mode="destinations_only"` pour une recherche legere de destinations. Ce mode n'est utilise nulle part cote Flutter. Il pourrait servir a reimplementer "Inspire-moi" sans lancer le pipeline complet. | P1 |
| Tests bloc partiels | `bagtrip/test/blocs/plan_trip_bloc_test.dart` existe mais il faudrait verifier la couverture des events SSE (`_handleSseEvent`), du retry generation, et du flow complet IA. | P2 |
| Pas de persistence du plan en cours | Si l'utilisateur quitte le wizard (bouton X), tout le state est perdu. Pas de brouillon ni de resume sauvegarde. | P2 |
| Image de destination non affichee dans la review | `bagtrip/lib/plan_trip/view/step_review_view.dart` — Le hero SliverAppBar utilise un gradient fixe, pas l'image Unsplash qui sera fetched a l'acceptation. L'utilisateur ne voit jamais de visuel de la destination pendant la review. | P2 |
| `nbTravelers` non transmis au SSE | `bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart:577-596` — Le nombre de voyageurs n'est pas inclus dans `_buildSseParams()`. L'API le supporte via `nbTravelers` dans `PlanTripRequest`. | P1 |
