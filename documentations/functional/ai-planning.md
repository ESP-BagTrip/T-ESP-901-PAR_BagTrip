# Planification IA — Pipeline multi-agents et SSE streaming

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

La planification IA de BagTrip habille trois workflows distincts derriere un meme socle de prompts, d'outils et d'observabilite :

- **W1 Inspire AI** (`mode=destinations_only`) : suggere 3-4 destinations reachable depuis la ville d'origine, classees via Amadeus Flight Inspiration puis narrees par un LLM. Le client recupere une liste de cartes avant le wizard de planification complet.
- **W2 Full plan** (`mode=full`) : produit un brouillon de voyage complet (activites, hebergements, transport, bagages, budget) a partir d'une destination choisie. Le pipeline persiste le `Trip` cote serveur et renvoie un `tripId` dans le `complete`.
- **W3 Post-trip suggestion** : pipeline RAG (BGE-M3 + cosine) qui propose la prochaine destination en se basant sur les feedbacks passes. La cible est verrouillee par cosinus, le LLM ne fait que la narration.

L'orchestration mobile passe par un BLoC consommant un flux SSE (`PlanTripBloc`) qui dispatch les evenements vers la View. Le projet a migre en cours de route de la pile **LangGraph + ReAct executor** (toujours presente pour la legacy / certains chemins isoles) vers un orchestrateur Python pur (`FullPlanOrchestrator` / `InspireOrchestrator` / `PostTripSuggester`) qui pilote des appels LLM en JSON Schema strict et parallelise les sous-taches via `asyncio.gather`. Le quota d'usage IA est applique via un `Depends(require_ai_quota)` cote routes ; le W3 ajoute `Depends(require_premium)`.

## Architecture LangGraph

### Layout du package `src/agent/`

| Module | Role |
|---|---|
| `agent/state.py` | `TripPlanState` (TypedDict total=False) — etat partage par les noeuds, champs `Annotated[..., operator.add]` pour les reducers (events, errors) |
| `agent/runtime_budget.py` | Budget cumulatif (`guard`, `track`, `BudgetExceededError`) base sur `time.monotonic()` |
| `agent/react_executor.py` | Boucle ReAct manuelle (Thought / Action / Observation / Final Answer) + JSON repair single-shot |
| `agent/nodes/budget.py` | Noeud deterministe d'agregation budget (Amadeus + activites) |
| `agent/tools/__init__.py` | `TOOL_REGISTRY` agregeant flights / hotels / locations / weather |
| `agent/tools/flights.py` | `search_real_flights` (Amadeus + idempotency cache) |
| `agent/tools/hotels.py` | `search_real_hotels` (Amadeus 2-step) |
| `agent/tools/locations.py` | `resolve_iata_code` (offline `airportsdata`) |
| `agent/tools/weather.py` | `get_weather` (Open-Meteo + fallback statique) |
| `agent/prompts/__init__.py` | `render(name, locale, **ctx)` Jinja2 avec fallback EN |
| `agent/prompts/templates/{en,fr}/*.j2` | Templates par langue (FR `include` EN par defaut) |

### TripPlanState — champs cles

| Champ | Source | Consommateur |
|---|---|---|
| `origin_iata`, `destinations`, `selected_destination` | resolution destination | tous les noeuds |
| `weather_data` | `get_weather` | activites + bagages + budget |
| `activities`, `accommodations`, `baggage_items` | nodes paralleles | budget + assembleur |
| `flight_offers` | budget_node (Amadeus direct ou synthetique) | persistence + UI |
| `budget_estimation` | budget_node (deterministe) | persistence + UI |
| `events`, `errors` | reducer `operator.add` | SSE serializer |
| `budget_deadline_monotonic`, `budget_consumed_seconds` | initial state | `guard` / `track` |
| `locale` | request | `render()` dans chaque noeud |

### Budget cumulatif

`settings.GRAPH_TIMEOUT_SECONDS` borne le stream complet, `settings.NODE_TIMEOUT_SECONDS` chaque appel — ni l'un ni l'autre ne protege contre un enchainement de noeuds lents qui restent individuellement dans leur quota. `runtime_budget.guard(state, min_required=5.0)` est appele en tete de chaque noeud lourd : si moins de 5 s restent avant la deadline, l'erreur `BudgetExceededError` remonte jusqu'au service qui emet un event SSE `error` puis le `done` final dans le `finally`. Le context manager `async with track(state, "node_name"):` incremente `budget_consumed_seconds` meme en cas d'exception (pour facturer le temps brule par un noeud KO) et log un WARN si le reste passe sous 5 s.

