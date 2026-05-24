# Endpoints REST BagTrip

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

Le backend FastAPI expose environ **150** endpoints REST repartis sur **22 routers**, tous montes dans `src/main.py` via `app.include_router(...)`. Hors `/admin/*` (back-office) et la racine `/` + `/health`, **tous les paths sont prefixes `/v1/`**. Il s'agit du seul niveau de version expose. Aucun routeur `/v2/` n'existe : les ruptures de contrat sont gerees par des nouveaux endpoints ou champs.

Conventions transverses :

- **Auth** : JWT `Authorization: Bearer <access_token>` (cookies HttpOnly equivalents en parallele). 401 declenche le single-guard refresh cote Flutter via `/v1/auth/refresh`.
- **Body / Response** : Pydantic v2, `populate_by_name=True`, `alias_generator=to_camel` cote responses (les schemas API exposent `camelCase` meme si les modeles ORM sont en `snake_case`).
- **Erreurs metier** : tout passe par `AppError` (`utils/errors.py`) + le handler global `app_error_handler` qui retourne `{ "detail": { "error", "code", ...extra } }`.
- **Pagination** : dependency partagee `PaginationParams` (`page>=1`, `limit 1..100`, default `20`). Reponse generique `Page[T]` ou variantes typees (`TripPaginatedResponse`, `ActivityPaginatedResponse`, `NotificationListResponse`, `AdminListResponse[T]`).
- **Ownership trips** : trois dependencies cote `src/api/auth/trip_access.py` :
  - `get_trip_access` (OWNER / EDITOR / VIEWER, lecture)
  - `get_trip_editor_access` (OWNER / EDITOR, ecriture)
  - `get_trip_owner_access` (OWNER seul, parametres trip / shares)
- **Quotas AI** : dependency `require_ai_quota` consomme un credit (decremente cote `PlanService.increment_ai_generation` apres succes uniquement). `require_premium` gate les flows premium-only (`/v1/ai/post-trip-suggestion`).
- **Admin** : dependency `require_admin` (rolling JWT + flag user `is_admin`). Tous les endpoints `/admin/*` derriere ce guard.
- **Locale** : header `Accept-Language` => `normalize_locale(...)` => threade dans les prompts LLM, fallback `en`.

Status codes :

- `200` lecture / mutation standard
- `201` creation (`POST` qui produit une nouvelle ressource)
- `204` suppression / logout / endpoints qui ne retournent rien
- `400` validation metier (`AppError` 400) ou JSON invalide
- `401` auth manquante / invalide
- `403` ownership / role / plan insuffisant
- `404` ressource introuvable
- `409` conflits (status transitions, doubles invites)
- `429` rate limit
- `502` upstream Amadeus / Stripe / FCM degrade
- `503` integration desactivee (`AIRLABS_NOT_CONFIGURED`, webhook secret manquant en prod)

---

## Auth

Prefixe : `/v1/auth`. Tag OpenAPI : `Auth`. Routeur : `api/src/api/auth/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/auth/register` | Public | Creation compte email + mot de passe, bcrypt + `UserCreationService.create_and_setup_user`, renvoie `AuthResponse` (access + refresh + user). 201. |
| POST | `/v1/auth/login` | Public | Login email + password, retourne `AuthResponse`. Cookies HttpOnly poses. |
| POST | `/v1/auth/google` | Public | Sign-in via Google ID token (`GoogleSignInRequest.idToken`), upsert user + retourne `AuthResponse`. |
| POST | `/v1/auth/apple` | Public | Sign-in via Apple ID token (`AppleSignInRequest.idToken`), gere "hide my email" via `sub` fallback. |
| POST | `/v1/auth/refresh` | Public (refresh token) | Rotation refresh token : revoke ancien + nouvelle paire access/refresh. Detection de reuse interne (vol). |
| POST | `/v1/auth/logout` | Bearer | Revoque le refresh token (body ou cookie). 204. |
| POST | `/v1/auth/logout-all` | Bearer | Revoque tous les refresh tokens de l'utilisateur. 204. |
| GET | `/v1/auth/me` | Bearer | Retourne `UserResponse` enrichi (`is_profile_completed`, `plan`, `ai_generations_remaining`, `plan_expires_at`). |
| PATCH | `/v1/auth/me` | Bearer | Met a jour `fullName` / `phone` (`UpdateUserRequest`). |
| DELETE | `/v1/auth/me` | Bearer | Suppression RGPD : cascade tout l'arbre voyages + Stripe customer best-effort. 204. |
| POST | `/v1/auth/forgot-password` | Public | Genere un reset token (sha256 store), retourne toujours 200 anti-enumeration. Dev expose `debug_reset_token`. |
| POST | `/v1/auth/reset-password` | Public | Reset via token + nouveau mot de passe. |

Schemas references : `SignupRequest`, `LoginRequest`, `GoogleSignInRequest`, `AppleSignInRequest`, `RefreshTokenRequest`, `LogoutRequest`, `ForgotPasswordRequest`, `ResetPasswordRequest`, `UpdateUserRequest`, `AuthResponse`, `UserResponse` (tous dans `api/auth/schemas.py`).

---

## Profile

