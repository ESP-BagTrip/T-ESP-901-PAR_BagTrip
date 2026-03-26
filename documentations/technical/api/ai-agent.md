# Agent IA — LangGraph Multi-Agent Trip Planning

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

L'agent IA de BagTrip est un **pipeline multi-noeud** orchestre par **LangGraph** qui planifie un voyage complet a partir des preferences utilisateur. Il utilise un pattern **ReAct** (Reason + Act) pour appeler des outils reels (Amadeus, Open-Meteo) et un modele LLM (`gpt-oss-120b` heberge chez OVH) pour le raisonnement.

Le pipeline s'execute en streaming via **Server-Sent Events (SSE)** pour permettre au client mobile d'afficher les resultats progressivement.

## Architecture du graph

Fichier principal : `api/src/agent/graph.py`

### Graph complet (`graph`)

```
START
  |
  v
destination_research          (ReAct: resolve_iata_code + get_weather)
  |
  +---------+---------+
  |         |         |
  v         v         v
activity  accommo-  baggage   (PARALLEL — fan-out/fan-in)
planner   dation    advisor
  |         |         |
  +---------+---------+
  |
  v
budget                        (ReAct: search_real_flights + resolve_iata_code)
  |
  v
assemble                      (Combine all outputs)
  |
  v
END
```

Les trois noeuds du milieu (`activity_planner`, `accommodation`, `baggage`) s'executent **en parallele** grace au fan-out/fan-in de LangGraph. Chaque noeud ecrit dans son propre champ de l'etat et les champs `events`/`errors` utilisent un **reducer** (`operator.add`) pour accumuler sans conflit.

### Graph leger (`destinations_only_graph`)

```
START → destination_research → assemble_destinations → END
```

Active via `mode: "destinations_only"` dans la requete. Ne fait que rechercher des destinations sans planifier les activites, hebergements et bagages.

## State (`api/src/agent/state.py`)

Le `TripPlanState` est un `TypedDict` partage entre tous les noeuds :

