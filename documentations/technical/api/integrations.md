# Integrations externes

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

L'API BagTrip dialogue avec sept fournisseurs tiers. Chaque integration est isolee derriere un wrapper sous `api/src/integrations/<provider>/` et exposee aux routes via un service facade sous `api/src/services/<provider>_service.py`. Trois principes non-negociables :

- **Aucune route n'appelle un client tiers directement** — la couche service est le seul point d'entree.
- **Tous les clients HTTP sortants partagent le singleton `httpx.AsyncClient`** initialise dans le lifespan FastAPI (`src/integrations/http_client.py`). Pas de `httpx.AsyncClient()` cree par requete.
- **Degradation gracieuse systematique** : une integration non configuree (cle absente) ou en panne ne casse jamais le boot ; les fonctionnalites associees deviennent indisponibles avec un fallback explicite (None, valeur par defaut, 503).

| Integration | Usage | Cache | Fallback |
|-------------|-------|-------|----------|
| Amadeus | Vols (search/price/order), hotels, POI, activites bookables, sentiments, destinations inspirantes | Token OAuth2 en memoire (expires_in - 5s) | `AppError(UPSTREAM_*)` + retry decorator |
| AirLabs | Statut vol temps reel (terminal, gate, retard) par code IATA | Dict in-memory, TTL 5 min | `None` si cle absente ou echec ; route renvoie 503 |
| Unsplash | Image de couverture des trips (paysage 1080px) | Dict in-memory, TTL 1h | URL statique continent-based (7 buckets) |
| Firebase FCM | Push notifications mobile | n/a | Notification persistee en DB meme sans FCM ; SDK desactive si service account absent |
| Stripe | Paiement vols (PaymentIntent capture manuelle), abonnement Premium, customers, billing portal | Idempotency keys cote Stripe (24h) | Boot warn si cle absente ; webhooks rejetes en prod sans secret |
| LLM (OVHcloud) | Generation de voyage SSE, ReAct executor, embeddings | n/a (chain de modeles + retry) | Fallback chain `LLM_MODEL_PRIMARY` -> `LLM_MODEL_FALLBACKS` |
| Open-Meteo | Meteo destination (forecast + climate) et geocoding multilingue | `idempotency_cache` agent (in-memory) | Estimation par zone climatique ; resolveur IATA cascade plus loin |

Toutes les integrations sont egalement listees dans `src/integrations/__init__.py` ; l'aviation data (referentiel aeroports IATA offline via `airportsdata`) y figure mais n'est pas un service externe — voir `architecture.md`.

## Amadeus

**Fichiers** : `src/integrations/amadeus/{auth,client,flights,hotels,pois,activities,sentiments,types,errors,retry}.py`
**Service facade** : `src/services/amadeus_service.py` (`AmadeusService`)

Amadeus Self-Service est le fournisseur principal pour les donnees de voyage : recherche, pricing, booking.

### Authentification

OAuth2 Client Credentials. Le token est mis en cache process-wide dans `_token_cache` (`auth.py`) avec une marge de 5 s avant expiration. Tout appel passe par `await fetch_token()` qui re-issue automatiquement le token a echeance.

```
POST {AMADEUS_BASE_URL}/v1/security/oauth2/token
Content-Type: application/x-www-form-urlencoded
grant_type=client_credentials&client_id=...&client_secret=...
```

Decorateur `@amadeus_retry` (`retry.py`) sur chaque appel : backoff exponentiel sur 429 / 5xx / `httpx.NetworkError`. Mapping des codes upstream vers `AppError("UPSTREAM_*", 502)` dans `errors.py`.

### Endpoints utilises

| Methode service | Endpoint Amadeus | Timeout |
|-----------------|------------------|---------|
| `search_flight_offers` | `GET /v2/shopping/flight-offers` | 20 s |
| `search_flight_destinations` | `GET /v1/shopping/flight-destinations` | 15 s |
| `search_flight_cheapest_dates` | `GET /v1/shopping/flight-dates` | 15 s |
| `confirm_flight_price` | `POST /v1/shopping/flight-offers/pricing` | 20 s |
| `create_flight_order` | `POST /v1/booking/flight-orders` | 30 s |
| `search_hotel_list` | `GET /v1/reference-data/locations/hotels/by-city` | (default 30 s) |
| `search_hotel_offers` | `GET /v3/shopping/hotel-offers` | (default 30 s) |
| `search_pois` | `GET /v1/reference-data/locations/pois` | (default) |
| `search_activities` | `GET /v1/shopping/activities` | (default) |
| `search_hotel_sentiments` | `GET /v2/e-reputation/hotel-sentiments` | (default) |

