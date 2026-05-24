# Agent IA - LangGraph + Orchestrateurs SSE BagTrip

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

L'agent IA de BagTrip planifie un voyage complet (destinations, vols/trains, hotels, activites,
bagages, budget) a partir des preferences declarees dans le wizard "Plan trip". L'API expose un
unique endpoint SSE `POST /v1/ai/plan-trip/stream` qui dispatche entre deux orchestrateurs :

- `InspireOrchestrator` (mode `destinations_only`) : etape "inspire-me" du wizard. Amadeus
  Flight Inspiration + enrichissement (meteo, Unsplash) + un seul appel LLM pour ranker.
- `FullPlanOrchestrator` (mode `full`) : pipeline complet origine -> destination ->
  meteo -> (activites, hebergements, transport, bagages, cover image) en parallele -> budget
  deterministe -> persistance `TripDraftCommand` via `PlanDraftService`.

Les deux orchestrateurs partagent les **memes briques agent** dans `api/src/agent/` :

- `state.py` - `TripPlanState` (TypedDict heritage LangGraph encore utilise par tests + futurs nodes).
- `tools/` - 4 outils decoupes par domaine (flights, hotels, locations, weather) + registry ReAct.
- `prompts/` - templates Jinja2 EN/FR resolus par `render(name, locale, **ctx)`.
- `runtime_budget.py` - budget cumulatif `guard` / `track` / `BudgetExceededError`.
- `react_executor.py` - boucle ReAct manuelle + JSON repair (`_repair_json_once`).
- `nodes/budget.py` - estimateur deterministe legacy reutilise par les tests + path de fallback.

Cote modele : `LLMRouter.get().chat_completion(...)` (chemin principal Full Plan / Inspire,
JSON schema strict OpenAI-compatible) ou `LLMService.acall_llm_messages(...)` (chemin ReAct).
Tous les prompts passent par `render(name, locale="en"|"fr", **ctx)` - **plus aucune constante
pre-rendered**, c'est l'invariant Sprint 4.

## Graph LangGraph

L'architecture actuelle n'execute plus un `StateGraph` LangGraph en production : le
`FullPlanOrchestrator` (Sprint 5) ordonne les sous-taches via `asyncio.gather`. Le pipeline
logique reste identique au graph historique et les tests reutilisent les nodes :

```
                    POST /v1/ai/plan-trip/stream
                                |
                                v
                    TripPlannerService.stream_plan
                                |
                +---------------+----------------+
                |                                |
       mode=destinations_only            mode=full (defaut)
                |                                |
                v                                v
       InspireOrchestrator              FullPlanOrchestrator
        .stream(InspireRequest)          .stream(FullPlanRequest)
                |                                |
                v                                v
   1. resolve origin IATA (offline)   1. LocationResolver origin + dest
   2. Amadeus FlightInspiration       2. get_weather (Open-Meteo)
   3. enrich (meteo // candidats)     3. asyncio.gather:
   4. LLM rank (inspire_rank.j2,         - activities  (LLM JSON schema)
      JSON schema strict)                - accommodations (Amadeus 2-step)
   5. Unsplash covers parallel           - transport (Amadeus or train)
   6. event "destinations" + "complete"  - baggage (LLM JSON schema)
                                         - cover image (Unsplash)
                                      4. _compute_budget deterministe
                                      5. emit destinations / weather /
                                         activities / accommodations /
                                         transport / baggage / budget
                                      6. emit "complete" {trip_draft}
                                                 |
                                                 v
                                  feasibility_pass.schedule_activities
                                                 |
                                                 v
                                  PlanDraftService.create_draft_from_command
                                                 |
                                                 v
                                  re-emit "complete" {tripId, status}
                                                 |
                                                 v
                                       finally: emit "done"
```

Le `TripPlanState` legacy reste utilise par `nodes/budget.py` (estimateur deterministe) et par
les tests qui pilotent le node en isolation. Tout nouveau node ecrit aujourd'hui via
l'orchestrator code-only conserve la convention "1 sous-tache = 1 corofunction" + JSON schema
strict cote LLM, ce qui evite la double couche ReAct / parsing manuel.

## State

`TripPlanState` (`api/src/agent/state.py`) est un `TypedDict(total=False)` partage par les
nodes residuels et certains tests. Les champs annotes avec `operator.add` utilisent un reducer
LangGraph pour le fan-in parallele.