### ReAct executor + JSON repair

`react_executor.react_execute` est utilise par les chemins legacy ou le modele ne supporte pas le tool calling natif (gpt-oss-120b). La boucle (max 5 iterations par defaut) :

1. Compose un system prompt avec les descriptions des tools du `TOOL_REGISTRY`.
2. Appelle le LLM via `LLMService.acall_llm_messages` (timeout `LLM_CALL_TIMEOUT_SECONDS`).
3. Parse la sortie : `Action: <tool>` + `Action Input: <json>` ou `Final Answer: <json>`.
4. Execute le tool, reinjecte la `Observation:` dans la conversation.
5. Repete jusqu'a Final Answer ou max iterations (force un Final Answer).

Le **JSON repair** (`_repair_json_once`) est un re-prompt unique correctif lance quand le Final Answer ne parse pas. Si la deuxieme tentative echoue, l'executor renvoie `{"raw_answer": ..., "repair_failed": True}` — jamais de degrade silencieux. Le flag `settings.REACT_JSON_REPAIR_ENABLED` permet de couper le repair en cas de double facturation indesiree.

### Prompts EN/FR

Les anciens constants pre-rendus (`DESTINATION_RESEARCH_PROMPT`, etc.) ont ete supprimes au Sprint 4. **Seul `render(name, locale=...)` est autorise.** Les templates Jinja2 vivent sous `agent/prompts/templates/{locale}/{name}.j2` ; le resolver tente la locale demandee puis fallback EN. `StrictUndefined` impose qu'une variable manquante crash a render-time (mieux qu'un prompt silencieusement casse). FR fallback vers EN via `{% include "en/..." %}` tant qu'une traduction n'est pas ecrite. Les templates actuels : `activity_planner`, `accommodation`, `accommodation_suggest`, `baggage`, `budget`, `destination_quick`, `inspire_rank`, `post_trip_suggestion`, `rank_destinations`.

### Locale threading

`PlanTripRequest.locale` (`"en"` par defaut, ou `"fr"`) est mappe sur `TripPlanState["locale"]` par `TripPlannerService._build_initial_state` (legacy) et thread aux orchestrateurs `FullPlanOrchestrator` / `InspireOrchestrator` via leur dataclass de requete. Chaque appel `render()` recoit la locale, et `normalize_locale` la canonicalise. Le post-trip lit `Accept-Language` du header HTTP via `normalize_locale(raw_request.headers.get("accept-language"))`.

### Tools — Amadeus, Open-Meteo, aviation data

| Tool | Backend | Cache | Fallback |
|---|---|---|---|
| `resolve_iata_code(query)` | `airportsdata` offline | n/a (in-memory) | aucun (lookup local) |
| `search_real_flights(origin, destination, date, return_date, adults)` | Amadeus Flight Offers Search | `idempotency_cache` keye sur tous les params | budget_node synthetise un offer haversine + 0.10 EUR/km + 80 EUR overhead si Amadeus KO |
| `search_real_hotels(cityCode, checkInDate, checkOutDate, adults)` | Amadeus Hotel List + Hotel Offers (2-step) | Redis TTL | `AccommodationDraft(source="deferred", price=0)` — UI affiche "Hotel a choisir" |
| `get_weather(lat, lon, start_date, end_date)` | Open-Meteo forecast | n/a | `_fallback_weather` (constantes saisonnieres) |

Les tools partagent un `_amadeus_semaphore` global (`agent/tools/_shared.py`) qui borne la concurrence Amadeus pour rester sous le RPM contractuel. Cote LLM, `LLMRouter` impose une autre semaphore globale et une chaine de fallback model par model.

### LLMRouter

`src/services/llm_router.py` est l'unique ingress LLM du process. Il centralise :

