# Planification IA — Agent multi-noeuds et SSE streaming

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

Le systeme de planification IA de BagTrip repose sur un **pipeline multi-agents orchestre par LangGraph** cote backend (FastAPI), et un **BLoC consommant un flux SSE** cote mobile (Flutter). Cinq agents specialises (destination, activites, hebergement, bagages, budget) collaborent pour produire un plan de voyage complet ancre dans des donnees reelles (Amadeus pour les vols/hotels, Open-Meteo pour la meteo). Chaque agent utilise le pattern **ReAct** (Reason + Act) avec un LLM OpenAI-compatible via LangChain pour orchestrer ses appels outils.

## Architecture backend — LangGraph

### Fichiers cles

| Fichier | Role |
|---------|------|
| `api/src/agent/graph.py` | Definition du graphe d'etats LangGraph, compilation |
| `api/src/agent/state.py` | `TripPlanState` (TypedDict) — etat partage entre noeuds |
| `api/src/agent/nodes/destination_research.py` | Noeud de recherche de destinations |
| `api/src/agent/nodes/activity_planner.py` | Noeud de planification d'activites |
| `api/src/agent/nodes/accommodation.py` | Noeud de recherche d'hebergements |
| `api/src/agent/nodes/baggage.py` | Noeud conseiller bagages |
| `api/src/agent/nodes/budget.py` | Noeud estimateur de budget |
| `api/src/agent/react_executor.py` | Boucle ReAct manuelle (Thought/Action/Observation) |
| `api/src/agent/tools.py` | Wrappers outils (Amadeus, Open-Meteo) |
| `api/src/agent/prompts.py` | System prompts par agent |
| `api/src/agent/retry.py` | Retry + degradation gracieuse |
| `api/src/api/ai/plan_trip_routes.py` | Endpoints SSE stream + accept |
| `api/src/api/ai/plan_trip_schemas.py` | Schemas Pydantic (request/response) |
| `api/src/services/llm_service.py` | Service singleton LLM (LangChain ChatOpenAI) |

### Topologie du graphe

```
START --> destination_research --> [activity_planner, accommodation, baggage] --> budget --> assemble --> END
```

Les trois noeuds intermediaires (`activity_planner`, `accommodation`, `baggage`) s'executent en **parallele** grace au fan-out/fan-in de LangGraph. Le noeud `budget` attend la completion des trois avant de s'executer.

Un second graphe allege existe pour la recherche de destinations uniquement :

```
START --> destination_research --> assemble_destinations --> END
```

Ce graphe est selectionne quand `request.mode == "destinations_only"`.

### Etat partage — `TripPlanState`

L'etat est un `TypedDict` avec les champs suivants :

**Entrees** (fixees a l'invocation) :
- `travel_types`, `budget_range`, `duration_days`, `companions`, `constraints`
- `departure_date`, `return_date` (format YYYY-MM-DD)
- `origin_city`, `travel_style`, `season`
- `nb_travelers`, `budget_preset`, `date_mode`

**Sorties par noeud** :
- `destination_research` -> `destinations`, `selected_destination`, `weather_data`, `origin_iata`
- `activity_planner` -> `activities`
- `accommodation` -> `accommodations`
- `baggage` -> `baggage_items`
- `budget` -> `budget_estimation`

**Champs avec reducer** (aggregation parallele via `Annotated[list, operator.add]`) :
- `events` : liste d'events SSE accumules
- `errors` : liste d'erreurs

**Sortie finale** :
- `trip_plan` : plan assemble complet

## Noeuds agents

### 1. Destination Research (`destination_research_node`)

**Objectif** : Proposer 3-4 destinations adaptees aux preferences, resoudre les codes IATA, obtenir la meteo reelle.

**Mode d'execution** : ReAct (boucle outil)

**Outils utilises** :
- `resolve_iata_code` : Resolution ville -> code IATA via Amadeus Location API
- `get_weather` : Previsions meteo via Open-Meteo (gratuit, sans cle API)

**Prompt systeme** (`DESTINATION_RESEARCH_PROMPT`) :
- Resoudre le code IATA de la ville d'origine
- Proposer 3-4 destinations avec IATA, coordonnees, meteo et raison du match
- Interdiction d'inventer des codes IATA ou des previsions

**Sortie attendue** :
```json
{
  "destinations": [
    {
      "city": "Barcelona",
      "country": "Spain",
      "iata": "BCN",
      "lat": 41.39,
      "lon": 2.17,
      "weather": {"avg_temp_c": 25, "rain_probability": 10, "description": "..."},
      "match_reason": "Perfect for your beach and culture preferences"
    }
  ],
  "origin_iata": "CDG"
}
```

**Selection** : La premiere destination est automatiquement selectionnee comme destination principale. Les autres deviennent des alternatives.

**Event SSE emis** : `destinations`

### 2. Activity Planner (`activity_planner_node`)

**Objectif** : Generer 5-8 activites contextualisees par la meteo reelle et les preferences.

**Mode d'execution** : Appel LLM direct (pas de ReAct, pas d'outils)

