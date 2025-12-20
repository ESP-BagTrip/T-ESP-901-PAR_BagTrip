## 1) Architecture DB finale (POC)

### Principes POC

* **Normaliser** : users, trips, travelers, “objets métiers” (search/offer/order/booking).
* **Tout le reste** (payload Amadeus + payload Stripe + erreurs) en **JSONB**.
* **Stripe** : ton pattern 2 impose une table centrale `booking_intents` + liens vers `flight_orders` / `hotel_bookings`.

### Tables (liste finale)

#### Core

* `users`
* `trips`
* `trip_travelers`

#### Flights

* `flight_searches`
* `flight_offers`
* `flight_orders`

#### Hotels

* `hotel_searches`
* `hotel_offers`
* `hotel_bookings`

#### Paiement & orchestration (Stripe + booking)

* `booking_intents` ✅ (clé de voûte)
* `stripe_events` ✅ (webhooks, optionnel mais recommandé)
* `amadeus_api_logs` ✅ (debug, recommandé)

---

### Schéma DBML (collable dans DrawDB) – version finale

```dbml
Table users {
  id uuid [pk]
  email varchar [unique, not null]
  password_hash varchar
  full_name varchar
  phone varchar
  created_at datetime
  updated_at datetime
}

Table trips {
  id uuid [pk]
  user_id uuid [not null, ref: > users.id]
  title varchar
  origin_iata char(3)
  destination_iata char(3)
  start_date date
  end_date date
  status varchar // draft | planned | booked | cancelled
  created_at datetime
  updated_at datetime

  Indexes { user_id }
}

Table trip_travelers {
  id uuid [pk]
  trip_id uuid [not null, ref: > trips.id]
  amadeus_traveler_ref varchar
  traveler_type varchar [not null] // ADULT | CHILD | etc.
  first_name varchar [not null]
  last_name varchar [not null]
  date_of_birth date
  gender varchar
  documents json
  contacts json
  raw json
  created_at datetime
  updated_at datetime

  Indexes { trip_id }
}

Table flight_searches {
  id uuid [pk]
  trip_id uuid [not null, ref: > trips.id]
  origin_iata char(3) [not null]
  destination_iata char(3) [not null]
  departure_date date [not null]
  return_date date
  adults int [not null]
  children int
  infants int
  travel_class varchar
  non_stop boolean
  currency char(3)
  amadeus_request json [not null]
  amadeus_response json
  amadeus_response_received_at datetime
  created_at datetime

  Indexes { trip_id }
}

Table flight_offers {
  id uuid [pk]
  flight_search_id uuid [not null, ref: > flight_searches.id]
  trip_id uuid [not null, ref: > trips.id]
  amadeus_offer_id varchar
  source varchar
  validating_airline_codes varchar
  last_ticketing_datetime datetime
  currency char(3)
  grand_total decimal
  base_total decimal
  offer_json json [not null]
  priced_offer_json json
  created_at datetime

  Indexes { trip_id, flight_search_id }
}

Table flight_orders {
  id uuid [pk]
  trip_id uuid [not null, ref: > trips.id]
  flight_offer_id uuid [not null, ref: > flight_offers.id]
  booking_intent_id uuid [unique, ref: > booking_intents.id] // 1 intent -> 0/1 flight order

  amadeus_flight_order_id varchar [unique]
  status varchar
  booking_reference varchar
  amadeus_create_order_request json [not null]
  amadeus_create_order_response json
  created_at datetime
  updated_at datetime

  Indexes { trip_id }
}

Table hotel_searches {
  id uuid [pk]
  trip_id uuid [not null, ref: > trips.id]
  city_code char(3)
  latitude decimal
  longitude decimal
  check_in date [not null]
  check_out date [not null]
  adults int [not null]
  room_qty int [not null]
  currency char(3)
  amadeus_request json [not null]
  amadeus_response json
  amadeus_response_received_at datetime
  created_at datetime

  Indexes { trip_id }
}

Table hotel_offers {
  id uuid [pk]
  hotel_search_id uuid [not null, ref: > hotel_searches.id]
  trip_id uuid [not null, ref: > trips.id]
  hotel_id varchar
  offer_id varchar
  chain_code varchar
  room_type varchar
  currency char(3)
  total_price decimal
  offer_json json [not null]
  created_at datetime

  Indexes { trip_id, hotel_search_id }
}

Table hotel_bookings {
  id uuid [pk]
  trip_id uuid [not null, ref: > trips.id]
  hotel_offer_id uuid [not null, ref: > hotel_offers.id]
  booking_intent_id uuid [unique, ref: > booking_intents.id] // 1 intent -> 0/1 hotel booking

  amadeus_booking_id varchar [unique]
  status varchar
  amadeus_booking_request json [not null]
  amadeus_booking_response json
  created_at datetime
  updated_at datetime

  Indexes { trip_id }
}

Table booking_intents {
  id uuid [pk]
  user_id uuid [not null, ref: > users.id]
  trip_id uuid [not null, ref: > trips.id]

  type varchar [not null] // flight | hotel
  status varchar [not null] // INIT | AUTHORIZED | BOOKING_PENDING | BOOKED | CAPTURED | FAILED | CANCELLED | PAYMENT_CAPTURE_FAILED

  amount decimal [not null]
  currency char(3) [not null]

  selected_offer_type varchar // flight_offer | hotel_offer
  selected_offer_id uuid // id interne (flight_offers.id ou hotel_offers.id)
  selected_offer_payload_hash varchar // optionnel

  stripe_payment_intent_id varchar
  stripe_charge_id varchar

  amadeus_order_id varchar // flight
  amadeus_booking_id varchar // hotel

  last_error json
  raw json // metadata / idempotency keys / etc.
  created_at datetime
  updated_at datetime

  Indexes { user_id, trip_id, status }
}

Table stripe_events {
  id uuid [pk]
  stripe_event_id varchar [unique, not null]
  type varchar [not null]
  livemode boolean
  payload json [not null]
  received_at datetime

  booking_intent_id uuid [ref: > booking_intents.id]
  processed_at datetime
  processing_error json
}

Table amadeus_api_logs {
  id uuid [pk]
  trip_id uuid [ref: > trips.id]
  booking_intent_id uuid [ref: > booking_intents.id]

  api_name varchar [not null]
  http_method varchar [not null]
  path varchar [not null]
  request_headers json
  request_body json
  response_status int
  response_headers json
  response_body json
  duration_ms int
  created_at datetime

  Indexes { trip_id, booking_intent_id, api_name }
}
```