- **Chain de fallback model** : primary → fallbacks. Un modele qui rejette la requete (400 unsupported feature, 422 schema rejection) skip au candidat suivant ; un 5xx / 408 / 429 / erreur reseau declenche un retry tenacity avec backoff exponentiel + jitter.
- **Concurrence** : `asyncio.Semaphore` partage cap les calls in-flight pour ne pas exploser le RPM OVH.
- **Tracing structure** : chaque call log model, attempt, latency, prompt/completion tokens, finish_reason. Suffisant pour reconstruire une session d'agent sans la rejouer.
- **Surfaces** : `chat_completion` (sync), `stream_chat_completion` (tokens), `embed` (BGE-M3). `LLMService` est un shim qui preserve les anciennes signatures (`acall_llm`, `acall_llm_messages`) consommees par `react_executor`.

## Orchestrators

| Service | Pipeline | LLM calls |
|---|---|---|
| `InspireOrchestrator` | resolve origin → Amadeus Flight Inspiration → enrich top-K → rank + narrate (1 call) → cover Unsplash | 1 call structured + 1 fallback LLM-only si Amadeus KO |
| `FullPlanOrchestrator` | resolve origin/dest → weather (sequentiel) → `asyncio.gather`(activities, accommodations, transport, baggage, cover) → budget deterministe | 2 calls JSON schema (activities + baggage) |
| `PostTripSuggester` | feedbacks last 10 → corpus → embed BGE-M3 → cosine vs `destination_catalog` → narration LLM | 1 embed + 1 narration JSON schema |

Le `TripPlannerService.stream_plan` est le point d'entree HTTP qui dispatch sur `InspireOrchestrator` (mode `destinations_only`) ou `FullPlanOrchestrator` (defaut). Pour le full plan il :

1. Drain les events de l'orchestrateur, capture le `complete` (et son `trip_draft`) sans le forwarder.
2. Applique la **feasibility pass** deterministe (`schedule_activities`) qui assigne les jours et la fenetre horaire des activites.
3. Persiste via `PlanDraftService.create_draft_from_command` (cree le `Trip`, les `Activity`, `Accommodation`, `ManualFlight`, `BaggageItem`, `BudgetItem`).
4. Re-emet un `complete` enrichi avec `tripId`, `status`, `tripDraft`.
5. Incremente le compteur AI via `PlanService.increment_ai_generation`.
6. Garantit le `done` final dans le `finally` meme si une exception remonte.

## SSE protocol

Endpoint unique : `POST /v1/ai/plan-trip/stream` (body : `PlanTripRequest`, header `Authorization: Bearer <jwt>`). Reponse : `StreamingResponse` en `text/event-stream` avec `Cache-Control: no-cache`, `X-Accel-Buffering: no`.

Format wire : `event: <type>\ndata: <json>\n\n`.

### Event types

| Event | Mode | Payload | Description |
|---|---|---|---|
| `progress` | full + inspire | `{phase, message?, ...}` | Etape courante (`starting`, `resolving_origin`, `weather`, `parallel_planning`, `enriching`, `ranking`) |
| `destinations` | full + inspire | `{destinations: [...], originIata}` | Cartes de destinations (1 element en `full`, 3-4 en `inspire`) |
| `weather` | full | `{avg_temp_c, min/max, rain_probability, description, source}` | Open-Meteo summary |
| `activities` | full | `{activities: [{title, description, category, estimated_cost, suggested_day?, time_of_day?, location?}]}` | Brouillon d'activites (target 9, feasibility-pass plus tard) |
| `accommodations` | full | `{accommodations: [{name, hotel_id, rating, price_total, price_per_night, nights, currency, check_in, check_out, source}]}` | Hotels Amadeus 3-5 etoiles |
| `transport` | full | `{legs: [{mode, direction, carrier, code, origin_iata, destination_iata, departure_at, arrival_at, price, currency, source}]}` | Vols (Amadeus) ou train (estimate same-country < 1000 km) |
| `baggage` | full | `{items: [{name, quantity, category, reason}]}` | Packing-list contextuelle (target 14) |
| `budget` | full | `{budget: {transport, accommodation, food, activity, total_min, total_max, currency, ...sources}}` | Breakdown deterministe en EUR |
| `warning` | full + inspire | `{code, message}` | Degradation soft (`ACCOMMODATIONS_AMADEUS_DOWN`, `TRANSPORT_AMADEUS_DOWN`, `ACTIVITIES_FAILED`, `BAGGAGE_FAILED`, `INSPIRE_AMADEUS_DOWN`) |
| `error` | full + inspire | `{code, message}` | Erreur fatale (`ORIGIN_UNRESOLVED`, `DESTINATION_UNRESOLVED`, `ACTIVITIES_INVALID_JSON`, etc.) |
| `complete` | full + inspire | full : `{tripId, status, tripDraft}` / inspire : `{destinations, mode, originIata, source, elapsed_s}` | Fin logique du run |
| `done` | full + inspire | `{status: "complete"}` | Cloture du stream — toujours emis dans le `finally` |
| `heartbeat` | (filtre cote client) | — | Maintien de connexion ; ignore par le parser mobile |