Prefixe : `/v1/profile`. Tag : `Profile`. Routeur : `api/src/api/profile/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| GET | `/v1/profile` | Bearer | Profil voyageur (cree un profil vide si inexistant). |
| PUT | `/v1/profile` | Bearer | Upsert preferences (`travelTypes`, `travelStyle`, `budget`, `companions`, `medicalConstraints`, `travelFrequency`). |
| GET | `/v1/profile/completion` | Bearer | Statut de completion (`is_completed`, `missing_fields`). |

Schemas : `ProfileCreateUpdateRequest`, `ProfileResponse`, `ProfileCompletionResponse` (`api/profile/schemas.py`).

---

## Trips

Prefixe : `/v1/trips`. Tag : `Trips`. Routeur : `api/src/api/trips/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/trips` | Bearer | Creation trip + auto-fetch cover Unsplash si manquant. 201. |
| GET | `/v1/trips` | Bearer | Liste paginee (owned + shared). Query `status`, `page`, `limit`. |
| GET | `/v1/trips/grouped` | Bearer | Voyages groupes en `ongoing` / `planned` / `completed`. |
| GET | `/v1/trips/{tripId}` | TripAccess | Detail trip + agregations + flight order resume + completion. |
| GET | `/v1/trips/{tripId}/home` | TripAccess | Donnees de la page d'accueil voyage (stats, features tiles, sections). Viewer voit `totalExpenses=0`. |
| PATCH | `/v1/trips/{tripId}` | OwnerAccess | Mise a jour trip (titre, dates, destination, nbTravelers, budget, dateMode...). |
| PATCH | `/v1/trips/{tripId}/tracking` | OwnerAccess | Toggle `flightsTracking` / `accommodationsTracking` (skip companion alerts). |
| PATCH | `/v1/trips/{tripId}/status` | OwnerAccess | Transition de status validee. ONGOING => COMPLETED declenche notifs `TRIP_ENDED`. |
| GET | `/v1/trips/{tripId}/completion-debug` | OwnerAccess | Breakdown 4 segments (flights / accommodations / activities / baggage). **404 en production.** |
| GET | `/v1/trips/{tripId}/weather` | TripAccess | Meteo destination (resolution IATA + Open-Meteo, fenetre `max(start,today)` -> `min(end,today+7j)`). |
| DELETE | `/v1/trips/{tripId}` | OwnerAccess | Suppression trip. 204. |

Schemas : `TripCreateRequest`, `TripUpdateRequest`, `TripTrackingUpdateRequest`, `TripStatusUpdateRequest`, `TripResponse`, `TripDetailResponse`, `TripHomeResponse`, `TripGroupedResponse`, `TripPaginatedResponse`, `WeatherResponse` (`api/trips/schemas.py`).

---

## Activities

Prefixe : `/v1/trips`. Tag : `Activities`. Routeur : `api/src/api/activities/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/trips/{tripId}/activities` | EditorAccess | Creation activite (title, date, startTime, endTime, location, category, estimatedCost, isBooked, validationStatus). 201. |
| GET | `/v1/trips/{tripId}/activities` | TripAccess | Liste paginee. Viewer voit `estimatedCost=null`. |
| GET | `/v1/trips/{tripId}/activities/{activityId}` | TripAccess | Detail activite. Viewer masque estimatedCost. |
| PATCH | `/v1/trips/{tripId}/activities/{activityId}` | EditorAccess | Update partiel. Plus de PUT (mort, retire). |
| DELETE | `/v1/trips/{tripId}/activities/{activityId}` | EditorAccess | Suppression. 204. |
| PATCH | `/v1/trips/{tripId}/activities/batch` | EditorAccess | Batch update via `activityIds[]` + `updates`. |
| POST | `/v1/trips/{tripId}/activities/suggest` | EditorAccess + `require_ai_quota` | Suggestions IA jour-par-jour (`day` optionnel). Consomme un credit AI. |

Schemas : `ActivityCreateRequest`, `ActivityUpdateRequest`, `ActivityBatchUpdateRequest`, `ActivityResponse`, `ActivityPaginatedResponse`, `ActivitySuggestResponse` (`api/activities/schemas.py`).

---

## Accommodations

Prefixe : `/v1/trips`. Tag : `Accommodations`. Routeur : `api/src/api/accommodations/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/trips/{tripId}/accommodations` | EditorAccess | Creation hebergement (name, address, checkIn, checkOut, pricePerNight, currency, bookingReference, notes). 201. |
| GET | `/v1/trips/{tripId}/accommodations` | TripAccess | Liste accommodations. Viewer voit `pricePerNight`, `currency`, `bookingReference` nullifies. |
| PATCH | `/v1/trips/{tripId}/accommodations/{accommodationId}` | EditorAccess | Update partiel. Gere le clear explicite de `pricePerNight` via `model_fields_set`. |
| DELETE | `/v1/trips/{tripId}/accommodations/{accommodationId}` | EditorAccess | Suppression. 204. |
| POST | `/v1/trips/{tripId}/accommodations/suggest` | EditorAccess + `require_ai_quota` | Suggestions IA d'hebergements (locale-aware). |

Schemas : `AccommodationCreateRequest`, `AccommodationUpdateRequest`, `AccommodationResponse`, `AccommodationListResponse`, `AccommodationSuggestResponse` (`api/accommodations/schemas.py`).

---

## Baggage

Prefixe : `/v1/trips`. Tag : `Baggage`. Routeur : `api/src/api/baggage/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/trips/{tripId}/baggage` | EditorAccess | Creation item bagage (name, quantity, isPacked, category, notes). 201. |
| GET | `/v1/trips/{tripId}/baggage` | TripAccess | Liste items bagages. |
| PATCH | `/v1/trips/{tripId}/baggage/{baggageItemId}` | EditorAccess | Update item. |
| DELETE | `/v1/trips/{tripId}/baggage/{baggageItemId}` | EditorAccess | Suppression. 204. |
| POST | `/v1/trips/{tripId}/baggage/suggest` | EditorAccess + `require_ai_quota` | Suggestions IA checklist bagages. |

Schemas : `BaggageItemCreateRequest`, `BaggageItemUpdateRequest`, `BaggageItemResponse`, `BaggageItemListResponse`, `BaggageSuggestionListResponse` (`api/baggage/schemas.py`).

---

## Budget items

Prefixe : `/v1/trips`. Tag : `BudgetItems`. Routeur : `api/src/api/budget_items/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/trips/{tripId}/budget-items` | EditorAccess | Creation depense (label, amount, category, date, isPlanned, validationStatus). Declenche `check_and_send_budget_alert`. 201. |
| GET | `/v1/trips/{tripId}/budget-items` | TripAccess | Liste items. Viewer recoit liste vide. |
| GET | `/v1/trips/{tripId}/budget-items/summary` | TripAccess | Summary agregre (total spent, percent consumed, par categorie). Viewer redacted via `redact_budget_summary_for_role`. |
| GET | `/v1/trips/{tripId}/budget-items/{itemId}` | TripAccess | Detail item. Viewer 403. |
| PUT | `/v1/trips/{tripId}/budget-items/{itemId}` | EditorAccess | Update complet. Re-check budget alerts. |
| DELETE | `/v1/trips/{tripId}/budget-items/{itemId}` | EditorAccess | Suppression + recheck alert. 204. |
| POST | `/v1/trips/{tripId}/budget/estimate` | EditorAccess + `require_ai_quota` | Estimation IA en s'appuyant sur le contexte trip (`agent/nodes/budget.budget_node`). |
| POST | `/v1/trips/{tripId}/budget/estimate/accept` | EditorAccess | Ecrit `trip.budget_estimated` (le `budget_target` user reste intact). |

Schemas : `BudgetItemCreateRequest`, `BudgetItemUpdateRequest`, `BudgetItemResponse`, `BudgetItemListResponse`, `BudgetSummaryResponse`, `BudgetEstimateResponse`, `AcceptEstimateRequest` (`api/budget_items/schemas.py`).

---

## Travelers

Prefixe : `/v1/trips`. Tag : `Travelers`. Routeur : `api/src/api/travelers/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/trips/{tripId}/travelers` | EditorAccess | Ajout voyageur (firstName, lastName, dateOfBirth, gender, travelerType, documents, contacts, amadeusTravelerRef). 201. |
| GET | `/v1/trips/{tripId}/travelers` | TripAccess | Liste travelers. |
| PATCH | `/v1/trips/{tripId}/travelers/{travelerId}` | EditorAccess | Update voyageur. |
| DELETE | `/v1/trips/{tripId}/travelers/{travelerId}` | EditorAccess | Suppression. 204. |

Schemas : `TravelerCreateRequest`, `TravelerUpdateRequest`, `TravelerResponse`, `TravelerListResponse` (`api/travelers/schemas.py`).

---

## Shares

Prefixe : `/v1/trips`. Tag : `Shares`. Routeur : `api/src/api/shares/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/trips/{tripId}/shares` | OwnerAccess | Invite par email + role (`VIEWER` / `EDITOR`). Si user inexistant => pending invite + token + mail. 201. |
| GET | `/v1/trips/{tripId}/shares` | TripAccess | Liste shares actifs + pending invites (visible OWNER seul). |
| DELETE | `/v1/trips/{tripId}/shares/{shareId}` | OwnerAccess | Revoque un share. 204. |
| DELETE | `/v1/trips/{tripId}/pending-invites/{inviteId}` | OwnerAccess | Annule une invite en attente. 204. |

Schemas : `ShareCreateRequest`, `ShareCreateResponse`, `ShareResponse`, `ShareListResponse`, `PendingInviteResponse` (`api/shares/schemas.py`).

---

## Invites

Prefixe : `/v1/invites`. Tag : `Invites`. Routeur : `api/src/api/invites/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/invites/{token}/accept` | Bearer | Accepte une invitation par token, joint le voyage. |

Schemas reutilises depuis shares : `ShareResponse`.

---

## Feedback

Prefixe : `/v1/trips`. Tag : `Feedback`. Routeur : `api/src/api/feedback/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/trips/{tripId}/feedback` | TripAccess (owner + viewers) | Soumettre un feedback de voyage termine (`overallRating`, `highlights`, `lowlights`, `wouldRecommend`, `aiExperienceRating`). 201. |
| GET | `/v1/trips/{tripId}/feedback` | TripAccess | Liste des feedbacks du trip. |

Schemas : `FeedbackCreateRequest`, `FeedbackResponse`, `FeedbackListResponse` (`api/feedback/schemas.py`).

---

## Flight searches

Prefixe : `/v1/trips`. Tag : `Flight Searches`. Routeur : `api/src/api/flights/searches/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/trips/{tripId}/flights/searches` | EditorAccess | Recherche Amadeus (origin/destination/dates/pax/class/nonStop/currency). Persiste search + offers. 201. |
| GET | `/v1/trips/{tripId}/flights/searches/{searchId}` | TripAccess | Detail search + offres persistees. Viewer masque `grandTotal` / `baseTotal`. |
| POST | `/v1/trips/{tripId}/flights/searches/multi` | EditorAccess | Recherche multi-segments (un appel Amadeus par segment). 201. |

Schemas : `FlightSearchCreateRequest`, `FlightSearchResponse`, `FlightSearchDetailResponse`, `FlightOfferSummary`, `FlightOfferDetail`, `MultiDestSearchCreateRequest`, `MultiDestSearchResponse` (`api/flights/searches/schemas.py`).

---

## Flight offers

Prefixe : `/v1/trips`. Tag : `Flight Offers`. Routeur : `api/src/api/flights/offers/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| GET | `/v1/trips/{tripId}/flights/offers/{offerDbId}` | TripAccess | Offre persistee complete. Viewer ne voit que `price.currency`. |
| POST | `/v1/trips/{tripId}/flights/offers/{offerDbId}/price` | EditorAccess | Re-pricing Amadeus (avant booking). Stocke `priced_offer_json`. |