**Contexte injecte** : destination, meteo, preferences de voyage, duree, compagnons, contraintes, style, preset budget.

**Prompt systeme** (`ACTIVITY_PLANNER_PROMPT`) :
- Ancrer les suggestions dans la meteo reelle (pas de randonnee si pluie)
- Assigner chaque activite a un jour et un creneau (morning/afternoon/evening)
- Maximum 3 activites par jour (une par creneau)
- Categories : `CULTURE`, `NATURE`, `FOOD`, `SPORT`, `SHOPPING`, `NIGHTLIFE`, `RELAXATION`, `OTHER`

**Sortie attendue** :
```json
{
  "activities": [
    {
      "title": "...",
      "description": "...",
      "category": "CULTURE",
      "estimated_cost": 25.0,
      "suggested_day": 1,
      "time_of_day": "morning",
      "location": "Gothic Quarter"
    }
  ]
}
```

**Event SSE emis** : `activities`

### 3. Accommodation (`accommodation_node`)

**Objectif** : Trouver des hotels reels avec prix via Amadeus.

**Mode d'execution** : ReAct (boucle outil)

**Outils utilises** :
- `search_real_hotels` : Recherche en 2 etapes — liste d'hotels par ville (ratings 3-5 etoiles, top 10 IDs) puis offres pour ces hotels