> Note POC sécurité : **ne stocke jamais** `cardNumber` en clair. Pour l’hôtel Amadeus, si “carte de garantie” requise : en sandbox mets des valeurs de test, mais ne les persiste pas (ou masque/crypto dans `amadeus_booking_request`).

---

## 2) Plan de dev API (minimum viable)

### Modules (découpage clair)

1. **Auth**
2. **Trips**
3. **Travelers**
4. **Flights** (search/offers/orders)
5. **Hotels** (search/offers/bookings)
6. **BookingIntents** (orchestration Stripe ↔ Amadeus) ✅
7. **StripeWebhooks** ✅
8. (Optionnel POC) Logs Amadeus

---

# 3) Endpoints complets (POC) + entrées/sorties

## 3.1 Auth

### `POST /v1/auth/register`

**In**

```json
{ "email":"a@b.com", "password":"x", "fullName":"A", "phone":"+33..." }
```

**Out 201**

```json
{ "user": { "id":"uuid", "email":"a@b.com" }, "token":"jwt" }
```

### `POST /v1/auth/login`

**In** `{ "email":"a@b.com", "password":"x" }`
**Out 200** `{ "user": {...}, "token":"jwt" }`

**Controller**: `AuthController`
**Service**: `AuthService`

---

## 3.2 Trips

### `POST /v1/trips`

**In**

```json
{ "title":"Rome", "originIata":"PAR", "destinationIata":"ROM", "startDate":"2026-01-10", "endDate":"2026-01-13" }
```

**Out 201** `{ "id":"uuid", ... }`

### `GET /v1/trips`

**Out 200**

```json
{ "items":[{ "id":"uuid","title":"Rome","status":"draft","startDate":"2026-01-10","endDate":"2026-01-13"}] }
```