Schemas : `FlightOfferResponse`, `FlightOfferPriceResponse` (`api/flights/offers/schemas.py`).

---

## Manual flights

Prefixe : `/v1/trips`. Tag : `Manual Flights`. Routeur : `api/src/api/flights/manual/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/trips/{tripId}/flights/manual` | EditorAccess | Ajout vol manuel (flightNumber, airline, departure/arrival airport, dates, price, currency, notes, flightType). 201. |
| GET | `/v1/trips/{tripId}/flights/manual` | TripAccess | Liste vols manuels. |
| GET | `/v1/trips/{tripId}/flights/manual/{flightId}` | TripAccess | Detail vol manuel. |
| PATCH | `/v1/trips/{tripId}/flights/manual/{flightId}` | EditorAccess | Update partiel (mapping camel/snake explicite via `model_dump(exclude_unset=True)`). |
| DELETE | `/v1/trips/{tripId}/flights/manual/{flightId}` | EditorAccess | Suppression. 204. |

Schemas : `ManualFlightCreateRequest`, `ManualFlightUpdateRequest`, `ManualFlightResponse`, `ManualFlightListResponse` (`api/flights/manual/schemas.py`).

---

## Flight info

Prefixe : `/v1/travel/flights`. Tag : `Flight Info`. Routeur : `api/src/api/flights/info/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| GET | `/v1/travel/flights/{flightNumber}/info` | Bearer | Infos temps reel d'un vol IATA via AirLabs (`AirLabsService.lookup_flight`). 503 si non configure. 400 si IATA invalide. |

Schemas : `FlightInfoResponse` (`api/flights/info/schemas.py`).

---

## Flight orders

Prefixe : `/v1/trips`. Tag : `Flight Orders`. Routeur : `api/src/api/flights/orders/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| GET | `/v1/trips/{tripId}/flights/orders` | TripAccess | Liste flight orders confirmes. Viewer masque `paymentId`. |
| GET | `/v1/trips/{tripId}/flights/orders/{orderId}` | TripAccess | Detail flight order. |
| DELETE | `/v1/trips/{tripId}/flights/orders/{orderId}` | EditorAccess | Suppression order. 403 si statut `CONFIRMED` (`CONFIRMED_FLIGHT_IMMUTABLE`). 204. |