| Bloc | Champ | Type | Source / role |
|---|---|---|---|
| Inputs wizard | `travel_types` | `str` | Tags du wizard (CULTURE, NATURE, ...) |
| | `duration_days` | `int` | Nombre de jours du voyage |
| | `companions` | `str` | "solo", "couple", "family", "friends" |
| | `constraints` | `str` | Texte libre (allergies, mobilite, "TGV"...) |
| | `departure_date` / `return_date` | `str` (YYYY-MM-DD) | Dates utilisateur |
| | `origin_city` / `destination_city` | `str` | Texte saisi |
| | `destination_iata` | `str` | IATA pre-rempli (flow manuel ou retour W1) |
| | `travel_style` / `season` | `str` | Profil voyageur |
| | `nb_travelers` | `int` | Compte de voyageurs (defaut 1) |
| | `budget_preset` | `str` | BACKPACKER / COMFORTABLE / PREMIUM / NO_LIMIT |
| | `target_budget` | `float \| None` | Plafond numerique sanity-check (Topic 01) |
| | `date_mode` | `str` | Mode date du wizard |
| Destination | `origin_iata` | `str` | IATA resolue de l'origine |
| | `destinations` | `list[dict]` | Liste de candidats |
| | `selected_destination` | `dict` | `{city, country, iata, lat, lon}` |
| | `weather_data` | `dict` | Snapshot Open-Meteo |
| Parallel outputs | `activities` | `list[dict]` | Idees d'activites pre-feasibility |
| | `accommodations` | `list[dict]` | Hotels Amadeus + price_total/per_night |
| | `baggage_items` | `list[dict]` | Liste de packing |
| Budget | `budget_estimation` | `dict` | Breakdown par categorie + min/max |
| | `flight_offers` | `list[dict]` | Offres Amadeus brutes pour Flutter |
| Accumulators | `events` | `Annotated[list[dict], add]` | SSE buffer LangGraph (fan-in) |
| | `errors` | `Annotated[list[str], add]` | Warnings non fataux |
| Final | `trip_plan` | `dict` | Plan assemble |
| Runtime budget | `budget_deadline_monotonic` | `float` | Deadline `time.monotonic()` |
| | `budget_consumed_seconds` | `float` | Temps deja consomme par les nodes |
| Locale | `locale` | `str` | "en" ou "fr", thread jusqu'aux templates Jinja2 |

## Nodes

Le `FullPlanOrchestrator` execute les "nodes" en methodes `@classmethod` async. Quelques nodes
historiques restent dans `api/src/agent/nodes/` (utilises par les tests et le path
deterministe). Tableau combine :

| Node / sub-task | Role | Tools / API | Appel LLM |
|---|---|---|---|
| `_resolve_destination` (FullPlan) | Resout `destination_city` ou `destination_iata` -> `ResolvedLocation` | `LocationResolver` (offline `airportsdata` + cascade multilingue) | non |
| `_fetch_weather` (FullPlan) | Snapshot meteo destination, alimente prompts activites + bagages | `tools.weather.get_weather` (Open-Meteo) + fallback climat-zone | non |
| `_brainstorm_activities` (FullPlan) | Genere 6-9 `ActivityDraft` ancres meteo/profil/budget | aucun | `activity_planner.j2` (JSON schema strict, T=0.5, max_tokens=1800) |
| `_search_accommodations` (FullPlan) | Liste les 10 premiers hotels 3-5 etoiles + offres tarifaires | `AmadeusService.search_hotel_list` + `search_hotel_offers` | non |
| `_build_transport` (FullPlan) | Choisit FLIGHT vs TRAIN (meme pays + < `TRAIN_THRESHOLD_KM`) puis construit les jambes | `AmadeusService.search_flight_offers` OR heuristique train per-100km | non |
| `_advise_baggage` (FullPlan) | Genere 10-14 `BaggageDraft` weather-aware | aucun | `baggage.j2` (JSON schema strict, T=0.4, max_tokens=1200) |
| `_fetch_cover_image` (FullPlan) | Image Unsplash + fallback deterministe | `unsplash_client.fetch_cover_image` | non |
| `_compute_budget` (FullPlan) | Breakdown deterministe : transport reel converti EUR, accommodation min, food/transport par-preset | `currency_service.convert` | non |
| `_resolve_origin_iata` (Inspire) | IATA origine via offline aviation data | `AviationDataService.search_by_keyword` | non |
| `_fetch_inspirations` (Inspire) | Amadeus Flight Inspiration -> N candidats trie cheapest first | `AmadeusService.search_flight_destinations` | non |
| `_enrich_candidates` (Inspire) | Meteo en parallele sur les `TOP_K_CANDIDATES` | `tools.weather.get_weather` | non |
| `_rank_with_llm` (Inspire) | Selectionne `pick_count` candidats + narrative copy, IATA contraint a l'enum | aucun | `inspire_rank.j2` (JSON schema enum sur IATA, T=0.4, max_tokens=900) |
| `_llm_only_fallback` (Inspire) | Path degradation quand Amadeus inspiration KO ; over-fetch + resolution offline | `LLMRouter` + `AviationDataService` | `destination_quick.j2` (JSON schema, T=0.6, max_tokens=1400) |
| `nodes/budget.py:budget_node` | Estimateur deterministe legacy (test + path fallback) ; `guard(state, min_required=2.0)` | `search_real_flights` + haversine fallback | non |
| `post_trip_suggester.py` | Premium : suggere le prochain voyage a partir des feedbacks passes | `LLMRouter` | `post_trip_suggestion.j2` |