### `GET /v1/trips/{tripId}`

**Out 200** (agrégé)

```json
{
  "trip": { "id":"uuid","status":"draft" },
  "flightOrder": null,
  "hotelBooking": null
}
```

### `PATCH /v1/trips/{tripId}`

**In** `{ "title":"Rome 2", "status":"planned" }`
**Out 200** trip updated

### `DELETE /v1/trips/{tripId}` → **204**

**Controller**: `TripsController`
**Service**: `TripsService`

---

## 3.3 Travelers

### `POST /v1/trips/{tripId}/travelers`

**In**

```json
{
  "amadeusTravelerRef":"1",
  "travelerType":"ADULT",
  "firstName":"Jane",
  "lastName":"Doe",
  "dateOfBirth":"1994-05-12",
  "gender":"FEMALE",
  "documents":[{"documentType":"PASSPORT","number":"12AB...","expiryDate":"2030-01-01","issuanceCountry":"FR","nationality":"FR"}],
  "contacts":{"email":"a@b.com","phone":"+33..."}
}
```

**Out 201** `{ "id":"uuid", ... }`

### `GET /v1/trips/{tripId}/travelers`

**Out 200** `{ "items":[...] }`

### `PATCH /v1/trips/{tripId}/travelers/{travelerId}`

### `DELETE /v1/trips/{tripId}/travelers/{travelerId}` → 204

**Controller**: `TravelersController`
**Service**: `TravelersService` (inclut un mapper `TravelerToAmadeusPayload` qui remplit `raw`)

---

## 3.4 Flights

### `POST /v1/trips/{tripId}/flights/searches`

**In**

```json
{
  "originIata":"PAR",
  "destinationIata":"ROM",
  "departureDate":"2026-01-10",
  "returnDate":"2026-01-13",
  "adults":2,
  "travelClass":"ECONOMY",
  "currency":"EUR",
  "nonStop":false
}
```

**Out 201**

```json
{
  "searchId":"uuid",
  "offers":[
    { "id":"uuid", "grandTotal":245.9, "currency":"EUR", "summary":{ "stops":0 } }
  ]
}
```

### `GET /v1/trips/{tripId}/flights/searches/{searchId}`

**Out 200** `{ "search": {...}, "offers":[...] }`

### `GET /v1/trips/{tripId}/flights/offers/{offerDbId}`

**Out 200** `{ "id":"uuid", "offer": { /* offer_json */ } }`

### `POST /v1/trips/{tripId}/flights/offers/{offerDbId}/price` *(optionnel mais recommandé)*

**Out 200** `{ "offerId":"uuid", "pricedOffer": { /* priced_offer_json */ } }`

> Pour le POC, tu peux “sauter” le repricing si tu acceptes quelques échecs au booking, mais c’est mieux de l’avoir.

**Controllers**: `FlightSearchesController`, `FlightOffersController`
**Services**:

* `FlightSearchService` (call Amadeus + persist search/offers)
* `FlightOfferPricingService` (call Amadeus + store priced)
* `AmadeusFlightsClient`

---

## 3.5 Hotels

### `POST /v1/trips/{tripId}/hotels/searches`

**In**

```json
{ "cityCode":"ROM", "checkIn":"2026-01-10", "checkOut":"2026-01-13", "adults":2, "roomQty":1, "currency":"EUR" }
```

**Out 201**

```json
{
  "searchId":"uuid",
  "offers":[
    { "id":"uuid", "hotelId":"AMH123", "offerId":"OFFER_456", "totalPrice":390.0, "currency":"EUR" }
  ]
}
```

### `GET /v1/trips/{tripId}/hotels/searches/{searchId}`

**Out 200** `{ "search": {...}, "offers":[...] }`

### `GET /v1/trips/{tripId}/hotels/offers/{offerDbId}`

**Out 200** `{ "id":"uuid", "offer": { /* offer_json */ } }`

**Controllers**: `HotelSearchesController`, `HotelOffersController`
**Services**:

* `HotelSearchService`
* `AmadeusHotelsClient`

---

# 4) Stripe + Booking orchestration (Pattern 2)

