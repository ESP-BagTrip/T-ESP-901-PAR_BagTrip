# Integrations Externes

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

L'API BagTrip s'integre avec 5 services externes. Chaque integration est encapsulee dans un client dedie sous `api/src/integrations/`. Les integrations sont concues pour une **degradation gracieuse** : si un service externe est indisponible ou non configure, l'application continue de fonctionner (avec des fonctionnalites reduites).

## Amadeus

**Fichiers** : `api/src/integrations/amadeus/`

Amadeus est le fournisseur principal pour les donnees de voyage : recherche de vols, hotels, locations, et booking.

### Authentification (`auth.py`)

- **Type** : OAuth2 Client Credentials (`client_credentials`)
- **URL** : `{AMADEUS_BASE_URL}/v1/security/oauth2/token`
- **Cache** : Token en memoire avec expiration (cache jusqu'a 5s avant expiration)
- **Timeout** : `REQUEST_TIMEOUT_MS` (3000ms par defaut)

```
POST /v1/security/oauth2/token
Content-Type: application/x-www-form-urlencoded
Body: grant_type=client_credentials&client_id=...&client_secret=...
```

Le token est reutilise entre les appels via la variable globale `_token_cache`. En cas d'expiration, un nouveau token est demande automatiquement.

### Client (`client.py`)

Classe `AmadeusClient` qui expose une interface unifiee. Instance globale : `amadeus_client`.

### Modules

#### Locations (`locations.py`)
- `search_locations_by_keyword(query)` — Recherche par mot-cle (GET `/v1/reference-data/locations`)
- `search_location_by_id(query)` — Recherche par ID (GET `/v1/reference-data/locations/{id}`)
- `search_location_nearest(query)` — Airports proches (GET `/v1/reference-data/locations/airports`)

Retourne des objets `LocationResult` avec `iataCode`, `address` (cityName, countryName), `geoCode` (lat, lon).

#### Flights (`flights.py`)
- `search_flight_offers(query)` — Offres de vols (GET `/v2/shopping/flight-offers`)
- `search_flight_destinations(query)` — Destinations inspirantes (GET `/v1/shopping/flight-destinations`)
- `search_flight_cheapest_dates(query)` — Dates les moins cheres (GET `/v1/shopping/flight-dates`)
- `confirm_flight_price(offer)` — Confirmation de prix (POST `/v1/shopping/flight-offers/pricing`)
- `create_flight_order(offer, travelers)` — Creation de commande (POST `/v1/booking/flight-orders`)

#### Hotels (`hotels.py`)
- `search_hotel_list(query)` — Liste d'hotels par ville (GET `/v1/reference-data/locations/hotels/by-city`)
- `search_hotel_offers(query)` — Offres d'hotel avec prix (GET `/v3/shopping/hotel-offers`)

### Types (`types.py`)

Modeles Pydantic pour les requetes et reponses Amadeus :
- `FlightOfferSearchQuery`, `FlightInspirationSearchQuery`, `FlightCheapestDateSearchQuery`
- `HotelListSearchQuery`, `HotelOffersSearchQuery`
- `LocationKeywordSearchQuery`, `LocationIdSearchQuery`, `LocationNearestSearchQuery`
- `FlightOffer`, `FlightOrderTraveler`, `FlightPriceResponse`

### API Logging (`models/amadeus_api_log.py`)

Le modele `AmadeusApiLog` existe pour tracer les appels Amadeus (endpoint, status, duree, etc.) mais le logging effectif n'est pas implemente dans le client actuel.

### Concurrence

Un `asyncio.Semaphore(3)` dans `tools.py` limite les appels Amadeus concurrents depuis les agents IA pour eviter le rate-limiting.

### Environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `AMADEUS_CLIENT_ID` | (requis) | Client ID Amadeus |
| `AMADEUS_CLIENT_SECRET` | (requis) | Client Secret Amadeus |
| `AMADEUS_BASE_URL` | `https://test.api.amadeus.com` | URL de base (test ou production) |

## AirLabs

**Fichier** : `api/src/integrations/airlabs/client.py`

Service de suivi de vol en temps reel.

### Client (`AirLabsClient`)

- **API** : REST (GET `https://airlabs.co/api/v9/flight`)
- **Methode** : `lookup_flight(flight_iata)` — recherche par code IATA vol (ex: `AF1234`)
- **Cache** : In-memory dict, TTL 5 minutes
- **Timeout** : 10 secondes (httpx)
- **Instance globale** : `airlabs_client`

### Donnees retournees

```json
{
  "flight_iata": "AF1234",
  "airline_iata": "AF",
  "airline_name": "Air France",
  "status": "en-route",
  "dep_iata": "CDG",
  "dep_terminal": "2E",
  "dep_gate": "K42",
  "dep_time": "2026-03-26T08:30:00+01:00",
  "dep_actual": "2026-03-26T08:35:00+01:00",
  "dep_delayed": 5,
  "arr_iata": "JFK",
  "arr_terminal": "1",
  "arr_time": "2026-03-26T11:00:00-04:00"
}
```

### Degradation

Si `AIRLABS_API_KEY` n'est pas configure, `lookup_flight()` retourne `None` et l'endpoint `/v1/travel/flights/{flightNumber}/info` retourne 503.

### Environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `AIRLABS_API_KEY` | `None` (optionnel) | Cle API AirLabs |

## Unsplash

**Fichier** : `api/src/integrations/unsplash/client.py`

Fournit des images de couverture automatiques pour les trips.

### Client (`UnsplashClient`)

- **API** : REST (GET `https://api.unsplash.com/search/photos`)
- **Methode** : `fetch_cover_image(destination_name)` — recherche une photo paysage
- **Auth** : Header `Authorization: Client-ID {UNSPLASH_ACCESS_KEY}`
- **Parametres** : `query=<destination>`, `orientation=landscape`, `per_page=1`
- **Cache** : In-memory dict, TTL 1 heure
- **Timeout** : 10 secondes (httpx async)
- **Instance globale** : `unsplash_client`

### Fallback continent-based

Methode `get_fallback_url(destination_name)` :
1. Detecte le continent a partir de mots-cles dans le nom de destination
2. Retourne une URL Unsplash statique correspondante

Continents detectes : Europe, Asia, North America, South America, Africa, Oceania.

Exemple : "Paris" → Europe → `https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=1080`

### Utilisation

Appele dans :
- `api/src/api/trips/routes.py` — creation de trip (si pas de `coverImageUrl`)
- `api/src/api/ai/plan_trip_routes.py` — accept plan (pour le trip IA)

### Environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `UNSPLASH_ACCESS_KEY` | `None` (optionnel) | Access Key Unsplash |

## Firebase (FCM)

**Fichier** : `api/src/integrations/firebase/__init__.py`

Firebase Admin SDK pour les push notifications (Firebase Cloud Messaging).

### Initialisation

- Charge le service account depuis `FIREBASE_SERVICE_ACCOUNT_PATH`
- Initialise l'app Firebase via `firebase_admin.initialize_app(cred)`
- **Degradation gracieuse** : si le path n'est pas configure ou l'init echoue, `get_firebase_app()` retourne `None` et les notifications push sont desactivees (mais les notifications sont quand meme creees en DB)

### Envoi (`services/notification_service.py`)

Methode `_send_fcm()` :
- **1 token** : `messaging.Message` + `messaging.send()`
- **Plusieurs tokens** : `messaging.MulticastMessage` + `messaging.send_each_for_multicast()`
- **Nettoyage** : si un token est invalide (`UnregisteredError`), il est supprime de la DB automatiquement

### Environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `FIREBASE_SERVICE_ACCOUNT_PATH` | `None` (optionnel) | Chemin vers le fichier JSON du service account |
| `GOOGLE_FIREBASE_PROJECT_ID` | `bagtrip-7d2d8` | Project ID pour la verification des tokens Google |

## Stripe

**Fichier** : `api/src/integrations/stripe/client.py`

Stripe est utilise pour deux fonctionnalites :
1. **Paiement des reservations de vol** — PaymentIntent avec capture manuelle
2. **Abonnement Premium** — Checkout Session + Billing Portal

### Client (`StripeClient`)

Wrapper statique autour de la lib `stripe` Python :

| Methode | Description |
|---------|-------------|
| `create_customer(email, name)` | Cree un client Stripe (a l'inscription) |
| `create_payment_intent(amount, currency, metadata, capture_method, customer, description)` | Cree un PaymentIntent (capture manuelle par defaut) |
| `capture_payment_intent(payment_intent_id)` | Capture un PI autorise |
| `cancel_payment_intent(payment_intent_id)` | Annule un PI |
| `retrieve_payment_intent(payment_intent_id)` | Recupere un PI |

### Flux de paiement (Booking)

```
1. POST /v1/trips/{id}/booking-intents     → BookingIntent (status: INIT)
2. POST /v1/booking-intents/{id}/payment/authorize  → Stripe PaymentIntent (capture: manual)
   → Webhook payment_intent.amount_capturable_updated → status: AUTHORIZED
3. POST /v1/booking-intents/{id}/book       → Amadeus Flight Order
   → status: BOOKED
4. POST /v1/booking-intents/{id}/payment/capture     → Stripe capture
   → status: CAPTURED
```

### Flux d'abonnement (Premium)

```
1. POST /v1/subscription/checkout    → Stripe Checkout Session URL
2. Utilisateur complete le paiement sur Stripe
3. Webhook customer.subscription.created → user.plan = "PREMIUM"
4. POST /v1/subscription/portal      → Stripe Billing Portal URL (gestion)
```

### Services Stripe

| Service | Fichier | Responsabilite |
|---------|---------|---------------|
| `StripePaymentsService` | `services/stripe_payments_service.py` | Authorize / Capture / Cancel PaymentIntents |
| `StripeWebhooksService` | `services/stripe_webhooks_service.py` | Traitement des evenements webhook |
| `StripeProductsService` | `services/stripe_products_service.py` | Initialisation des produits au demarrage |
| `SubscriptionService` | `services/subscription_service.py` | Checkout + Portal + Status |

### Webhooks traites (`stripe_webhooks_service.py`)

| Evenement | Action |
|-----------|--------|
| `payment_intent.amount_capturable_updated` | BookingIntent → AUTHORIZED |
| `payment_intent.canceled` | BookingIntent → CANCELLED |
| `payment_intent.payment_failed` | BookingIntent → FAILED |
| `customer.subscription.created` | User plan → PREMIUM |
| `customer.subscription.updated` | Mise a jour expiration, downgrade si cancelled/unpaid |
| `customer.subscription.deleted` | User plan → FREE |
| `invoice.payment_succeeded` | Mise a jour plan_expires_at |

Idempotence : chaque evenement Stripe est persiste dans `StripeEvent` et deduplique par `stripe_event_id`.

### Environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `STRIPE_SECRET_KEY` | `None` (optionnel) | Cle secrete Stripe |
| `STRIPE_WEBHOOK_SECRET` | `None` (optionnel) | Secret pour verifier les webhooks |
| `STRIPE_SUCCESS_URL` | `bagtrip://subscription/success?session-id={CHECKOUT_SESSION_ID}` | URL de retour apres paiement reussi |
| `STRIPE_CANCEL_URL` | `bagtrip://subscription/cancel` | URL de retour apres annulation |

## Open-Meteo

**Usage** : `api/src/agent/tools.py` (fonction `get_weather`)

Service meteo gratuit, sans cle API. Utilise pour obtenir des previsions reelles dans le pipeline IA et l'endpoint weather des trips.

- **API** : GET `https://api.open-meteo.com/v1/forecast`
- **Parametres** : latitude, longitude, start_date, end_date, daily metrics
- **Metrics** : `temperature_2m_max`, `temperature_2m_min`, `precipitation_probability_max`
- **Timeout** : 10 secondes
- **Fallback** : Estimation par zone climatique (latitude) + saison si l'API echoue

### Environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `OPEN_METEO_BASE_URL` | `https://api.open-meteo.com` | URL de base Open-Meteo |

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Amadeus API logging non implemente | Le modele `AmadeusApiLog` existe mais aucun appel Amadeus ne cree de log. Fichier : `api/src/models/amadeus_api_log.py` | P2 |
| Pas de circuit breaker | Aucun circuit breaker sur les appels externes (Amadeus, AirLabs, Unsplash). Un service down entraine des timeouts repetes. Fichiers : tous les clients | P1 |
| Stripe en mode test uniquement | L'URL de base Amadeus est `test.api.amadeus.com` par defaut. L'endpoint `confirm-test` permet de payer avec la carte 4242. Fichier : `api/src/api/payments/routes.py` | P1 |
| Pas de monitoring des webhooks | Les erreurs de traitement des webhooks Stripe sont persistees dans `processing_error` mais pas d'alerte. Fichier : `api/src/services/stripe_webhooks_service.py` | P2 |
| Cache Unsplash non distribue | Le cache Unsplash est in-memory (dict). En multi-instance, chaque worker refait les requetes. Fichier : `api/src/integrations/unsplash/client.py` | P2 |
| AirLabs cache synchrone | Le client AirLabs utilise `httpx` synchrone (pas async). Fichier : `api/src/integrations/airlabs/client.py` ligne 37 | P2 |
| Pas de gestion du rate-limit Amadeus 429 | Si Amadeus retourne 429, le client ne fait pas de retry avec backoff. Le semaphore limite a 3 appels concurrents mais pas de retry. Fichier : `api/src/agent/tools.py` | P1 |