Le `complete` du `FullPlanOrchestrator` est swallowed par `TripPlannerService` et re-emis apres persistence avec `tripId`. Le client doit lire le `complete` final (apres budget) pour recuperer le `tripId` et naviguer vers le detail.

## Cote Mobile

### Consommation SSE

| Fichier | Role |
|---|---|
| `lib/service/ai_service.dart` | `AiRepositoryImpl.planTripStream` — Dio POST en `ResponseType.stream`, parse SSE ligne par ligne |
| `lib/repositories/ai_repository.dart` | Contrat `AiRepository` (interface) |
| `lib/plan_trip/bloc/plan_trip_bloc.dart` | `PlanTripBloc` — pilote le wizard 6 etapes, gere le stream a l'etape 4 |
| `lib/post_trip/bloc/post_trip_bloc.dart` | Stats post-voyage (non-IA — stats trip / activites / budget) |
| `lib/service/agent_service.dart` | Chat agent (stub Epic 6, non utilise en prod) |

### Parsing du flux

Le parser SSE de `AiRepositoryImpl.planTripStream` :

1. Construit le body camelCase (`travelTypes`, `originCity`, `destinationCity`, `destinationIata`, `mode`, `locale`).
2. Recupere le JWT via `StorageService`, pose les headers `Authorization`, `Accept: text/event-stream`.
3. Lance un `Dio` dedie en `ResponseType.stream` (le client principal `flutter_client_sse` bufferise sur certaines plateformes — c'etait un bug observe).
4. Lit le `byteStream` ligne par ligne (`utf8.decoder` + `LineSplitter`).
5. Accumule `event:` + `data:` jusqu'a la ligne vide qui delimite un block SSE.
6. Filtre les `heartbeat`, JSON-decode la `data` puis yield `{event, data}` en `Stream<Map<String, dynamic>>`.

### Cancellation

`PlanTripBloc` appelle `_cancelSseStream()` avant tout nouveau stream (retry, `BackToProposals`, `close`). La regle CLAUDE.md impose explicitement d'appeler le cancel avant un nouveau `planTripStream` pour eviter les fuites de subscription et les states race. Le `Dio` interne est ferme (`dio.close()`) en fin de stream — `await for` se termine naturellement sur `done`.

### Inspire (getInspiration)

`getInspiration({required originCity, ...})` reutilise `planTripStream` en `mode: 'destinations_only'`, drain le flux jusqu'au premier `destinations` ou `complete`, et retourne `Success(destinations.cast<Map>())`. Stop conditions : `done` ou `error`.

### Post-trip

`getPostTripSuggestion()` appelle `POST /ai/post-trip-suggestion` (pas de SSE — reponse synchrone). Le backend repond `{suggestion: {destination, destinationCountry, durationDays, budgetEur, description, highlightsMatch, activities}}`. Le client extrait `data['suggestion']` et renvoie `Success(Map<String, dynamic>)`.

## Post-trip suggestions

### Pipeline W3

1. **Feedback lookback** : `db.query(Feedback, Trip).filter(user_id).order_by(desc(created_at)).limit(10)`. Si aucun feedback → `AppError NO_FEEDBACK_HISTORY 400`.
2. **Catalogue bootstrap** : `bootstrap_destination_catalog(db)` la premiere fois (seed les embeddings BGE-M3 sur les ~50 destinations curees de `destination_catalog_data`).
3. **Composition du corpus** : highlights ponderes x2 si rating >= 4 et `would_recommend=True`, lowlights prefixees `avoid:` pour eloigner l'embedding des themes negatifs.
4. **Embedding utilisateur** : `LLMRouter.get().embed(inputs=[corpus])` → vecteur BGE-M3.
5. **Cosine ranking** : produit scalaire / (norm_a * norm_b) contre chaque ligne du catalogue, sauf les IATA deja visites. Top-1.
6. **Confidence floor** : si score < 0.35, log un WARN `low_confidence` mais on ship quand meme.
7. **Narration LLM** : `render("post_trip_suggestion", locale)` + prompt verrouillant la destination + JSON schema strict (`description`, `highlights_match`, `activities[]` avec category UPPERCASE). Aucune liberte de choisir la destination — le LLM ecrit seulement le copy.
8. **Quota** : `require_ai_quota` + `require_premium` (FREE bloque), `increment_ai_generation` apres succes.

### Garanties

- Pas d'hallucination de destination : IATA, ville, pays viennent du `DestinationCatalog` (DB).
- `matchScore` retourne au client pour telemetrie / observabilite.
- Locale lue depuis `Accept-Language`, fallback EN.

## Inspire AI

### Pipeline W1

1. **Resolve origin** : `airportsdata` offline → IATA. Si vide → `error: ORIGIN_UNRESOLVED`.
2. **Amadeus Flight Inspiration** : `FlightInspirationSearchQuery(origin, departureDate, duration, viewBy=DESTINATION)`. Soft-fail (warning `INSPIRE_AMADEUS_DOWN` + LLM-only fallback).
3. **Top-K candidates** (defaut 8) : enrichissement parallele
   - metadata destination via `AviationDataService.get_by_id` (city/country/coords)
   - meteo via `get_weather` (Open-Meteo)
   - cheapest flight via Amadeus `search_flight_offers` (optionnel)
4. **LLM rank + narrate** : 1 seul appel JSON schema (`render("inspire_rank", locale)`). Le LLM choisit `pick_count` destinations parmi le set candidat (impossible d'inventer un IATA) et ecrit `match_reason`, `weather_summary`, `top_activities`.
5. **Cover images** : Unsplash en parallele.
6. **Fallback LLM-only** : si Amadeus KO ou aucun candidat resoluble, `render("destination_quick", locale)` produit une liste avec IATA en clair (resolved offline ensuite). Marque `source: "llm_only"` dans le `complete`.

## Flux

### Wizard plan-trip 6 etapes (Flutter)

1. **Dates** (start/end ou month + duration).
2. **Voyageurs + budget** (`nbTravelers`, `budgetPreset`, `targetBudget`).
3. **Destination** : flow manuel (saisie city/IATA) ou flow IA (Inspire-me → `destinations_only` stream → grille de 3-4 cartes).
4. **Propositions IA** (full SSE) : streaming live, chips d'avancement par phase, accumulation incrementale dans l'etat du BLoC.
5. **Generation SSE** : barre de progression, `_cancelSseStream` sur retry.
6. **Review** : recap final, le `complete` shippe `tripId` → `context.go(TripDetailRoute(tripId).location)`.

### Taxonomie des codes d'erreur

| Code | Source | HTTP | Comportement |
|---|---|---|---|
| `ORIGIN_UNRESOLVED` | inspire + full | 200 + SSE error | client affiche "ville d'origine inconnue", wizard reste sur step 1 |
| `DESTINATION_UNRESOLVED` | full | 200 + SSE error | step 3 reset, propose une nouvelle saisie |
| `INSPIRE_AMADEUS_DOWN` | inspire | 200 + warning | fallback LLM-only (continue) |
| `ACCOMMODATIONS_AMADEUS_DOWN` / `_LIST_FAILED` / `_OFFERS_FAILED` | full | 200 + warning | hotels vides, source=deferred, budget=0 |
| `TRANSPORT_AMADEUS_DOWN` / `TRANSPORT_FLIGHT_FAILED` | full | 200 + warning | budget synthetise un offer haversine si possible |
| `ACTIVITIES_FAILED` / `ACTIVITIES_INVALID_JSON` | full | 200 + warning ou SSE error | retry possible, sinon liste vide |
| `BAGGAGE_FAILED` / `BAGGAGE_INVALID_JSON` | full | 200 + warning | packing-list vide (non bloquant) |
| `AI_QUOTA_EXCEEDED` | route guard | 402 | client affiche le paywall upgrade |
| `UPGRADE_REQUIRED` | route guard (premium) | 402 | bloque post-trip pour FREE |
| `NO_FEEDBACK_HISTORY` | post-trip | 400 | client invite a completer un voyage avant |
| `POST_TRIP_INVALID_JSON` / `POST_TRIP_EMBED_FAILED` | post-trip | 502 | retry possible |
| `BudgetExceededError` (graph) | runtime_budget | 200 + SSE error | run avorte, `done` ferme proprement |

### Observabilite

- Chaque event SSE est aussi logge structurellement (request-id injecte par le middleware).
- `LLMRouter` log latency p95 par model + tokens consommes — base pour les dashboards cost / latency.
- `match_score` du W3 est retourne en clair au client pour pouvoir tracer la confiance des suggestions sur la duree.
- `elapsed_s` final dans le `complete` permet de mesurer la duree totale d'un run cote API.

### Backend lifecycle SSE

```
POST /v1/ai/plan-trip/stream
  -> require_ai_quota (reconcile Stripe, raise 402 si quota epuise)
  -> TripPlannerService.stream_plan (StreamingResponse)
     try:
       if mode == destinations_only:
         InspireOrchestrator.stream  -> yield SSE events
       else:
         FullPlanOrchestrator.stream -> yield events sans complete
         schedule_activities(cmd)    -> feasibility pass deterministe
         PlanDraftService.create_draft_from_command
         yield complete {tripId, status, tripDraft}
         PlanService.increment_ai_generation
     except Exception as exc:
       yield error {message}
     finally:
       yield done {status: complete}     # garantit la cloture
```

### Quota gating FREE vs PREMIUM

| Plan | AI generations / mois | Post-trip W3 | Viewers par trip |
|---|---|---|---|
| FREE | 3 | bloque (402 UPGRADE_REQUIRED) | 2 |
| PREMIUM | illimite (`None`) | active | 10 |
| ADMIN | illimite | active | illimite |

`PlanService.check_ai_generation_quota` reconcilie d'abord le plan via Stripe (pour ne pas bloquer un user fraichement upgrade dont le webhook tarde), puis verifie le compteur `ai_generations_count` vs limite. Auto-reset au passage d'un mois calendaire. `increment_ai_generation` est appele apres succes du run (le quota n'est pas consomme si la generation echoue).

## Ce qu'il manque

- **Traductions FR completes** : les templates FR `include` les EN par defaut (`accommodation_suggest.j2`, `inspire_rank.j2`, `post_trip_suggestion.j2` notamment). Une vraie passe FR releverait la qualite linguistique des copies generees.
- **Streaming token-par-token** : aujourd'hui chaque event SSE correspond a la fin d'un sous-step. Le streaming "live" du LLM (chunks de tokens) n'est pas remonte au client — le router le supporte (`stream_chat_completion`) mais aucun consommateur n'en tire parti.
- **Native tool calling** : `react_executor` (Thought/Action/Final Answer) reste pour les modeles sans function calling natif. Les chemins critiques (W1/W2/W3) sont passes sur du JSON schema strict ; un cleanup viserait a retirer entierement le ReAct manuel.
- **Re-ranking post-cosine W3** : le tri post-trip est purement cosine sur ~50 destinations curees. Un re-ranker (BGE-Reranker ou similaire) ameliorerait la pertinence quand les top-3 sont proches en score.
- **Eval harness** : aucun jeu d'evals automatise pour benchmarker la qualite des plans entre deployments (latence p95 par phase OK, mais pas de score de qualite metier).
- **Catalogue post-trip extensible** : `destination_catalog_data` est code en dur. Un workflow d'edition admin (admin-panel) avec re-embedding a la sauvegarde permettrait d'enrichir la couverture.
- **Cancellation cote serveur** : si le client ferme la connexion mid-stream, l'orchestrateur poursuit ses appels Amadeus/LLM (cout perdu). Un `request.is_disconnected()` poll dans le generator stopperait proprement.
- **Agent service / chat** : `agent_service.dart` chat() reste un `UnimplementedError` (Epic 6). Pas de feature d'edition conversationnelle du trip.