C’est ici que ton POC devient “fiable”.
Le front ne réserve plus directement : il passe par **BookingIntent**.

## 4.1 Créer une intention de booking

### `POST /v1/trips/{tripId}/booking-intents`

**Description** : lier une offre sélectionnée (vol/hôtel) à un intent et calculer le montant.

**In (flight)**

```json
{ "type":"flight", "flightOfferId":"uuid" }
```

**In (hotel)**

```json
{ "type":"hotel", "hotelOfferId":"uuid" }
```

**Out 201**

```json
{
  "bookingIntent": {
    "id":"uuid",
    "type":"flight",
    "status":"INIT",
    "amount":24590,
    "currency":"EUR",
    "selectedOfferId":"uuid"
  }
}
```

> `amount` : je te conseille de le stocker en **minor units** côté code (cents) même si ta DB met decimal.

**Controller**: `BookingIntentsController.create()`
**Service**: `BookingIntentsService.createIntent(tripId, userId, dto)`

* charge l’offre DB
* calcule amount/currency
* stocke `selected_offer_id` + hash optionnel

---

## 4.2 Autoriser paiement (Stripe PaymentIntent manual capture)

### `POST /v1/booking-intents/{intentId}/payment/authorize`

**Description** : crée un PaymentIntent Stripe en `capture_method=manual` et renvoie `client_secret`.

**In**

```json
{ "returnUrl":"https://app/callback" }
```

**Out 200**

```json
{
  "stripePaymentIntentId":"pi_123",
  "clientSecret":"pi_123_secret_...",
  "status":"requires_payment_method"
}
```

**Controller**: `PaymentsController.authorize()` (ou `BookingIntentsPaymentsController`)
**Service**: `StripePaymentsService.createManualCapturePaymentIntent(intentId, userId)`

* met `metadata: { booking_intent_id, trip_id, type }`
* enregistre `stripe_payment_intent_id`
* status intent reste `INIT` (ou passe `PAYMENT_CREATED` si tu veux)

**Front** : confirme PaymentIntent via Stripe SDK → statut attendu `requires_capture`.

---

## 4.3 Webhook Stripe (mettre intent en AUTHORIZED)

### `POST /v1/stripe/webhooks`

**Description** : reçoit les events Stripe, met à jour `booking_intents`.

Événements minimum :

* `payment_intent.amount_capturable_updated` → intent = `AUTHORIZED`
* `payment_intent.canceled` → intent = `CANCELLED`
* (optionnel) `payment_intent.payment_failed`

**Out 200** `{ "received": true }`

**Controller**: `StripeWebhooksController.handle()`
**Service**: `StripeWebhooksService.processEvent(event)`

* persiste dans `stripe_events` (idempotence via `stripe_event_id`)
* map → update booking intent

---

## 4.4 Book (Amadeus) — seulement si AUTHORIZED

### `POST /v1/booking-intents/{intentId}/book`

**Description** : orchestre l’appel Amadeus selon `type`.

**In (flight)**

```json
{
  "travelerIds":["uuid1","uuid2"],
  "contacts":[{ "emailAddress":"a@b.com" }]
}
```

**In (hotel)**

```json
{
  "guests":[{ "name":{"firstName":"John","lastName":"Doe"}, "contact":{"email":"a@b.com"} }],
  "roomAssociations":[{ "guestReferences":["1"], "hotelOfferId":"OFFER_456" }]
}
```

**Out 201**

```json
{
  "bookingIntent": { "id":"uuid", "status":"BOOKED" },
  "amadeus": {
    "type":"flight",
    "orderId":"eJz..."
  }
}
```

**Controller**: `BookingIntentsController.book()`
**Service**: `BookingOrchestratorService.book(intentId, userId, dto)`

* vérifie `AUTHORIZED`
* passe `BOOKING_PENDING`
* si `type=flight` :

  * build payload Amadeus = offer + travelers(raw) + contacts
  * call `AmadeusFlightsClient.createOrder()`
  * insert `flight_orders` + set `amadeus_order_id`
* si `type=hotel` :

  * build payload booking hotel
  * call `AmadeusHotelsClient.bookHotel()`
  * insert `hotel_bookings` + set `amadeus_booking_id`