Schemas : `FlightOrderResponse` (`api/flights/orders/schemas.py`).

---

## Booking intents

Deux routeurs distincts mais meme tag `Booking Intents`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/trips/{tripId}/booking-intents` | EditorAccess | Cree une intention de booking pour une offre selectionnee (`type`, `flightOfferId`). 201. |
| GET | `/v1/booking-intents/{intentId}` | Bearer | Recupere une booking intent par id (ownership user). |
| POST | `/v1/booking-intents/{intentId}/book` | Bearer | Reserve via Amadeus (`BookingOrchestratorService.book` : DB lock + repricing + create order + capture). Necessite status `AUTHORIZED`. 201. |

Routeurs : `api/src/api/booking_intents/routes.py` (creation), `api/src/api/booking_intents/book_routes.py` (lecture + book).

Schemas : `BookingIntentCreateRequest`, `BookingIntentResponse`, `BookingIntentBookRequestFlight`, `BookingIntentBookResponse` (`api/booking_intents/schemas.py`).

---

## Payments

Prefixe : `/v1/booking-intents`. Tag : `Payments`. Routeur : `api/src/api/payments/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/booking-intents/{intentId}/payment/authorize` | Bearer | Cree un PaymentIntent Stripe manual capture (`StripePaymentsService`). |
| POST | `/v1/booking-intents/{intentId}/payment/capture` | Bearer | Capture le PaymentIntent (exige `BOOKED` en prod). |
| POST | `/v1/booking-intents/{intentId}/payment/cancel` | Bearer | Annule le PaymentIntent. |
| POST | `/v1/booking-intents/{intentId}/payment/refund` | Bearer | Refund total / partiel d'un PaymentIntent capture. |
| POST | `/v1/booking-intents/{intentId}/payment/confirm-test` | Admin (non-prod uniquement) | QA helper : confirme PaymentIntent avec carte test Stripe. 404 en production meme pour admin. |

Schemas : `PaymentAuthorizeRequest`, `PaymentAuthorizeResponse`, `PaymentCaptureResponse`, `PaymentCancelResponse`, `PaymentRefundRequest`, `PaymentRefundResponse` (`api/payments/schemas.py`).

---

## Notifications

Prefixe : `/v1/notifications`. Tag : `Notifications`. Routeur : `api/src/api/notifications/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| GET | `/v1/notifications` | Bearer | Liste paginee notifications + `unreadCount`. |
| GET | `/v1/notifications/unread-count` | Bearer | Compteur unread pour le badge. |
| PATCH | `/v1/notifications/{notificationId}/read` | Bearer | Marque une notif comme lue. |
| POST | `/v1/notifications/read-all` | Bearer | Marque toutes les notifs comme lues. Retourne `{updated: <count>}`. |