**Entrees (set a l'invocation)** :
- `travel_types`, `budget_range`, `duration_days`, `companions`, `constraints`
- `departure_date`, `return_date`, `origin_city`, `travel_style`, `season`
- `nb_travelers`, `budget_preset`, `date_mode`

**Sorties par noeud** :
- `destinations`, `selected_destination`, `weather_data`, `origin_iata` (destination_research)
- `activities` (activity_planner)
- `accommodations` (accommodation)
- `baggage_items` (baggage)
- `budget_estimation` (budget)
- `trip_plan` (assemble)

**Accumulateurs** (reducer `operator.add`) :
- `events` — evenements SSE a emettre
- `errors` — erreurs non fatales

## Noeuds en detail

### 1. `destination_research_node` (`nodes/destination_research.py`)

**Type** : ReAct (tool calling)
**Outils** : `resolve_iata_code`, `get_weather`
**Prompt** : `DESTINATION_RESEARCH_PROMPT`

Fonctionnement :
1. Construit un prompt a partir de l'etat (origin_city, travel_types, budget, etc.)
2. Demande au LLM de proposer 3-4 destinations
3. Le LLM utilise `resolve_iata_code` pour obtenir les vrais codes IATA
4. Le LLM utilise `get_weather` pour obtenir les previsions meteo reelles
5. Retourne la liste de destinations, selectionne la premiere comme principale

Sortie SSE : `event: destinations`

### 2. `activity_planner_node` (`nodes/activity_planner.py`)

**Type** : Direct LLM (pas de tools)
**Prompt** : `ACTIVITY_PLANNER_PROMPT`

Fonctionnement :
1. Recoit la destination selectionnee et les donnees meteo reelles
2. Le LLM genere 5-8 activites contextualisees (pas d'activites outdoor si pluie, etc.)
3. Chaque activite a un `suggested_day` (1-based) et un `time_of_day` (morning/afternoon/evening)

Sortie SSE : `event: activities`

### 3. `accommodation_node` (`nodes/accommodation.py`)

**Type** : ReAct (tool calling)
**Outils** : `search_real_hotels`
**Prompt** : `ACCOMMODATION_PROMPT`

Fonctionnement :
1. Construit le prompt avec destination, dates, budget
2. Le LLM appelle `search_real_hotels` pour obtenir des vrais prix d'hotel Amadeus
3. Si aucun resultat, le LLM estime des prix raisonnables (source: "estimated")

Sortie SSE : `event: accommodations`

### 4. `baggage_node` (`nodes/baggage.py`)

**Type** : Direct LLM (pas de tools)
**Prompt** : `BAGGAGE_PROMPT`

Fonctionnement :
1. Recoit destination, meteo reelle, activites planifiees, duree
2. Le LLM suggere 10-15 objets a emporter, ancres dans les conditions meteo reelles
3. Fallback vers une liste par defaut si le LLM echoue (`_default_baggage_items()`)

Sortie SSE : `event: baggage`

### 5. `budget_node` (`nodes/budget.py`)

**Type** : ReAct (tool calling)
**Outils** : `search_real_flights`, `resolve_iata_code`
**Prompt** : `BUDGET_PROMPT`

Fonctionnement :
1. Agrege les donnees de tous les noeuds precedents
2. Le LLM appelle `search_real_flights` pour obtenir des vrais prix de vol
3. Combine avec les prix d'hotel reels, les couts d'activites, et estime repas + transport
4. Produit une estimation par categorie avec source (amadeus vs estimated)

Sortie SSE : `event: budget`

### 6. `assemble_node` (dans `graph.py`)

**Type** : Assemblage pur (pas de LLM)

Combine toutes les sorties en un `trip_plan` final et emet `event: complete`.

## ReAct Executor (`api/src/agent/react_executor.py`)

Le modele `gpt-oss-120b` ne supporte pas le native function calling. Le ReAct executor implemente manuellement la boucle :

```
1. Envoyer system prompt (instruction + descriptions des outils) + user prompt
2. Parser la sortie du LLM :
   - Si "Action: <tool> / Action Input: <json>" → executer l'outil
   - Si "Final Answer: <json>" → retourner le resultat
3. Injecter "Observation: <result>" dans la conversation
4. Repeter (max 5 iterations)
```

**Parsing** (`parse_react_output`) :
- Detection par regex de `Action:`, `Action Input:`, `Final Answer:`
- Nettoyage automatique des code fences markdown
- Fallback : si ni Action ni Final Answer, traite la sortie comme une reponse finale
- Recovery JSON : si le JSON est malformee, tente d'extraire un objet `{...}` par regex

**Max iterations** : 5 (configurable). Si atteint, force un `Final Answer` en derniere iteration.

## Tools (`api/src/agent/tools.py`)

4 outils disponibles dans le `TOOL_REGISTRY` :

### `resolve_iata_code`
- **Input** : `{"city_name": "Paris"}`
- **Output** : `{"iata": "CDG", "city": "Paris", "country": "France", "lat": 49.0, "lon": 2.55}`
- **Source** : Amadeus Location Search API
- **Cache** : IdempotencyCache (TTL 5min)

### `search_real_flights`
- **Input** : `{"origin": "CDG", "destination": "BCN", "date": "2025-07-01", "return_date": "2025-07-08", "adults": 1}`
- **Output** : `{"flights": [...], "cheapest": 150.0, "currency": "EUR", "source": "amadeus"}`
- **Source** : Amadeus Flight Offers Search (max 5 offres)
- **Cache** : IdempotencyCache (TTL 5min)

### `search_real_hotels`
- **Input** : `{"city_code": "PAR", "check_in": "2025-07-01", "check_out": "2025-07-08", "adults": 1}`
- **Output** : `{"hotels": [...], "source": "amadeus"}`
- **Source** : Amadeus Hotel List + Hotel Offers (2 appels chaines)
- **Cache** : IdempotencyCache (TTL 5min)
- **Note** : Prend les 10 premiers hotels par ville puis cherche les offres

### `get_weather`
- **Input** : `{"latitude": 48.85, "longitude": 2.35, "start_date": "2025-07-01", "end_date": "2025-07-08"}`
- **Output** : `{"avg_temp_c": 22, "min_temp_c": 15, "max_temp_c": 28, "rain_probability": 20, "description": "Warm and pleasant", "source": "open-meteo"}`
- **Source** : Open-Meteo API (gratuite, sans cle)
- **Fallback** : Estimation par zone climatique (latitude) + saison si l'API echoue

Tous les outils utilisent un **semaphore** (`asyncio.Semaphore(3)`) pour limiter les appels Amadeus concurrents.

## Prompts (`api/src/agent/prompts.py`)

5 prompts systeme specialises :

| Prompt | Longueur | Outils autorises | Format de sortie |
|--------|----------|-------------------|------------------|
| `DESTINATION_RESEARCH_PROMPT` | ~20 lignes | resolve_iata_code, get_weather | `{destinations: [...], origin_iata}` |
| `ACTIVITY_PLANNER_PROMPT` | ~25 lignes | Aucun | `{activities: [...]}` |
| `ACCOMMODATION_PROMPT` | ~15 lignes | search_real_hotels | `{accommodations: [...]}` |
| `BAGGAGE_PROMPT` | ~15 lignes | Aucun | `{items: [...]}` |
| `BUDGET_PROMPT` | ~20 lignes | search_real_flights, resolve_iata_code | `{estimation: {...}}` |

Chaque prompt insiste sur l'utilisation de donnees reelles ("Do NOT invent prices, IATA codes, or weather data").

## Retry (`api/src/agent/retry.py`)

Wrapper `with_retry()` pour les noeuds paralleles :
- 1 retry apres echec (configurable `max_retries`)
- En cas d'echec total : **degradation gracieuse** — retourne une liste vide + evenement SSE `warning`
- Map automatique `node_name → field` : activity_planner→activities, accommodation→accommodations, baggage→baggage_items

## SSE Streaming (`api/src/api/ai/plan_trip_routes.py`)

L'endpoint `POST /v1/ai/plan-trip/stream` retourne un `StreamingResponse` avec `media_type="text/event-stream"`.

### Evenements emis

| Evenement | Donnees | Quand |
|-----------|---------|-------|
| `progress` | `{phase, message}` | Debut de chaque phase |
| `destinations` | `{destinations, origin_iata}` | Apres destination_research |
| `activities` | `{activities, source}` | Apres activity_planner |
| `accommodations` | `{accommodations, source}` | Apres accommodation |
| `baggage` | `{items}` | Apres baggage |
| `budget` | `{estimation, source}` | Apres budget |
| `complete` | `{tripPlan}` | Plan final assemble |
| `warning` | `{section, message}` | Noeud en echec (degradation) |
| `error` | `{message}` | Erreur fatale du graph |
| `heartbeat` | `{ts}` | Toutes les 15s (keepalive) |
| `done` | `{status: "complete"}` | Signal de fin du stream |

Headers de reponse : `Cache-Control: no-cache`, `Connection: keep-alive`, `X-Accel-Buffering: no`.

### Accept Plan (`POST /v1/ai/plan-trip/accept`)

Cree un trip DRAFT a partir du plan IA :
1. Resout la destination (primaire ou alternative via `selectedDestinationIndex`)
2. Fetch image de couverture Unsplash
3. Cree le trip avec `origin="AI"`
4. Cree les activites avec scheduling intelligent (`suggested_day` + `time_of_day` → `date` + `start_time`)
5. Cree les bagages IA (ou fallback i18n FR/EN si absents)

## LLM Service (`api/src/services/llm_service.py`)

Wrapper singleton autour de `langchain_openai.ChatOpenAI` :
- Modele : `gpt-oss-120b` (OVH Kepler)
- Base URL : `https://oai.endpoints.kepler.ai.cloud.ovh.net/v1`
- Temperature : 0.7
- Methodes : `call_llm()` (sync), `acall_llm()` (async), `acall_llm_messages()` (pour ReAct)
- Nettoyage automatique des code fences markdown avant parsing JSON

## Post-Trip AI (`api/src/services/post_trip_ai_service.py`)

Feature Premium : analyse les feedbacks passes de l'utilisateur et suggere un prochain voyage personalise.

- Charge les 10 derniers feedbacks avec leurs trips
- Construit un prompt avec l'historique (notes, points forts/faibles, recommandation)
- Appel LLM direct (pas de ReAct, pas de tools)
- Retourne une suggestion avec destination, duree, budget, activites

Guard : `require_premium` + `require_ai_quota`

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Pas de streaming du LLM token par token | Le streaming SSE emet des evenements par noeud, pas par token LLM. L'utilisateur attend la fin de chaque noeud. Fichier : `api/src/api/ai/plan_trip_routes.py` | P2 |
| Pas de cache Redis pour les outils | Le `IdempotencyCache` est in-memory avec TTL 5min. En multi-instance, les caches ne sont pas partages. Fichier : `api/src/utils/idempotency.py` | P1 |
| Pas de timeout global sur le graph | Si un noeud prend trop de temps (LLM lent, Amadeus timeout), le stream peut rester ouvert indefiniment. Pas de timeout global sur `astream()`. Fichier : `api/src/api/ai/plan_trip_routes.py` | P1 |
| Fallback LLM basique | Si le LLM echoue, les noeuds activity_planner et baggage retournent des listes vides ou un fallback minimal. Pas de retry au niveau LLM. Fichier : `api/src/agent/nodes/activity_planner.py` | P2 |
| Pas de tests pour le ReAct executor | Le parsing regex du ReAct output n'a pas de tests unitaires. Fichier : `api/src/agent/react_executor.py` | P1 |
| Deduplication d'evenements fragile | La deduplication SSE utilise `event_key = f"{event_type}:{node_name}"` ce qui peut manquer des cas edge. Fichier : `api/src/api/ai/plan_trip_routes.py` ligne 90 | P2 |
| Post-trip AI sans contexte d'activites | Le service `PostTripAIService` n'inclut pas les activites des trips passes dans le prompt, seulement les feedbacks. Fichier : `api/src/services/post_trip_ai_service.py` | P2 |