## Tools

Tous les tools vivent sous `api/src/agent/tools/` et sont exposes via le registry partage
`TOOL_REGISTRY` consomme par le ReAct executor. Concurrence Amadeus capee par
`_amadeus_semaphore = asyncio.Semaphore(3)` (`tools/_shared.py`).

### `agent/tools/flights.py`

| Element | Valeur |
|---|---|
| Function | `search_real_flights(origin, destination, date, return_date=None, adults=1)` |
| API | Amadeus Flight Offers Search (max 5 offres, `currencyCode="EUR"`) |
| Retour | `{flights: [...], cheapest: float, currency: "EUR", source: "amadeus"}` |
| Cache | `idempotency_cache` keye sur `(origin, destination, date, return_date, adults)` |
| Erreur | `{error, source: "error"}` ; le node appelant fallback sur `_synthesize_flight_offer` (haversine + cost lineaire) |
| Concurrence | Acquiert `_amadeus_semaphore` |

### `agent/tools/hotels.py`

| Element | Valeur |
|---|---|
| Function | `search_real_hotels(city_code, check_in, check_out, adults=1)` |
| API | Amadeus Hotel List (`ratings="3,4,5"`) -> 10 premiers `hotelId` -> Hotel Offers (`currency="EUR"`) |
| Retour | `{hotels: [{name, hotel_id, rating, price_total, price_per_night, nights, ...}], source: "amadeus"}` |
| Particularite | `price_total` ET `price_per_night` sont exposes simultanement (bug B23 : un seul champ ambigu re-multiplie par nights provoquait l'inflation budget) |
| Cache | `idempotency_cache` keye sur `(city_code, check_in, check_out, adults)` |
| Erreur | `{hotels: [], source: "error", error: str}` |

### `agent/tools/locations.py`

| Element | Valeur |
|---|---|
| Function | `resolve_iata_code(city_name)` |
| API | Offline `AviationDataService.search_by_keyword(sub_type="CITY,AIRPORT", limit=1)` |
| Retour | `{iata, city, country, lat, lon}` ou `{error}` |
| Cache | aucun (offline, deja O(1)) |

### `agent/tools/weather.py`

| Element | Valeur |
|---|---|
| Function | `get_weather(latitude, longitude, start_date, end_date)` |
| API | Open-Meteo Forecast (gratuit, sans cle, `daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max`) |
| Retour | `{avg_temp_c, min_temp_c, max_temp_c, rain_probability, description, source: "open-meteo"}` |
| Cache | `idempotency_cache` keye sur `(lat, lon, start, end)` |
| Fallback | `_fallback_weather(start_date, latitude)` : climate-zone par latitude absolue (subarctic / temperate / subtropical / tropical) + saison hemisphere ; `source: "estimated_climate_zone"` |

## ReAct executor + JSON repair

Fichier : `api/src/agent/react_executor.py`. Conserve pour le path legacy (`nodes/budget.py`
peut encore appeler `search_real_flights` directement, mais le ReAct loop reste branche dans
les nodes historiques + tests).

Le modele OVH `gpt-oss-120b` ne supporte pas le function-calling natif : ReAct est implemente
en prompt-only :

```
1. Compose system prompt : agent_instruction + descriptions tools (depuis TOOL_REGISTRY)
2. Boucle (max 5 iterations) :
   - Appel LLM avec timeout `settings.LLM_CALL_TIMEOUT_SECONDS`
   - parse_react_output(raw) :
       * "Final Answer: <json>" -> retourne str (a parser)
       * "Action: <tool> / Action Input: <json>" -> retourne (tool_name, dict)
       * sinon -> traite la sortie comme final answer (avec recovery JSON par regex)
   - Si tool call : execute tool_registry[tool_name]["fn"](**tool_input)
   - Re-injecte "Observation: <json_result>" dans la conversation
3. Final answer :
   - _parse_final_answer(raw) : tente json.loads ; renvoie None si KO
   - Si KO et settings.REACT_JSON_REPAIR_ENABLED :
       _repair_json_once(llm, raw, error)
         -> single re-prompt ("Your previous response was not valid JSON. Parse error: ...")
         -> max 1 retry, jamais en boucle
         -> succes : log "JSON repair succeeded"
         -> echec : retourne {raw_answer, repair_failed: True}
4. Si max iterations atteint -> dernier prompt "provide your Final Answer now"
```

Points de durete :

- **Markdown stripping** : le repair re-strip les fences ```json``` au cas ou la LLM les
  re-ajoute. Defensif - le modele OVH re-emet parfois des fences malgre l'instruction.
- **Tool call type errors** captees separement (`TypeError`) pour fournir un message exploitable
  au LLM (`"Error calling {tool_name}: invalid parameters - {e}"`) au lieu d'un traceback brut.
- **JSON recovery par regex** : si `Action Input` ne parse pas, regex `\{[^}]+\}` tente
  d'extraire un objet ; sinon `{raw}` est envoye et le LLM corrigera a l'iteration suivante.
- **TimeoutError** propage en `{"error": "LLM call timed out after Ns"}` que le caller
  surface en SSE `warning` / `error`.

`MAX_REACT_ITERATIONS = 5`. Au-dela, force un `Final Answer` ; double parse failure -> retour
`{raw_answer, repair_failed: True}` sans crash.

## Budget cumulatif

Fichier : `api/src/agent/runtime_budget.py`. Adresse le trou entre :

- `settings.GRAPH_TIMEOUT_SECONDS` qui cap le **total** stream (`async_generator_with_timeout`
  cote `TripPlannerService`).
- `settings.NODE_TIMEOUT_SECONDS` qui cap chaque **node individuel** wrappe `with_retry`.

Aucun des deux n'empeche une chaine de nodes lents de tenir individuellement sous leur cap
tout en explosant le total. Solution : un budget partage stocke dans `state` comme
`time.monotonic()` deadline.

### API

```python
from src.agent.runtime_budget import BudgetExceededError, guard, remaining, track

async def my_node(state: TripPlanState) -> dict:
    guard(state, min_required=5.0)        # raise BudgetExceededError si < 5s
    async with track(state, "my_node"):   # cumul du temps consomme
        await asyncio.wait_for(heavy_call(), timeout=remaining(state))
```

| Helper | Comportement |
|---|---|
| `remaining(state)` | `max(0.0, deadline - time.monotonic())`. Retourne `inf` si `budget_deadline_monotonic` absent (tests, anciens checkpoints) - backward compat |
| `consumed(state)` | Lit `budget_consumed_seconds` (defaut 0.0) |
| `guard(state, *, min_required)` | Raise `BudgetExceededError(f"Graph budget exhausted: {left:.1f}s left, need {min_required:.1f}s")` si `remaining < min_required` |
| `track(state, node_name)` | Context manager async. `finally` ajoute `elapsed` a `budget_consumed_seconds` MEME en cas d'exception (le node a consomme du temps quoi qu'il arrive). Warn log si `remaining < 5.0` apres execution |
| `BudgetExceededError` | Exception dediee. Alias backward-compat : `BudgetExceeded` |