Schemas : `NotificationResponse`, `NotificationListResponse`, `UnreadCountResponse` (`api/notifications/schemas.py`).

---

## Device tokens

Prefixe : `/v1/device-tokens`. Tag : `DeviceTokens`. Routeur : `api/src/api/device_tokens/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/device-tokens` | Bearer | Enregistre un token FCM (`fcmToken`, `platform`, `locale`). 201. |
| DELETE | `/v1/device-tokens` | Bearer | Desenregistre un token (token via body pour ne pas leaker dans les access logs). 204. |

Schemas : `DeviceTokenRegisterRequest`, `DeviceTokenUnregisterRequest`, `DeviceTokenResponse` (`api/device_tokens/schemas.py`).

---

## Subscription

Prefixe : `/v1/subscription`. Tag : `Subscription`. Routeur : `api/src/api/subscription/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/subscription/checkout` | Bearer | Legacy : cree une session Stripe Checkout (fallback web). |
| POST | `/v1/subscription/start` | Bearer | Bootstrap PaymentSheet (`{customer, ephemeral_key, amount, currency}`) sans creer la sub. |
| POST | `/v1/subscription/confirm` | Bearer | Cree la `Subscription(default_incomplete)` avec le `paymentMethodId` choisi, retourne le client_secret. |
| POST | `/v1/subscription/payment-method/setup` | Bearer | SetupIntent pour rattacher / changer la carte in-app. |
| POST | `/v1/subscription/payment-method/attach` | Bearer | Attache un `paymentMethodId` comme default sub. |
| POST | `/v1/subscription/portal` | Bearer | Stripe Billing Portal session (fallback). |
| GET | `/v1/subscription/status` | Bearer | Statut light (plan, period_end). |
| GET | `/v1/subscription/me` | Bearer | Detail sub (renewal date, payment method, cancel state). |
| POST | `/v1/subscription/cancel` | Bearer | Schedule cancel at period end. |
| POST | `/v1/subscription/reactivate` | Bearer | Annule le scheduled-cancel. |
| GET | `/v1/subscription/invoices` | Bearer | Recent invoices (`limit` 1..50, default 12). |

Pas de fichier `schemas.py` dedie : retours JSON dictes par `SubscriptionService`.

---

## Stripe webhooks

Prefixe : `/v1/stripe`. Tag : `Stripe Webhooks`. Routeur : `api/src/api/stripe/webhooks/routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/stripe/webhooks` | Signature Stripe (`stripe-signature`) | Receive et dispatch les events Stripe. Verification signature en prod, dev-only escape hatch hors prod. 503 si `STRIPE_WEBHOOK_SECRET` absent en production. |

Pas de schema Pydantic : on consomme directement le payload Stripe via `stripe.Webhook.construct_event`.

---

## Admin

Prefixe : `/admin` (sans `/v1/`). Tag : `Admin`. Routeur : `api/src/api/admin/routes.py`. Tous derriere `require_admin`.

### Listes paginees + search `q`

| Methode | Route | Description |
|---|---|---|
| GET | `/admin/health` | Health check admin. |
| GET | `/admin/users` | Liste users. |
| GET | `/admin/trips` | Liste trips. |
| GET | `/admin/travelers` | Liste travelers. |
| GET | `/admin/flight-bookings` | Liste flight bookings. |
| GET | `/admin/traveler-profiles` | Liste traveler profiles. |
| GET | `/admin/booking-intents` | Liste booking intents. |
| GET | `/admin/flight-searches` | Liste flight searches. |
| GET | `/admin/accommodations` | Liste hebergements. |
| GET | `/admin/activities` | Liste activites. |
| GET | `/admin/budget-items` | Liste budget items. |
| GET | `/admin/baggage-items` | Liste items bagages. |
| GET | `/admin/trip-shares` | Liste shares. |
| GET | `/admin/feedbacks` | Liste feedbacks. |
| GET | `/admin/notifications` | Liste notifications. |