### Cache et TTL

Pas de cache HTTP cote BagTrip. Le seul element memoise est le token OAuth2 (~30 min). Les recherches sont logiquement deduplicables par hash de query si un caller veut wrap dans Redis (cf. note `AmadeusService.search_pois` qui delegue le cache aux callers).

### Variables d'environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `AMADEUS_CLIENT_ID` | (requis) | Client ID Amadeus |
| `AMADEUS_CLIENT_SECRET` | (requis) | Client Secret Amadeus |
| `AMADEUS_BASE_URL` | `https://test.api.amadeus.com` | Base URL (test ou production) |
| `REQUEST_TIMEOUT_MS` | `3000` | Timeout du token endpoint en ms |

## AirLabs

**Fichier** : `src/integrations/airlabs/client.py`
**Service facade** : `src/services/airlabs_service.py` (`AirLabsService.lookup_flight`)

Lookup vol temps reel par code IATA (ex `AF1234`). Utilise par l'endpoint flight info quand un trip a un manual flight enregistre.

### Endpoint

```
GET https://airlabs.co/api/v9/flight?flight_iata={code}&api_key={AIRLABS_API_KEY}
```

Le client renvoie la premiere entree de la liste `response` (ou l'objet si dict). Champs principaux exposes : `flight_iata`, `airline_iata`, `airline_name`, `status`, `dep_iata`, `dep_terminal`, `dep_gate`, `dep_time`, `dep_actual`, `dep_delayed`, `arr_iata`, `arr_terminal`, `arr_time`.

### Cache et fallback

- Cache dict in-memory `_CACHE`, TTL 5 minutes par code IATA.
- Si `AIRLABS_API_KEY` absente : retourne `None` immediatement.
- Sur exception ou payload vide : warn log + `None`.

**Limitation connue** : le client AirLabs utilise `httpx.get(...)` synchrone (10 s timeout) au lieu du singleton `AsyncClient` — point de dette technique, voir "Ce qu'il manque".

### Variables d'environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `AIRLABS_API_KEY` | `None` | Cle API AirLabs (optionnel) |

## Unsplash

**Fichier** : `src/integrations/unsplash/client.py`
**Usage** : `api/trips/routes.py` (creation trip sans `coverImageUrl`), `api/ai/plan_trip_routes.py` (accept plan).

### Endpoint

```
GET https://api.unsplash.com/search/photos?query={destination}&orientation=landscape&per_page=1
Authorization: Client-ID {UNSPLASH_ACCESS_KEY}
```

Le client passe par `get_http_client()` (singleton httpx) avec timeout 10 s. L'URL retournee est `results[0].urls.regular` (1080px).

### Cache et fallback continent-based

- Cache dict `_CACHE`, TTL 1h, cle = `destination.lower().strip()`.
- Sans cle API ou sur echec : `fetch_cover_image()` renvoie `None`.
- Le caller appelle ensuite `UnsplashClient.get_fallback_url(destination_name)` qui detecte le continent par mots-cles (`_CONTINENT_KEYWORDS` couvre Europe, Asia, North America, South America, Africa, Oceania) et renvoie une URL Unsplash statique royalty-free pre-selectionnee. Defaut : photo monde.

### Variables d'environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `UNSPLASH_ACCESS_KEY` | `None` | Access Key Unsplash (optionnel) |

## Firebase (FCM)

**Fichier** : `src/integrations/firebase/__init__.py`
**Service consommateur** : `src/services/notification_service.py` (`NotificationService._send_fcm`)

### Initialisation

`_init_firebase()` est appele a l'import du module. Si `FIREBASE_SERVICE_ACCOUNT_PATH` est absent ou si l'init Firebase echoue, `get_firebase_app()` renvoie `None` et les notifications push sont desactivees silencieusement (les Notification SQL sont toujours creees pour l'in-app feed).

### Envoi

`NotificationService._send_fcm(db, tokens, title, body, data)` :
- 1 token : `messaging.Message` + `messaging.send()`.
- N tokens : `messaging.MulticastMessage` + `messaging.send_each_for_multicast()`.
- Sur `messaging.UnregisteredError` : le device token est supprime de la table `device_tokens` automatiquement (purge des inscriptions perimees).

Les payloads localises sont produits par `render_notification(...)` (`notification_messages.py`) — backend-owned, le client ne fait que rendre.

### Variables d'environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `FIREBASE_SERVICE_ACCOUNT_PATH` | `None` | Chemin local vers le JSON service account |
| `GOOGLE_FIREBASE_PROJECT_ID` | `bagtrip-7d2d8` | Project ID pour la verif des id tokens Google Sign-In |

## Stripe

**Fichier** : `src/integrations/stripe/client.py`
**Service facade non-payment** : `src/services/stripe_gateway_service.py` (`StripeGatewayService.delete_customer`)
**Services metier** : `stripe_payments_service.py`, `stripe_products_service.py`, `stripe_webhooks/service.py`, `subscription_service.py`.

Stripe couvre deux flux distincts :
1. **Paiement vols** — PaymentIntent en `capture_method=manual`, autorise puis capture apres confirmation Amadeus.
2. **Abonnement Premium** — Subscription en `default_incomplete` consommee par le `PaymentSheet` Flutter natif (pas de Checkout URL).

### Lazy-init non-mutante (sous reserve)

Au chargement de `src/integrations/stripe/client.py`, **si** `STRIPE_SECRET_KEY` est definie, le module pose `stripe.api_key` et `stripe.api_version = "2024-10-28.acacia"`. Si la cle est absente le SDK reste inerte (les routes payment renvoient 503 a l'usage). Le pinning explicite de la version API evite qu'un rolling update Stripe change silencieusement les payloads webhook.

### Operations exposees par `StripeClient`

| Domaine | Methode | Stripe API |
|---------|---------|------------|
| Customer | `create_customer` / `retrieve_customer` / `delete_customer` | `Customer.create/retrieve/delete` |
| PaymentIntent | `create_payment_intent(capture_method="manual")`, `capture_payment_intent`, `cancel_payment_intent`, `retrieve_payment_intent` | `PaymentIntent.*` |
| Charge / Refund | `retrieve_charge`, `create_refund` | `Charge.retrieve`, `Refund.create` |
| Subscription | `create_subscription` (mode `default_incomplete`), `retrieve/list/cancel/update_subscription` | `Subscription.*` |
| Invoice | `list_invoices` | `Invoice.list` |
| PaymentSheet | `retrieve_payment_method`, `attach_payment_method`, `create_setup_intent`, `create_ephemeral_key` | mobile-native flows |
| Billing Portal | `create_billing_portal_session` | `billing_portal.Session.create` |

Chaque mutation accepte un `idempotency_key` optionnel — Stripe dedupe 24 h, ce qui rend les retry reseau coherents avec une operation metier (ex `f"bi-{booking_intent_id}-authorize-v1"`).

### Products bootstrap

`StripeProductsService.initialize_products()` est appele dans le lifespan : il cherche par metadata `type=flight` / `type=premium_subscription` et cree le produit + prix recurrent (999 cts / EUR / month) s'ils n'existent pas. Les IDs sont caches dans `STRIPE_PRODUCT_IDS` pour reutilisation par `SubscriptionService`. Sans `STRIPE_SECRET_KEY` le bootstrap est skip avec warn.

### Webhooks

Endpoint `/v1/stripe/webhooks` (`api/stripe/webhooks/routes.py`). Verification signature via `stripe.Webhook.construct_event(body, sig, STRIPE_WEBHOOK_SECRET)`. En prod, l'absence du secret leve une erreur de boot via field validator (`env.py`). Hors prod, une escape hatch permet de parser sans signature avec un warn.

Evenements traites (`stripe_webhooks/handlers/`) :

| Evenement | Action |
|-----------|--------|
| `payment_intent.amount_capturable_updated` | BookingIntent -> AUTHORIZED |
| `payment_intent.canceled` | BookingIntent -> CANCELLED |
| `payment_intent.payment_failed` | BookingIntent -> FAILED |
| `customer.subscription.created` | User plan -> PREMIUM |
| `customer.subscription.updated` | Maj expiration ; downgrade si `canceled` / `unpaid` |
| `customer.subscription.deleted` | User plan -> FREE |
| `invoice.payment_succeeded` | Maj `plan_expires_at` |

Idempotence : chaque event est persiste dans `StripeEvent` deduplique par `stripe_event_id`.

### Variables d'environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `STRIPE_SECRET_KEY` | `None` | Cle secrete (sk_test_ ou sk_live_) |
| `STRIPE_WEBHOOK_SECRET` | `None` ; **requis en prod** (field validator) | Secret signature webhook |
| `STRIPE_SUCCESS_URL` | `bagtrip://subscription/success?session-id={CHECKOUT_SESSION_ID}` | Retour mobile post-checkout legacy |
| `STRIPE_CANCEL_URL` | `bagtrip://subscription/cancel` | Retour mobile annulation |

## LLM (OVHcloud — OpenAI-compatible)

**Fichier router** : `src/services/llm_router.py` (`LLMRouter` singleton)
**Facade legacy** : `src/services/llm_service.py` (`LLMService` — `call_llm`, `acall_llm`, `acall_llm_messages`)

Le router est l'unique point d'acces au provider LLM pour le process API. Il cible un endpoint OpenAI-compatible — par defaut `https://oai.endpoints.kepler.ai.cloud.ovh.net/v1` (OVHcloud AI Endpoints). Le modele principal historique etait `gpt-oss-120b` ; la chain par defaut actuelle est `Mistral-Small-3.2-24B-Instruct-2506` -> `Qwen3-32B` -> `Meta-Llama-3_3-70B-Instruct`.

### Responsabilites

- **Fallback chain** : `LLM_MODEL_PRIMARY` puis chaque entree de `LLM_MODEL_FALLBACKS`. Un modele qui rejette une feature (tool calls non supportes, response_format refuse, 4xx schema) est skip vers le suivant (`_PermanentLLMError`). Tenacity gere uniquement les transients (`_TransientLLMError`).
- **Retry transient** : 408 / 429 / 5xx / `httpx.TimeoutException` / `httpx.NetworkError` avec backoff exponentiel jitter (`stop_after_attempt(LLM_RETRY_MAX_ATTEMPTS)`, `wait_exponential_jitter(base, max)`).
- **Concurrence** : `asyncio.Semaphore(LLM_MAX_CONCURRENCY)` partage par process pour rester sous la limite RPM OVH.
- **Client HTTP** : `httpx.AsyncClient` dedie au router (Authorization bearer + base_url + timeout `(connect=10, read=LLM_CALL_TIMEOUT_SECONDS, write=10, pool=5)`). Pas le singleton commun car ce client porte les headers Auth fixes et son propre timeout long. `aclose()` enregistre via `atexit`.
- **Tracing** : chaque call logge `model`, `attempt`, `latency_s`, `prompt_tokens`, `completion_tokens`, `finish_reason`, `tool_calls`. Le payload de retour est augmente d'un champ `_router = { model_used, attempts[] }` pour reconstituer la trace post-mortem.

### Surface publique

- `chat_completion(messages, tools?, tool_choice?, response_format?, temperature, max_tokens, models?)` -> dict OpenAI-compatible.
- `stream_chat_completion(...)` -> async iterator de chunks JSON (`data: ... [DONE]`). **Ne fallback PAS** une fois le premier byte forwarde au client SSE.
- `embed(inputs, model?)` -> `list[list[float]]` via `/embeddings`.

`LLMService` enveloppe `chat_completion` pour les call sites legacy qui attendent un dict JSON parse (avec `_strip_markdown_fences` defensif) ou un raw string (`acall_llm_messages`).

### Variables d'environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `LLM_API_BASE` | `https://oai.endpoints.kepler.ai.cloud.ovh.net/v1` | Endpoint OpenAI-compatible |
| `LLM_API_KEY` | (requis) | Bearer token OVH |
| `LLM_MODEL_PRIMARY` | `Mistral-Small-3.2-24B-Instruct-2506` | Modele principal |
| `LLM_MODEL_FALLBACKS` | `Qwen3-32B,Meta-Llama-3_3-70B-Instruct` | CSV fallback chain |
| `LLM_EMBEDDING_MODEL` | `bge-m3` | Modele d'embeddings |
| `LLM_MAX_CONCURRENCY` | `24` | Semaphore cap |
| `LLM_RETRY_MAX_ATTEMPTS` | `3` | Tentatives par modele |
| `LLM_RETRY_BACKOFF_BASE_S` / `_MAX_S` | `0.5` / `8.0` | Backoff jitter |
| `LLM_CALL_TIMEOUT_SECONDS` | `120` | Timeout read par appel (SMP-324) |

## Open-Meteo

Deux endpoints sont consommes, tous via `get_http_client()` (singleton) :

### Forecast (`agent/tools/weather.py`)

```
GET {OPEN_METEO_BASE_URL}/v1/forecast?latitude=..&longitude=..&start_date=..&end_date=..&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max
```

Utilise par le tool `get_weather` du graph LangGraph et par l'endpoint weather des trips. Gratuit, sans cle API. Mis en cache via `idempotency_cache.get/set("get_weather", params)` (Redis-backed ou in-memory si Redis absent). Sur echec : fallback estimation par zone climatique (latitude) + saison.

### Geocoding (`src/integrations/open_meteo/geocoding.py`)

```
GET https://geocoding-api.open-meteo.com/v1/search?name={place}&language={fr|en}&count=5&format=json
```

`search_places(name, language, count)` -> `list[GeocodedPlace]` (name, lat, lon, country, country_code, admin1, population). Resolveur multilingue qui plug dans `airportsdata.search_nearest()` pour la resolution IATA quand l'utilisateur saisit "Singapour", "Tokyo", "Marrakech" en FR. Timeout 5 s, fallback `[]` sur echec — le resolveur IATA a d'autres etages de fallback.

### Variables d'environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `OPEN_METEO_BASE_URL` | `https://api.open-meteo.com` | Base URL forecast |
| `OPEN_METEO_GEOCODING_BASE_URL` | `https://geocoding-api.open-meteo.com` | Base URL geocoding |

## Patterns communs

### Singleton `httpx.AsyncClient` (`src/integrations/http_client.py`)

Un seul pool process-wide, owne par le lifespan FastAPI. Limites : 100 connexions totales, 20 keepalive, timeout default 30 s. Chaque caller passe son `timeout=` per request — Amadeus flight offers tape 20 s, Amadeus order 30 s, Unsplash 10 s, Open-Meteo 5 s. `init_http_client()` est idempotent (safe sur warm reload) ; `close_http_client()` est appele en teardown.

Exceptions historiques :
- **LLMRouter** maintient son propre `httpx.AsyncClient` car il porte un `Authorization` bearer et un timeout long fixe.
- **AirLabs** utilise `httpx.get` synchrone — dette technique a migrer.

### Service facade obligatoire

Pattern impose par CLAUDE.md : `Route -> Service (metier) -> Integration wrapper`. Toute nouvelle integration passe par `src/services/<name>_service.py` (facade thin avec methodes statiques delegant au client). Les routes ne peuvent jamais importer `amadeus_client`, `airlabs_client`, `StripeClient`, `unsplash_client` directement.

### Cache Redis pour les integrations lentes

Quand un appel externe est cher ou rate-limite (Amadeus hotels, Open-Meteo forecast, agent tool results), le caller wrap dans `idempotency_cache` (`src/utils/idempotency.py`) qui pointe sur Redis quand `REDIS_URL` est defini et fallback in-memory sinon. Le client Redis lui-meme est centralise dans `src/integrations/redis_client.py` (singleton avec ping memoise — None si indispo).

### Lazy-init des SDK

Pour Stripe le module pose `stripe.api_key` au load mais le SDK ne pre-cree pas de connexion ; pour Firebase l'`initialize_app(cred)` est ramene a un no-op si le service account est absent. Aucune mutation globale ne casse le boot.

### Idempotency cote provider

- Stripe : `idempotency_key` sur toute mutation (create/capture/cancel PaymentIntent, attach PaymentMethod, refund, subscription).
- Webhooks Stripe : `StripeEvent` deduplique par `stripe_event_id`.
- Amadeus : pas d'idempotency native — les retries restent au niveau HTTP (`@amadeus_retry`).

### Tracing et observabilite

Chaque integration logge structuredly avec contexte (`model`, `url`, `params`, `status`, `latency_s`). Le middleware `request_id` injecte un `X-Request-ID` propage dans tous les logs sortants via `contextvars`. Les LLMRouter responses portent un champ `_router` synthetique pour debug.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| AirLabs sync httpx | `httpx.get(...)` synchrone dans `airlabs/client.py` bloque l'event loop FastAPI ; migrer sur `get_http_client()` async | P1 |
| Pas de circuit breaker | Aucun breaker sur Amadeus / AirLabs / Unsplash / LLM. Un provider down entraine timeouts repetes sur chaque requete tant qu'il ne repond pas | P1 |
| Amadeus en mode test par defaut | `AMADEUS_BASE_URL` pointe sur `test.api.amadeus.com` (cartes Stripe test 4242). Switch production = changement infra | P1 |
| Cache Unsplash et AirLabs non distribues | Dict in-memory par worker ; en multi-instance chaque worker refait les requetes. Migrer sur Redis avec le pattern `idempotency_cache` | P2 |
| Pas de logs persistes Amadeus | Modele `AmadeusApiLog` cree mais aucun appel n'ecrit dedans ; pas de tracabilite cross-restart des quotas consommes | P2 |
| Monitoring webhooks Stripe | Les erreurs de handler sont persistees dans `StripeEvent.processing_error` mais aucune alerte n'est emise — risque de drift silencieux sur les downgrades Premium | P2 |
| LLM router : pas de cache resultats | Pas d'option de cache LLM (semantic ou exact-match) ; les nodes IA paient le full cost a chaque relance | P2 |
| Pas de health probe externe | Aucun endpoint `/health/integrations` qui ping chaque provider. Diagnostic se fait en reactif sur erreur upstream | P3 |