`BudgetExceededError` remonte jusqu'a `TripPlannerService.stream_plan` qui le wrap en
`event: error` ; le `finally` general emet quand meme `done` pour que le client ne reste pas
suspendu. Le node `budget_node` (`nodes/budget.py`) demarre avec `guard(state, min_required=2.0)` -
un budget exhausted juste avant l'agregation est non bloquant car la sous-chaine fait surtout
de la sommation en memoire.

## Prompts Jinja2 EN/FR

Resolveur : `api/src/agent/prompts/__init__.py`. **`render(name, locale="en", **ctx)` est le seul
point d'entree**. Les constantes Python `XXX_PROMPT` pre-rendered ont ete supprimees au Sprint 4.

```python
from src.agent.prompts import render

system_prompt = render(
    "activity_planner",
    locale=normalize_locale(req.locale),  # "en" | "fr"
    target=9,
)
```

Comportement :

| Aspect | Valeur |
|---|---|
| Templates root | `api/src/agent/prompts/templates/{locale}/{name}.j2` |
| Locale par defaut | `"en"` |
| Fallback | Si `templates/<locale>/<name>.j2` absent -> tente `templates/en/<name>.j2` -> sinon `ValueError` (= typo dans le caller) |
| `StrictUndefined` | Toute variable Jinja absente du `**ctx` -> raise au render. Crash bruyant = mieux qu'un prompt silencieusement casse |
| `autoescape` | `False` (bandit B701 # nosec) : les templates contiennent des blocs JSON schema `{"a": 1}`, l'escape HTML les casserait. Pas de surface XSS : sortie injectee dans `LLMRouter.chat_completion` jamais servie au browser |
| `keep_trailing_newline` | True (les prompts se terminent par un newline) |

### Templates livres

| Template | EN | FR | Consumer |
|---|---|---|---|
| `activity_planner.j2` | 2145 o | 2424 o | `FullPlanOrchestrator._brainstorm_activities` + `ActivityService` (re-suggest manuel) |
| `accommodation.j2` | 652 o | 747 o | path legacy `nodes/accommodation` (deprecated) |
| `accommodation_suggest.j2` | 719 o | 871 o | `AccommodationsService` (re-suggest manuel depuis trip detail) |
| `baggage.j2` | 691 o | 898 o | `FullPlanOrchestrator._advise_baggage` + `BaggageItemsService` |
| `budget.j2` | 955 o | 1027 o | reserve - estimateur LLM (path legacy) |
| `destination_quick.j2` | 2217 o | 2560 o | `InspireOrchestrator._llm_only_fallback` |
| `inspire_rank.j2` | 1686 o | 1735 o | `InspireOrchestrator._rank_with_llm` |
| `post_trip_suggestion.j2` | 1001 o | 1148 o | `PostTripSuggester` (feature Premium) |
| `rank_destinations.j2` | 1442 o | 1583 o | reserve - future re-ranking pass |

### Threading locale

Chaque caller normalise via `normalize_locale(request.locale or "en")` puis passe l'argument
explicitement a `render(...)`. Le state `TripPlanState.locale` porte la valeur de bout en
bout pour les nodes legacy. Les templates FR sont autonomes (pas de `{% include "en/..." %}`
restant) - la cascade de fallback `fr` -> `en` reste un filet de securite cote loader.

## SSE streaming

`TripPlannerService.stream_plan(request, user_id, db)` est l'unique point de sortie SSE.
Pattern : `_sse(event, data)` produit `"event: <type>\ndata: <json>\n\n"`. `try / finally`
englobe TOUT le pipeline pour garantir que `done` est emis meme sur exception fatale.

```python
try:
    if request.mode == "destinations_only":
        async for ev_type, ev_data in InspireOrchestrator.stream(inspire_req):
            yield _sse(ev_type, ev_data)
        return

    async for ev_type, ev_data in FullPlanOrchestrator.stream(full_req):
        if ev_type == "complete":
            trip_draft_payload = ev_data.get("trip_draft")
            continue                       # absorbe le complete brut
        yield _sse(ev_type, ev_data)

    # feasibility pass + persistance + re-emit complete avec tripId
    cmd.activities = schedule_activities(cmd)
    trip = PlanDraftService.create_draft_from_command(db, user, cmd)
    yield _sse("complete", {"tripId": str(trip.id), "tripDraft": ...})
    PlanService.increment_ai_generation(db, user)
except Exception as exc:
    yield _sse("error", {"message": str(exc)})
finally:
    yield _sse("done", {"status": "complete"})
```

### Protocole events

| Event | Quand | Payload (camelCase pour les keys exposees Flutter) |
|---|---|---|
| `progress` | Debut de chaque phase | `{phase, message?, originIata?, ...}` |
| `destinations` | Apres ranking (Inspire) ou apres parallel planning (Full) | `{destinations: [...], originIata}` |
| `weather` | Apres `_fetch_weather` (Full) | `WeatherSummary` asdict |
| `activities` | Apres `_brainstorm_activities` | `{activities: [ActivityDraft, ...]}` |
| `accommodations` | Apres `_search_accommodations` | `{accommodations: [AccommodationDraft, ...]}` |
| `transport` | Apres `_build_transport` | `{legs: [TransportLeg, ...]}` |
| `baggage` | Apres `_advise_baggage` | `{items: [BaggageDraft, ...]}` |
| `budget` | Apres `_compute_budget` | `{budget: BudgetBreakdown}` |
| `warning` | Sous-tache en echec (orchestrator code stable) | `{code: "ACCOMMODATIONS_AMADEUS_DOWN" \| "ACTIVITIES_FAILED" \| ..., message}` |
| `error` | Erreur fatale (origin/dest unresolvable, LLM JSON KO, BudgetExceededError) | `{code?, message}` |
| `complete` | Plan persiste server-side | `{tripId, status, tripDraft}` |
| `done` | Fin garantie (`finally`) | `{status: "complete"}` |

Headers HTTP : `Cache-Control: no-cache`, `Connection: keep-alive`, `X-Accel-Buffering: no`
(desactive le buffering Nginx -> evite que les events restent bloques 4-5s).

### Idempotency cache (tools)

`src.utils.idempotency.idempotency_cache` est un cache in-memory TTL utilise par
`search_real_flights`, `search_real_hotels`, `get_weather`. Cle = `(tool_name, params)`. Pas
de Redis derriere -> en multi-worker chaque process a son propre cache (cf section
"Ce qu'il manque").

### Persistance post-stream

Apres le `complete` brut du `FullPlanOrchestrator`, `TripPlannerService` :

1. `schedule_activities(cmd)` (`feasibility_pass.py`) - assigne les `suggested_day` /
   `time_of_day` manquants, trie en ordre calendaire pour matcher l'affichage Flutter.
2. `PlanDraftService.create_draft_from_command(db, user, cmd)` - cree le `Trip` en statut
   DRAFT + activites + accommodations + transport + baggage + budget items en une transaction.
3. Re-emet un `complete` enrichi `{tripId, status, tripDraft}` (le client appelle
   `/v1/trips/{tripId}` pour la suite ; pas de route `accept` separee depuis SMP-325).
4. `PlanService.increment_ai_generation(db, user)` decremente le quota Free.

## Ce qu'il manque

| Element | Description | Priorite |
|---|---|---|
| Cache Redis pour les tools | `idempotency_cache` est in-memory TTL ; en multi-worker chaque process a son cache. Migrer vers Redis (deja singleton dans `integrations/redis_client.py`) economiserait les appels Amadeus repetes entre instances | P1 |
| Timeout global cote orchestrators | `FullPlanOrchestrator` n'embarque pas de `runtime_budget` ; seuls les nodes legacy le consomment. Un Amadeus lent + une LLM lente cumules peuvent depasser `GRAPH_TIMEOUT_SECONDS` sans deadline interne explicite | P1 |
| Tests ReAct executor | `parse_react_output` et `_repair_json_once` n'ont pas de tests unitaires dedies. Les regex fences + recovery JSON sont fragiles aux variations modele | P1 |
| Streaming LLM token-par-token | Les events SSE sont emis par sous-tache (gate sur la fin du `chat_completion`) ; l'utilisateur attend la fin du brainstorm pour voir des activites. Streamer le `delta` LLM par chunk reduirait la perception de latence | P2 |
| Convergence agent/orchestrator | `nodes/budget.py` + `tools/__init__.py` portent un duplicat partiel de la logique flight/hotel (estimateur deterministe + synthese haversine). Decision a prendre : retirer le legacy ou rebrancher le FullPlanOrchestrator dessus pour eviter la divergence | P2 |
| Tests fallback LLM-only Inspire | `_llm_only_fallback` deroule un schema strict + cascade de resolution offline ; couverture des cas IATA hallucines limitee | P2 |
| `accommodation_suggest` re-prompt | Le re-suggest manuel depuis trip detail (`AccommodationsService`) appelle directement le LLM sans JSON schema strict cote OVH ; pas de JSON repair si la sortie casse | P2 |
| Post-trip suggester sans contexte activites | `PostTripSuggester` lit feedbacks + trips mais n'injecte pas les activites des voyages passes -> suggestions moins personnalisees | P3 |
| FR templates fige | Les templates FR sont autonomes mais n'ont pas de pipeline de revue lexicale ; certaines tournures restent traduites mot-a-mot de l'EN | P3 |