**Prompt systeme** (`ACCOMMODATION_PROMPT`) :
- Obligation d'utiliser l'outil (pas d'invention)
- Fallback `source: "estimated"` si aucun resultat

**Sortie attendue** :
```json
{
  "accommodations": [
    {
      "name": "Hotel Name",
      "hotel_id": "AMADEUS_ID",
      "price_total": 450.0,
      "price_per_night": 64.3,
      "currency": "EUR",
      "source": "amadeus"
    }
  ]
}
```

**Event SSE emis** : `accommodations`

### 4. Baggage Advisor (`baggage_node`)

**Objectif** : Suggerer 10-15 articles essentiels bases sur la meteo reelle et les activites planifiees.

**Mode d'execution** : Appel LLM direct

**Contexte injecte** : destination, meteo reelle (JSON), duree, titres des 8 premieres activites, compagnons, contraintes, style.

**Prompt systeme** (`BAGGAGE_PROMPT`) :
- Ancrer dans la meteo (< 10C -> couches chaudes, > 40% pluie -> impermeable)
- Categories : `DOCUMENTS`, `CLOTHING`, `ELECTRONICS`, `TOILETRIES`, `HEALTH`, `ACCESSORIES`, `OTHER`

**Fallback** : Si le LLM echoue, `_default_baggage_items()` retourne 6 items par defaut (passeport, adaptateur, creme solaire, trousse secours, chargeur, vetements).

**Event SSE emis** : `baggage`

### 5. Budget Estimator (`budget_node`)

**Objectif** : Calculer un budget realiste avec les vrais prix de vols + hotels deja collectes.

**Mode d'execution** : ReAct (boucle outil)

**Outils utilises** :
- `search_real_flights` : Recherche de vols Amadeus (top 5 offres, prix en EUR)
- `resolve_iata_code` : Resolution si necessaire

**Contexte injecte** : destination (avec IATA), ville d'origine, dates, duree, nombre de voyageurs, preset budget, hotels deja trouves (top 3), cout total estime des activites.

**Prompt systeme** (`BUDGET_PROMPT`) :
- Utiliser les vrais prix de vols Amadeus
- Integrer les prix d'hotels deja collectes
- Estimer repas, transport, activites
- Produire un total min/max en EUR

**Sortie attendue** :
```json
{
  "estimation": {
    "flights": {"amount": 350, "currency": "EUR", "source": "amadeus", "details": "Round trip CDG-BCN"},
    "accommodation": {"amount": 450, "currency": "EUR", "source": "amadeus", "per_night": 64.3},
    "meals": {"amount": 280, "currency": "EUR", "source": "estimated", "per_day_per_person": 40},
    "transport": {"amount": 100, "currency": "EUR", "source": "estimated", "per_day": 14.3},
    "activities": {"amount": 150, "currency": "EUR", "source": "estimated"},
    "total_min": 1200,
    "total_max": 1500,
    "currency": "EUR"
  }
}
```

**Event SSE emis** : `budget`

### 6. Assemble (`assemble_node`)

**Objectif** : Combiner toutes les sorties en un plan unifie.

**Pas d'appel LLM** : pure aggregation des champs du state.

**Sortie** : `trip_plan` contenant `destination`, `origin_iata`, `weather`, `alternatives`, `activities`, `accommodations`, `baggage`, `budget`, `duration_days`, `departure_date`, `return_date`.

**Event SSE emis** : `complete` avec le `tripPlan` complet

## ReAct Executor

Le ReAct executor (`api/src/agent/react_executor.py`) implemente le pattern ReAct manuellement car le LLM utilise (configure via `settings.LLM_MODEL`) ne supporte pas le function calling natif.

### Boucle

1. Construire le system prompt = instruction agent + descriptions d'outils + format ReAct
2. Envoyer system + user prompt au LLM
3. Parser la reponse :
   - Si `Final Answer: {...}` -> retourner le JSON parse
   - Si `Action: tool_name` + `Action Input: {...}` -> executer l'outil, injecter `Observation: result` dans la conversation
4. Repeter jusqu'a `Final Answer` ou `MAX_REACT_ITERATIONS` (5)
5. Si max atteint : forcer une reponse finale

### Robustesse

- Nettoyage des fences markdown (`\`\`\`json ... \`\`\``)
- Recovery JSON partiel via regex `\{[^}]+\}`
- Fallback si ni Action ni Final Answer detectes

## Outils (Tool Registry)

Tous les outils sont enregistres dans `TOOL_REGISTRY` (`api/src/agent/tools.py`) avec nom, fonction, description, et parametres.

### `resolve_iata_code(city_name)`

- **Source** : Amadeus Location API (`search_locations_by_keyword`)
- **Cache** : idempotency cache
- **Semaphore** : max 3 appels Amadeus concurrents
- **Retour** : `{iata, city, country, lat, lon}` ou `{error: ...}`

### `search_real_flights(origin, destination, date, return_date?, adults?)`

- **Source** : Amadeus Flight Offers Search
- **Retour** : top 5 offres avec airline, prix, horaires, duree + prix le moins cher
- **Cache** : idempotency cache

### `search_real_hotels(city_code, check_in, check_out, adults?)`

- **Source** : Amadeus Hotel List + Hotel Offers (2 etapes)
- **Retour** : liste d'hotels avec nom, ID, prix total, prix/nuit, source
- **Cache** : idempotency cache
- **Filtrage** : hotels 3-5 etoiles, top 10 IDs

### `get_weather(latitude, longitude, start_date, end_date)`

- **Source** : Open-Meteo API (`/v1/forecast`)
- **Retour** : `{avg_temp_c, min_temp_c, max_temp_c, rain_probability, description, source}`
- **Fallback intelligent** : `_fallback_weather()` estime la meteo par zone climatique (latitude) + saison si Open-Meteo est indisponible. 4 zones : tropical (<23), subtropical (23-35), temperate (35-55), subarctic (55+).
- **Cache** : idempotency cache

## Retry et degradation gracieuse

Le wrapper `with_retry()` (`api/src/agent/retry.py`) encapsule les 3 noeuds paralleles :

- **1 retry** par defaut (`max_retries=1`, soit 2 tentatives total)
- **En cas d'echec total** : retourne une liste vide pour le champ concerne + un event SSE `warning` + une entree dans `errors`
- Les autres noeuds continuent normalement (le pipeline ne s'arrete pas)

## SSE Streaming — Endpoint et protocole

### Endpoint : `POST /v1/ai/plan-trip/stream`

**Authentification** : JWT (Bearer token) + verification quota IA (`require_ai_quota`)

**Request body** (`PlanTripRequest`) :

| Champ | Type | Description |
|-------|------|-------------|
| `travelTypes` | `str?` | Preferences (ex: "beach, culture") |
| `budgetRange` | `str?` | Fourchette budget texte |
| `durationDays` | `int?` | Duree en jours (defaut: 7) |
| `companions` | `str?` | Compagnons (defaut: "solo") |
| `season` | `str?` | Saison preferee |
| `constraints` | `str?` | Contraintes |
| `departureDate` | `str?` | Date de depart YYYY-MM-DD |
| `returnDate` | `str?` | Date de retour YYYY-MM-DD |
| `originCity` | `str?` | Ville de depart |
| `travelStyle` | `str?` | Style de voyage |
| `nbTravelers` | `int?` | Nombre de voyageurs (defaut: 1) |
| `budgetPreset` | `str?` | Preset budget (BACKPACKER/COMFORTABLE/PREMIUM/NO_LIMIT) |
| `dateMode` | `str?` | Mode de date |
| `mode` | `str?` | "full" (defaut) ou "destinations_only" |

**Response** : `text/event-stream` avec headers `Cache-Control: no-cache`, `Connection: keep-alive`, `X-Accel-Buffering: no`

### Events SSE emis

| Event | Donnees | Phase |
|-------|---------|-------|
| `progress` | `{phase, message}` | Tout au long du pipeline |
| `destinations` | `{destinations: [...], origin_iata}` | Apres destination_research |
| `activities` | `{activities: [...], source}` | Apres activity_planner |
| `accommodations` | `{accommodations: [...], source}` | Apres accommodation |
| `baggage` | `{items: [...]}` | Apres baggage |
| `budget` | `{estimation: {...}, source}` | Apres budget |
| `complete` | `{tripPlan: {...}}` | Apres assemble |
| `warning` | `{section, message}` | Degradation gracieuse d'un noeud |
| `heartbeat` | `{ts}` | Toutes les 15 secondes |
| `error` | `{message}` | En cas d'erreur fatale |
| `done` | `{status: "complete"}` | Signal de fin de stream |

### Deduplication

Un set `sent_events` track les combinaisons `event_type:node_name` pour eviter les doublons (possible avec le fan-in LangGraph).

### Quota IA

Apres completion reussie, `PlanService.increment_ai_generation()` incremente le compteur de generations IA de l'utilisateur.

## Consommation SSE cote Flutter

### `AiRepositoryImpl.planTripStream()`

- Utilise `flutter_client_sse` (SSEClient) en mode POST
- Headers : `Authorization: Bearer <token>`, `Accept: text/event-stream`, `Content-Type: application/json`
- Filtre les heartbeats
- Parse chaque event en `{event: String, data: Map<String, dynamic>}`
- Yield via `async*` generator

### `PlanTripBloc._handleSseEvent()`

Mapping des events SSE vers les transitions de state :

| Event | Transition de state |
|-------|-------------------|
| `progress` | Mise a jour de `generationMessage` |
| `destinations` | `destinations: completed`, `activities: inProgress`, progression 20% |
| `activities` | `activities: completed`, `accommodations: inProgress`, progression 40% |
| `accommodations` | `accommodations: completed`, `baggage: inProgress`, progression 60% |
| `baggage` | `baggage: completed`, `budget: inProgress`, progression 80% |
| `budget` | `budget: completed`, progression 90% |
| `complete` | Parse `tripPlan` via `_tripPlanFromSseData()`, progression 100%, `currentStep: 5` |
| `error` | `generationError` set |
| `done` | Si pas de plan genere, fallback vers review vide |

### Conversion SSE -> TripPlan

`_tripPlanFromSseData()` extrait et structure les donnees brutes du SSE :
- `destination.{city, country, iata}`
- `weather` (tel quel)
- `activities` -> `highlights` (4 premiers titres), `dayProgram`, `dayDescriptions`, `dayCategories`
- `accommodations[0]` -> `accommodationName`, `accommodationPrice`, `accommodationSource`
- `budget.flights` -> `flightPrice`, `flightSource`, `flightRoute`
- `baggage` -> `essentialItems`, `essentialReasons`
- `budget.{total_min, total_max}` -> `budgetEur` (prefere max)

## Endpoint : `POST /v1/ai/plan-trip/accept`

**Objectif** : Transformer le plan genere en un vrai trip en base de donnees.

**Request body** (`AcceptPlanRequest`) :

| Champ | Type | Description |
|-------|------|-------------|
| `suggestion` | `dict` | Le plan genere complet |
| `startDate` | `str?` | Date de depart YYYY-MM-DD |
| `endDate` | `str?` | Date de retour YYYY-MM-DD |
| `selectedDestinationIndex` | `int` | Index dans la liste de destinations (0 = primaire) |

**Logique** :
1. Resolution de la destination (primaire ou alternative)
2. Fetch image de couverture Unsplash
3. Creation du trip (`origin: "AI"`)
4. Creation des activites avec scheduling : `suggested_day` -> date reelle, `time_of_day` -> `TIME_OF_DAY_MAP` (morning=09:00, afternoon=14:00, evening=19:00), `validation_status: "SUGGESTED"`
5. Creation des bagages (IA ou fallback i18n)

## Presets budget — correspondance mobile/API

| Cle Flutter | Cle API | Label API |
|---|---|---|
| `BudgetPreset.backpacker` | `BACKPACKER` | "budget/backpacker (< 50 EUR/day/person)" |
| `BudgetPreset.comfortable` | `COMFORTABLE` | "comfortable (50-150 EUR/day/person)" |
| `BudgetPreset.premium` | `PREMIUM` | "premium (150-500 EUR/day/person)" |
| `BudgetPreset.noLimit` | `NO_LIMIT` | "no budget limit" |

Definis dans `api/src/api/ai/plan_trip_schemas.py` : `BUDGET_PRESET_RANGES`.

## LLM Service

Le `LLMService` (`api/src/services/llm_service.py`) est un singleton lazy utilisant `langchain_openai.ChatOpenAI` :

- **Model** : `settings.LLM_MODEL`
- **Base URL** : `settings.LLM_API_BASE`
- **Temperature** : 0.7
- **3 methodes** : `call_llm` (sync JSON), `acall_llm` (async JSON), `acall_llm_messages` (async raw, pour ReAct)
- **Nettoyage** : strip des fences markdown avant parsing JSON

## Tests existants

### Flutter (`bagtrip/test/`)

| Fichier | Couverture |
|---------|-----------|
| `blocs/plan_trip_bloc_test.dart` | Events et transitions du BLoC |
| `models/plan_trip_models_test.dart` | Serialisation/deserialisation des models |
| `plan_trip/helpers/budget_estimation_test.dart` | Fonction pure `estimateBudget()` |
| `plan_trip/view/plan_trip_flow_page_test.dart` | Widget test du wizard |
| `plan_trip/view/step_dates_view_test.dart` | Vue dates |
| `plan_trip/view/step_travelers_budget_view_test.dart` | Vue voyageurs/budget |
| `plan_trip/widgets/traveler_stepper_test.dart` | Widget stepper |
| `plan_trip/widgets/month_grid_picker_test.dart` | Picker mois |
| `plan_trip/widgets/duration_chip_selector_test.dart` | Chips duree |

### API (`api/tests/`)

| Fichier | Couverture |
|---------|-----------|
| `test_plan_trip_schema.py` | Validation du schema Pydantic |
| `test_accept_endpoint.py` | Endpoint accept |
| `test_state_injection.py` | Injection de l'etat initial |
| `test_destinations_only_mode.py` | Mode destinations_only |
| `test_time_of_day_mapping.py` | Mapping time_of_day -> time |

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| "Inspire-moi" casse | `bagtrip/lib/service/ai_service.dart:23-33` — `getInspiration()` retourne `const Success([])`. Le flow IA ne peut plus etre declenche via le bouton "Inspire-moi". Le mode `destinations_only` du graphe LangGraph existe cote API mais n'est pas utilise cote mobile. | P0 |
| Parametres SSE incomplets | `bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart:577-596` — `_buildSseParams()` ne transmet que 4 des 14 champs supportes par `PlanTripRequest`. Manquent : `originCity`, `travelTypes`, `companions`, `constraints`, `season`, `travelStyle`, `nbTravelers`, `budgetPreset`, `dateMode`, `mode`. L'IA travaille donc avec un contexte tres appauvri. | P0 |
| Pas de tests unitaires pour les noeuds agents | `api/src/agent/nodes/` — Aucun test unitaire pour `destination_research_node`, `activity_planner_node`, `accommodation_node`, `baggage_node`, `budget_node`. Les tests d'integration existent mais pas de tests isoles avec mock LLM. | P1 |
| Pas de test pour `react_executor.py` | `api/src/agent/react_executor.py` — La boucle ReAct (parsing, recovery JSON, max iterations) n'a pas de tests unitaires. | P1 |
| Pas de test pour `_handleSseEvent` | `bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart:379-461` — Le mapping des events SSE vers les transitions de state n'est pas teste de maniere isolee. | P1 |
| `_sseSubscription` jamais assigne | `bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart:32` — Le champ `_sseSubscription` est declare mais jamais assigne (le bloc utilise `emit.forEach` au lieu d'un `listen`). Le `_onRetryGeneration` annule cette subscription vide avant de re-fire l'event, ce qui est inoffensif mais trompeur. | P2 |
| Pas de cancellation SSE propre | `bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart:322-377` — Si l'utilisateur quitte le wizard pendant la generation, `close()` annule `_sseSubscription` (toujours null) mais `emit.forEach` n'est pas interrompu proprement. Le bloc verifie `isClosed` pour eviter les emissions post-close, mais le stream SSE continue cote serveur. | P1 |
| Weather fallback latitude-only | `api/src/agent/tools.py:283-353` — Le fallback meteo est intelligent (4 zones climatiques + hemisphere) mais ne prend pas en compte l'altitude, la proximite cotiere, ou les microclimats. Acceptable comme estimation. | P2 |
| Pas de streaming partiel cote review | `bagtrip/lib/plan_trip/view/step_review_view.dart` — La review n'affiche rien tant que l'event `complete` n'est pas recu. Les donnees intermediaires (activites, hotels) pourraient etre affichees progressivement au fil du stream. | P2 |
| Pas d'image de destination dans la review | `bagtrip/lib/plan_trip/view/step_review_view.dart:53-137` — Le hero SliverAppBar utilise un gradient fixe au lieu d'afficher une image de la destination. L'image Unsplash n'est fetchee qu'a l'acceptation (`plan_trip_routes.py:237`). | P2 |