* status intent → `BOOKED`

Si KO :

* status → `FAILED`
* `last_error` rempli
* (et tu peux auto-cancel l’autorisation via endpoint ci-dessous ou directement dans le service)

---

## 4.5 Capture Stripe — seulement si BOOKED

### `POST /v1/booking-intents/{intentId}/payment/capture`

**Out 200**

```json
{
  "bookingIntent": { "id":"uuid", "status":"CAPTURED" },
  "stripe": { "paymentIntentId":"pi_123" }
}
```

**Controller**: `PaymentsController.capture()`
**Service**: `StripePaymentsService.capture(intentId, userId)`

* vérifie `BOOKED`
* capture PaymentIntent
* update intent → `CAPTURED`
* si capture KO → `PAYMENT_CAPTURE_FAILED` + retry manuel

---

## 4.6 Cancel l’autorisation si booking échoue

### `POST /v1/booking-intents/{intentId}/payment/cancel`

**Out 200**

```json
{ "bookingIntent": { "id":"uuid", "status":"CANCELLED" } }
```

**Controller**: `PaymentsController.cancel()`
**Service**: `StripePaymentsService.cancel(intentId, userId)`

* annule PaymentIntent si possible

---

# 5) Liste finale Controllers & Services (POC)

## Controllers

* `AuthController`
* `TripsController`
* `TravelersController`
* `FlightSearchesController`
* `FlightOffersController`
* `HotelSearchesController`
* `HotelOffersController`
* `BookingIntentsController`
* `PaymentsController` (authorize/capture/cancel)
* `StripeWebhooksController`
* (optionnel) `LogsController`

## Services

**Core**

* `AuthService`
* `TripsService`
* `TravelersService`

**Amadeus**

* `AmadeusFlightsClient`
* `AmadeusHotelsClient`
* `FlightSearchService`
* `FlightOfferPricingService` (optionnel)
* `HotelSearchService`

**Orchestration & payment**

* `BookingIntentsService`
* `BookingOrchestratorService` ✅ (book flight/hotel)
* `StripePaymentsService`
* `StripeWebhooksService`

**Infra**

* `AmadeusLogsService` (ou intégré aux clients)
* `IdempotencyService` (simple : clé en header + table optionnelle, ou usage DB unique constraints)

---

# 6) Plan de dev (ordre exact, POC)

### Sprint 0 — Setup

1. Projet API + DB migrations + ORM
2. Auth JWT
3. CRUD Trips

### Sprint 1 — Données voyage

4. CRUD Travelers (avec génération `raw` Amadeus)
5. Flight search + persist offers
6. Hotel search + persist offers

### Sprint 2 — Paiement & orchestration (ton Pattern 2)

7. `POST /booking-intents` (flight/hotel)
8. `POST /booking-intents/{id}/payment/authorize` (Stripe manual capture)
9. Webhook Stripe + table `stripe_events` (idempotence)
10. `POST /booking-intents/{id}/book` (Amadeus booking)
11. `POST /booking-intents/{id}/payment/capture`
12. `POST /booking-intents/{id}/payment/cancel`

### Sprint 3 — Stabilisation (très court)

13. Logs Amadeus + `last_error` partout
14. Idempotency (Stripe keys + DB unique constraints + `stripe_events` unique)
15. Tests end-to-end : happy path + échecs (booking KO, capture KO)

---

# 7) Règles d’état (à implémenter tel quel)

Transitions autorisées sur `booking_intents.status` :

* `INIT` → `AUTHORIZED` (via webhook `amount_capturable_updated`)
* `AUTHORIZED` → `BOOKING_PENDING` → `BOOKED`
* `BOOKED` → `CAPTURED`
* `AUTHORIZED|BOOKING_PENDING` → `FAILED`
* `FAILED` → `CANCELLED` (après cancel Stripe)
* `BOOKED` → `PAYMENT_CAPTURE_FAILED` (si capture KO)

Garde-fous :

* `/book` refuse si pas `AUTHORIZED`
* `/capture` refuse si pas `BOOKED`
* `/cancel` refuse si déjà `CAPTURED`