### User management

| Methode | Route | Description |
|---|---|---|
| GET | `/admin/users/{userId}` | Detail user (`AdminUserDetailResponse`). |
| PATCH | `/admin/users/{userId}` | Update champs profil. Refuse `plan` self-change. |
| PATCH | `/admin/users/{userId}/plan` | Force change de plan (`UpdatePlanRequest`). |
| PATCH | `/admin/users/{userId}/ai-quota/reset` | Reset compteur AI a 0. |
| POST | `/admin/users/{userId}/ban` | Ban user (`AdminBanRequest`). Self-ban refuse. |
| POST | `/admin/users/{userId}/unban` | Lever le ban. |
| DELETE | `/admin/users/{userId}` | Soft-delete (`deleted_at`). Self-delete refuse. |
| POST | `/admin/users/bulk/plan` | Bulk plan change (`AdminBulkPlanRequest`). |
| POST | `/admin/users/bulk/ban` | Bulk ban (`AdminBulkBanRequest`). |

### Trip management

| Methode | Route | Description |
|---|---|---|
| GET | `/admin/trips/{tripId}` | Detail trip + sub-entity counts. |
| PATCH | `/admin/trips/{tripId}` | Update trip (admin bypass `AdminTripUpdateRequest`). |
| DELETE | `/admin/trips/{tripId}` | Hard-delete + cascade. 204. |
| PATCH | `/admin/trips/{tripId}/archive` | Soft-archive (`archived_at`). |

### Booking management

| Methode | Route | Description |
|---|---|---|
| GET | `/admin/booking-intents/{intentId}/detail` | Detail booking intent admin. |
| PATCH | `/admin/booking-intents/{intentId}/status` | Force status (`AdminBookingStatusRequest`). |
| POST | `/admin/booking-intents/{intentId}/cancel` | Force `CANCELLED`. |
| POST | `/admin/booking-intents/{intentId}/refund` | Force `REFUNDED` (n'execute pas le refund Stripe). |

### Sub-entity CRUD (admin bypass)

| Methode | Route | Description |
|---|---|---|
| POST | `/admin/trips/{tripId}/activities` | Cree activite (`AdminActivityCreateRequest`). |
| PATCH | `/admin/trips/{tripId}/activities/{activityId}` | Update activite. |
| DELETE | `/admin/trips/{tripId}/activities/{activityId}` | Delete activite. 204. |
| POST | `/admin/trips/{tripId}/accommodations` | Cree hebergement. |
| PATCH | `/admin/trips/{tripId}/accommodations/{accId}` | Update hebergement. |
| DELETE | `/admin/trips/{tripId}/accommodations/{accId}` | Delete hebergement. 204. |
| DELETE | `/admin/trips/{tripId}/budget-items/{itemId}` | Delete budget item. 204. |
| DELETE | `/admin/trips/{tripId}/baggage/{itemId}` | Delete baggage. 204. |
| DELETE | `/admin/trips/{tripId}/shares/{shareId}` | Revoke share. 204. |
| DELETE | `/admin/feedbacks/{feedbackId}` | Delete feedback. 204. |

### Audit log + exports + dashboards + notifs

| Methode | Route | Description |
|---|---|---|
| GET | `/admin/audit-logs` | Audit logs filtrables (`entity_type`, `entity_id`, `actor_id`, `action`). |
| GET | `/admin/users/export` | Export CSV users (`StreamingResponse`). |
| GET | `/admin/dashboard/metrics` | KPI dashboard. |
| GET | `/admin/dashboard/metrics/users-chart` | Chart inscriptions (`period` week/month/year). |
| GET | `/admin/dashboard/metrics/revenue-chart` | Chart revenus. |
| GET | `/admin/dashboard/metrics/feedbacks-chart` | Distribution feedbacks par rating. |
| POST | `/admin/notifications/send` | Envoie une notification push a des users (`AdminSendNotificationRequest`). |

Schemas (`api/admin/schemas.py`) : `AdminListResponse[T]`, `AdminUserResponse`, `AdminUserDetailResponse`, `AdminUserUpdateRequest`, `AdminBanRequest`, `AdminBulkBanRequest`, `AdminBulkPlanRequest`, `UpdatePlanRequest`, `AdminTripResponse`, `AdminTripDetailResponse`, `AdminTripUpdateRequest`, `AdminTravelerResponse`, `AdminTravelerProfileResponse`, `AdminFlightBookingResponse`, `AdminFlightSearchResponse`, `AdminAccommodationResponse/Create/Update`, `AdminActivityResponse/Create/Update`, `AdminBudgetItemResponse`, `AdminBaggageItemResponse`, `AdminTripShareResponse`, `AdminFeedbackResponse`, `AdminNotificationResponse`, `AdminBookingIntentResponse`, `AdminBookingStatusRequest`, `AdminSendNotificationRequest`, `AuditLogResponse`.

---

## Travel (locations + Amadeus search)

Prefixe : `/v1/travel`. Tag : `Travel`. Routeur : `api/src/api/travel/routes.py`. Cache TTLCache 15min / 256 entrees pour les recherches de vols.

### Locations (offline `aviation_data`)

| Methode | Route | Auth | Description |
|---|---|---|---|
| GET | `/v1/travel/locations` | Public | Recherche locations par `keyword` + `subType` (`CITY,AIRPORT`). |
| GET | `/v1/travel/locations/nearest` | Public | Plus proches d'un `(latitude, longitude)`. |
| GET | `/v1/travel/locations/{id}` | Public | Detail location par id IATA. |

### Vols Amadeus

| Methode | Route | Auth | Description |
|---|---|---|---|
| GET | `/v1/travel/flight/offers` | Public | Recherche d'offres Amadeus, cache 15 min, validations strictes (adults 1..9, includedAirlineCodes XOR excludedAirlineCodes, etc.). |
| GET | `/v1/travel/flight/destinations` | Public | Inspiration (origine fixee, "ou puis-je aller"). |
| GET | `/v1/travel/flight/cheapest-dates` | Public | Cheapest dates entre origine et destination. |

Schemas : `LocationSearchResult` (`api/travel/schemas.py`) + `FlightOfferSearchQuery`, `FlightInspirationSearchQuery`, `FlightCheapestDateSearchQuery` (`integrations/amadeus/types.py`).

---

## Hotels

Prefixe : `/v1/travel/hotels`. Tag : `Hotel Search`. Routeur : `api/src/api/hotels/routes.py`. Search-only (pas de booking Amadeus).

| Methode | Route | Auth | Description |
|---|---|---|---|
| GET | `/v1/travel/hotels/by-city` | Bearer | Liste hotels par `cityCode` IATA (`radius`, `ratings`, `hotelSource`). |
| GET | `/v1/travel/hotels/offers` | Bearer | Offres detaillees (`hotelIds` max 50, `checkInDate`, `checkOutDate`, `adults`, `currency`). |

Schemas : `HotelListSearchResponse`, `HotelOffersSearchResponse` (`api/hotels/schemas.py`) + `HotelListSearchQuery`, `HotelOffersSearchQuery` (`integrations/amadeus/types.py`).

---

## AI

Deux routeurs sous le prefixe `/v1/ai`.

### Plan trip SSE

Tag : `AI Trip Planning`. Routeur : `api/src/api/ai/plan_trip_routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/ai/plan-trip/stream` | Bearer + `require_ai_quota` | Genere un voyage complet en SSE (`text/event-stream`). Events emis : `progress`, `destinations`, `weather`, `activities`, `accommodations`, `transport`, `baggage`, `budget`, `warning`, `error`, `complete` (avec `tripId`), `done`. |

Schemas : `PlanTripRequest` (`api/ai/plan_trip_schemas.py`). Pipeline gere par `TripPlannerService.stream_plan`.

### Post trip

Tag : `AI Post-Trip`. Routeur : `api/src/api/ai/post_trip_routes.py`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/ai/post-trip-suggestion` | Bearer + `require_ai_quota` + `require_premium` | Suggestion next-trip via RAG sur historique feedbacks (W3 pipeline, BGE-M3 embeddings + catalogue cure). Premium-only. |

Schemas : `PostTripSuggestionResponse`, `PostTripSuggestion`, `PostTripActivity` (`api/ai/post_trip_schemas.py`).

---

## Booking (deprecated)

Prefixe : `/v1/booking`. Tag : `Booking (Deprecated)`. Routeur : `api/src/api/booking/routes.py`. Marquees `deprecated=True` dans OpenAPI, conservees pour retrocompat. Tous les flows passent desormais par `/v1/trips/{tripId}/booking-intents` + `/v1/booking-intents/{intentId}/book`.

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/v1/booking/pricing` | Public | **DEPRECATED** Confirme le prix d'une `flightOffer`. Remplace par `/v1/trips/{tripId}/flights/offers/{offerDbId}/price`. |
| POST | `/v1/booking/create` | Bearer | **DEPRECATED** Cree une reservation Amadeus + stocke dans la table `Booking`. Remplace par booking intents. |
| GET | `/v1/booking/list` | Bearer | **DEPRECATED** Liste les bookings de l'utilisateur. Remplace par `/v1/trips` + booking intents. |

Schemas : `FlightPriceRequest`, `FlightBookingRequest`, `BookingResponse` (`api/booking/schemas.py`).

---

## Endpoints racine

| Methode | Route | Description |
|---|---|---|
| GET | `/` | Banner `{ "message": "BagTrip API", "version": "1.0.0" }`. |
| GET | `/health` | Health check `{ "status": "ok" }`. |
| GET | `/metrics` | Exporte par `prometheus_fastapi_instrumentator` (configure dans `main.py`). |

---

## Conventions

### Authentification

- Header `Authorization: Bearer <jwt>` (algo HS256). Cookies HttpOnly equivalents (`access_token`, `refresh_token`) poses par le backend.
- `get_current_user` (`api/auth/middleware.py`) injecte l'utilisateur ORM. `require_admin` ajoute le flag admin. `require_premium` exige `plan == PREMIUM`. `require_ai_quota` decremente le quota AI (sur succes uniquement).
- 401 sur access expire => le client appelle `/v1/auth/refresh` (single-guard cote Flutter), rotation des deux tokens.

### Pagination

- Standard : `?page=<n>&limit=<n>` (`1..100`, default `20`) via `PaginationParams`.
- Reponses generiques `Page[T]` ou variantes typees (`TripPaginatedResponse`, `ActivityPaginatedResponse`, `NotificationListResponse`, `AdminListResponse[T]`). Toujours `{items, total, page, limit, totalPages}` (camelCase wire).
- Filtres optionnels : `status` (trips), `q` (recherche admin), `period` (charts).

### Conventions wire

- Responses **camelCase** (Pydantic + `alias_generator=to_camel`). Le snake_case interne SQLAlchemy n'est jamais expose tel quel.
- Dates : ISO 8601 (`YYYY-MM-DD` pour les dates pures, `YYYY-MM-DDTHH:MM:SSZ` pour les datetimes).
- Decimaux : floats serialises (`grandTotal`, `priceTotal`...). Le backend stocke en `Numeric` cote ORM.

### Role-based redaction

- `TripRole.VIEWER` declenche un masquage cote route ou via `redact_for_viewer(...)` / `redact_budget_summary_for_role(...)` :
  - Activities : `estimatedCost = null`
  - Accommodations : `pricePerNight`, `currency`, `bookingReference` nullifies
  - Budget items : liste vide + detail 403, summary redacted (jamais `total_spent` sans masquer `percent_consumed`)
  - Trip home : `totalExpenses = 0`
  - Flight offers / orders : `grandTotal`, `baseTotal`, `paymentId` nullifies

### Errors

- Reponse erreur : `{ "detail": { "error": "<message>", "code": "<code>", ...extra } }`.
- Codes principaux : `NOT_FOUND`, `FORBIDDEN`, `VALIDATION_ERROR`, `UPSTREAM_ERROR`, `RATE_LIMITED`, `INVALID_QUERY`, `OFFER_NOT_FOUND`, `SEARCH_NOT_FOUND`, `BOOKING_INTENT_NOT_FOUND`, `CONFIRMED_FLIGHT_IMMUTABLE`, `AIRLABS_NOT_CONFIGURED`, `NOT_AVAILABLE_IN_PROD`.

### Headers & middlewares

- `X-Request-ID` injecte par `request_id_middleware`, repropage dans chaque log.
- Headers securite forces par `security_headers_middleware` (HSTS / CSP / X-Frame-Options / Referrer).
- Rate limit Redis (`rate_limit_middleware` + `auth_rate_limit_middleware`, plus strict sur `/v1/auth/*`).
- CORS configure dans `main.py`, liste explicite validee au boot.
- SSE (`/v1/ai/plan-trip/stream`) ajoute `Cache-Control: no-cache`, `Connection: keep-alive`, `X-Accel-Buffering: no`.

---

## Ce qu'il manque

- **Endpoint read-only `/v1/trips/{tripId}/bookings`** : aucune vue unifiee qui liste les bookings cross-domain (vol + hotel + activite confirmes). Il faut taper `/flights/orders`, suivre les booking intents et croiser avec les accommodations / activities une par une.
- **Pagination accommodations / baggage / budget-items / travelers / flight-orders / manual-flights** : ces listes renvoient un tableau complet (`<X>ListResponse`). Pour un voyage avec >100 items, pas de cursor / page. A standardiser sur `Page[T]`.
- **Streaming notifications** : pas d'endpoint long-polling / SSE / WebSocket cote app. Le client poll `/v1/notifications/unread-count` + recoit les push FCM. Une WebSocket simplifierait le badge live.
- **`GET /v1/trips/{tripId}/feedback/{feedbackId}`** : pas d'endpoint de detail unitaire, seulement liste + create. Idem pour `PATCH` / `DELETE` (les feedbacks sont immuables cote owner, seul admin peut delete).
- **Booking intents hotels / activites** : le modele `BookingIntent` distingue les types mais `BookingOrchestratorService.book` ne gere que les vols (`travelerIds` only). Pas de route pour confirmer une nuit ou une activite via Amadeus.
- **`POST /v1/profile/preferences/reset`** : pas d'endpoint pour reset le profil. L'app fait un `PUT` avec tous les champs a null, semantique floue (clear vs noop).
- **`/v1/health/deep`** : pas de readiness probe qui verifie DB + Redis + Amadeus + Stripe + FCM. `/health` est un simple `{ "status": "ok" }` qui ne teste rien.
- **`/v1/subscription/sync`** : pas d'endpoint admin / user pour forcer la re-synchro d'une sub Stripe (uniquement reactif via webhooks). Necessaire quand un webhook a echoue silencieusement.
- **OpenAPI versioning explicite** : pas de header `API-Version` ni redirection `/api/...` -> `/v1/...`. Un vieux client qui tape `/api/trips` recoit un 404 brut.
- **Inconsistance `PUT` budget-items** : `PUT /v1/trips/{tripId}/budget-items/{itemId}` alors que tout le reste de l'API utilise `PATCH` pour les updates partiels (activities, accommodations, manual-flights, travelers, trips). A aligner.
- **`/v1/trips/{tripId}/completion-debug`** : utile en support mais 404 en production. Pas d'equivalent prod-safe (eventuellement gate sur role admin).
