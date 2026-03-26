# Reference des Endpoints API

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

L'API BagTrip expose ses routes sous le prefixe `/v1/` (sauf `/admin/` et les routes racine). Toutes les routes authentifiees utilisent le header `Authorization: Bearer <JWT>` ou un cookie `access_token` (httpOnly). Les routes admin requierent un user avec `plan = "ADMIN"`.

Les reponses suivent le format JSON standard. Les erreurs retournent `{"error": "...", "code": "..."}`.

## Routes systeme

| Methode | Path | Auth | Description |
|---------|------|------|-------------|
| GET | `/` | Non | Route racine — retourne `{"message": "BagTrip API", "version": "1.0.0"}` |
| GET | `/health` | Non | Health check — retourne `{"status": "ok"}` |

## Auth (`/v1/auth`)

Fichier : `api/src/api/auth/routes.py`

| Methode | Path | Auth | Description | Request Body | Response |
|---------|------|------|-------------|-------------|----------|
| POST | `/v1/auth/register` | Non | Inscription | `SignupRequest` (email, password, fullName?, phone?) | `AuthResponse` (201) |
| POST | `/v1/auth/login` | Non | Connexion email/password | `LoginRequest` (email, password) | `AuthResponse` |
| POST | `/v1/auth/google` | Non | Sign-in Google (Firebase ID token) | `GoogleSignInRequest` (idToken) | `AuthResponse` |
| POST | `/v1/auth/apple` | Non | Sign-in Apple (ID token) | `AppleSignInRequest` (idToken) | `AuthResponse` |
| POST | `/v1/auth/refresh` | Non | Rotation de tokens | `RefreshTokenRequest` (refresh_token) | `AuthResponse` |
| GET | `/v1/auth/me` | Oui | Profil utilisateur courant | - | `UserResponse` |
| PATCH | `/v1/auth/me` | Oui | Mise a jour profil (nom, phone) | `UpdateUserRequest` (fullName?, phone?) | `UserResponse` |
| POST | `/v1/auth/logout` | Oui | Revocation d'un refresh token | `LogoutRequest` (refresh_token?) | 204 |
| POST | `/v1/auth/logout-all` | Oui | Revocation de tous les refresh tokens | - | 204 |

`AuthResponse` : `{access_token, refresh_token, expires_in, token_type, user: UserResponse}`

## Trips (`/v1/trips`)

Fichier : `api/src/api/trips/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/v1/trips` | Oui | Owner | Creer un trip (auto-fetch cover Unsplash) |
| GET | `/v1/trips` | Oui | Owner+Viewer | Lister les trips (pagine, filtre par statut) |
| GET | `/v1/trips/grouped` | Oui | Owner+Viewer | Trips groupes par statut (ongoing, planned, completed) |
| GET | `/v1/trips/{tripId}` | Oui | Owner+Viewer | Detail d'un trip avec flight order |
| GET | `/v1/trips/{tripId}/home` | Oui | Owner+Viewer | Page d'accueil d'un trip (stats, features, sections) |
| PATCH | `/v1/trips/{tripId}` | Oui | Owner | Mise a jour d'un trip |
| PATCH | `/v1/trips/{tripId}/status` | Oui | Owner | Changement de statut (avec validation de transition) |
| GET | `/v1/trips/{tripId}/weather` | Oui | Owner+Viewer | Meteo de la destination (Open-Meteo) |
| DELETE | `/v1/trips/{tripId}` | Oui | Owner | Suppression d'un trip |

Pagination : `?page=1&limit=20&status=ongoing|planned|completed`

## Activities (`/v1/trips/{tripId}/activities`)

Fichier : `api/src/api/activities/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/{tripId}/activities` | Oui | Owner | Creer une activite |
| GET | `/{tripId}/activities` | Oui | Owner+Viewer | Lister les activites (pagine) |
| GET | `/{tripId}/activities/{activityId}` | Oui | Owner+Viewer | Detail d'une activite |
| PUT | `/{tripId}/activities/{activityId}` | Oui | Owner | Mise a jour complete |
| PATCH | `/{tripId}/activities/{activityId}` | Oui | Owner | Mise a jour partielle |
| DELETE | `/{tripId}/activities/{activityId}` | Oui | Owner | Suppression |
| PATCH | `/{tripId}/activities/batch` | Oui | Owner | Batch update (validation_status, etc.) |
| POST | `/{tripId}/activities/suggest` | Oui | Owner (AI quota) | Suggestions IA d'activites |

Note : les viewers ne voient pas `estimatedCost`. Le suggest consomme un quota IA (guard `require_ai_quota`).

## Accommodations (`/v1/trips/{tripId}/accommodations`)

Fichier : `api/src/api/accommodations/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/{tripId}/accommodations` | Oui | Owner | Creer un hebergement |
| GET | `/{tripId}/accommodations` | Oui | Owner+Viewer | Lister les hebergements |
| PATCH | `/{tripId}/accommodations/{accommodationId}` | Oui | Owner | Mise a jour |
| DELETE | `/{tripId}/accommodations/{accommodationId}` | Oui | Owner | Suppression |

Note : viewers ne voient pas `pricePerNight`, `currency`, `bookingReference`.

## Baggage (`/v1/trips/{tripId}/baggage`)

Fichier : `api/src/api/baggage/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/{tripId}/baggage` | Oui | Owner | Creer un element de bagage |
| GET | `/{tripId}/baggage` | Oui | Owner+Viewer | Lister les bagages |
| PATCH | `/{tripId}/baggage/{baggageItemId}` | Oui | Owner | Mise a jour |
| DELETE | `/{tripId}/baggage/{baggageItemId}` | Oui | Owner | Suppression |
| POST | `/{tripId}/baggage/suggest` | Oui | Owner (AI quota) | Suggestions IA de bagages |

## Budget Items (`/v1/trips/{tripId}/budget-items`)

Fichier : `api/src/api/budget_items/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/{tripId}/budget-items` | Oui | Owner | Creer un poste de depense |
| GET | `/{tripId}/budget-items` | Oui | Owner+Viewer | Lister les postes (viewers: liste vide) |
| GET | `/{tripId}/budget-items/summary` | Oui | Owner+Viewer | Resume du budget (viewers: montants masques) |
| GET | `/{tripId}/budget-items/{itemId}` | Oui | Owner | Detail d'un poste (viewers: 403) |
| PUT | `/{tripId}/budget-items/{itemId}` | Oui | Owner | Mise a jour complete |
| DELETE | `/{tripId}/budget-items/{itemId}` | Oui | Owner | Suppression |

La creation/maj/suppression declenche `check_and_send_budget_alert()` (notification si seuil franchi).

## Travelers (`/v1/trips/{tripId}/travelers`)

Fichier : `api/src/api/travelers/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/{tripId}/travelers` | Oui | Owner | Creer un traveler (passager) |
| GET | `/{tripId}/travelers` | Oui | Owner+Viewer | Lister les travelers |
| PATCH | `/{tripId}/travelers/{travelerId}` | Oui | Owner | Mise a jour |
| DELETE | `/{tripId}/travelers/{travelerId}` | Oui | Owner | Suppression |

## Shares (`/v1/trips/{tripId}/shares`)

Fichier : `api/src/api/shares/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/{tripId}/shares` | Oui | Owner | Inviter un utilisateur par email |
| GET | `/{tripId}/shares` | Oui | Owner | Lister les partages |
| DELETE | `/{tripId}/shares/{shareId}` | Oui | Owner | Revoquer un partage |

## Feedback (`/v1/trips/{tripId}/feedback`)

Fichier : `api/src/api/feedback/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/{tripId}/feedback` | Oui | Owner+Viewer | Soumettre un feedback |
| GET | `/{tripId}/feedback` | Oui | Owner+Viewer | Lister les feedbacks |

## Flight Searches (`/v1/trips/{tripId}/flights/searches`)

Fichier : `api/src/api/flights/searches/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/{tripId}/flights/searches` | Oui | Owner | Lancer une recherche de vols (Amadeus) |
| GET | `/{tripId}/flights/searches/{searchId}` | Oui | Owner+Viewer | Detail d'une recherche + offres |

## Flight Offers (`/v1/trips/{tripId}/flights/offers`)

Fichier : `api/src/api/flights/offers/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| GET | `/{tripId}/flights/offers/{offerDbId}` | Oui | Owner+Viewer | Detail d'une offre de vol |
| POST | `/{tripId}/flights/offers/{offerDbId}/price` | Oui | Owner | Re-pricing (Amadeus Flight Price) |

## Flight Orders (`/v1/trips/{tripId}/flights/orders`)

Fichier : `api/src/api/flights/orders/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| GET | `/{tripId}/flights/orders` | Oui | Owner+Viewer | Lister les commandes de vol |
| GET | `/{tripId}/flights/orders/{orderId}` | Oui | Owner+Viewer | Detail d'une commande |
| DELETE | `/{tripId}/flights/orders/{orderId}` | Oui | Owner | Supprimer (interdit si CONFIRMED) |

## Manual Flights (`/v1/trips/{tripId}/flights/manual`)

Fichier : `api/src/api/flights/manual/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/{tripId}/flights/manual` | Oui | Owner | Creer un vol manuel |
| GET | `/{tripId}/flights/manual` | Oui | Owner+Viewer | Lister les vols manuels |
| GET | `/{tripId}/flights/manual/{flightId}` | Oui | Owner+Viewer | Detail d'un vol manuel |
| DELETE | `/{tripId}/flights/manual/{flightId}` | Oui | Owner | Supprimer un vol manuel |

## Flight Info (`/v1/travel/flights`)

Fichier : `api/src/api/flights/info/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| GET | `/v1/travel/flights/{flightNumber}/info` | Oui | Any | Infos temps reel d'un vol (AirLabs) |

## Booking Intents (`/v1/trips/{tripId}/booking-intents` et `/v1/booking-intents`)

Fichiers : `api/src/api/booking_intents/routes.py` et `book_routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/v1/trips/{tripId}/booking-intents` | Oui | Owner | Creer un intent de reservation |
| GET | `/v1/booking-intents/{intentId}` | Oui | Owner | Recuperer un intent par ID |
| POST | `/v1/booking-intents/{intentId}/book` | Oui | Owner | Executer la reservation (Amadeus Flight Order) |

## Payments (`/v1/booking-intents/{intentId}/payment`)

Fichier : `api/src/api/payments/routes.py`

| Methode | Path | Auth | Access | Description |
|---------|------|------|--------|-------------|
| POST | `/{intentId}/payment/authorize` | Oui | Owner | Creer un PaymentIntent Stripe (capture manuelle) |
| POST | `/{intentId}/payment/capture` | Oui | Owner | Capturer un PaymentIntent (apres booking) |
| POST | `/{intentId}/payment/cancel` | Oui | Owner | Annuler un PaymentIntent |
| POST | `/{intentId}/payment/confirm-test` | Oui | Owner | [TEST] Confirmer avec carte de test 4242 |

## Stripe Webhooks (`/v1/stripe`)

Fichier : `api/src/api/stripe/webhooks/routes.py`

| Methode | Path | Auth | Description |
|---------|------|------|-------------|
| POST | `/v1/stripe/webhooks` | Signature Stripe | Reception et traitement des evenements Stripe |

## Subscription (`/v1/subscription`)

Fichier : `api/src/api/subscription/routes.py`

| Methode | Path | Auth | Description |
|---------|------|------|-------------|
| POST | `/v1/subscription/checkout` | Oui | Creer une session Stripe Checkout (upgrade Premium) |
| POST | `/v1/subscription/portal` | Oui | Creer une session Stripe Billing Portal |
| GET | `/v1/subscription/status` | Oui | Statut de l'abonnement courant |

## Notifications (`/v1/notifications`)

Fichier : `api/src/api/notifications/routes.py`

| Methode | Path | Auth | Description |
|---------|------|------|-------------|
| GET | `/v1/notifications` | Oui | Liste paginee des notifications |
| GET | `/v1/notifications/unread-count` | Oui | Nombre de notifications non lues (badge) |
| PATCH | `/v1/notifications/{notificationId}/read` | Oui | Marquer une notification comme lue |
| POST | `/v1/notifications/read-all` | Oui | Marquer toutes les notifications comme lues |

## Device Tokens (`/v1/device-tokens`)

Fichier : `api/src/api/device_tokens/routes.py`

| Methode | Path | Auth | Description |
|---------|------|------|-------------|
| POST | `/v1/device-tokens` | Oui | Enregistrer un token FCM |
| DELETE | `/v1/device-tokens/{token}` | Oui | Supprimer un token FCM |

## Profile (`/v1/profile`)

Fichier : `api/src/api/profile/routes.py`

| Methode | Path | Auth | Description |
|---------|------|------|-------------|
| GET | `/v1/profile` | Oui | Recuperer le profil voyageur (cree si inexistant) |
| PUT | `/v1/profile` | Oui | Creer ou mettre a jour le profil voyageur |
| GET | `/v1/profile/completion` | Oui | Verifier la completion du profil |

## Travel / Amadeus (`/v1/travel`)

Fichier : `api/src/api/travel/routes.py`

| Methode | Path | Auth | Description |
|---------|------|------|-------------|
| GET | `/v1/travel/locations` | Non | Recherche de locations par mot-cle (Amadeus) |
| GET | `/v1/travel/locations/{id}` | Non | Detail d'une location par ID |
| GET | `/v1/travel/locations/nearest` | Non | Locations les plus proches (lat/lon) |
| GET | `/v1/travel/flight/offers` | Non | Recherche d'offres de vols |
| GET | `/v1/travel/flight/destinations` | Non | Destinations inspirantes |
| GET | `/v1/travel/flight/cheapest-dates` | Non | Dates les moins cheres |

## Hotel Search (`/v1/travel/hotels`)

Fichier : `api/src/api/hotels/routes.py`

| Methode | Path | Auth | Description |
|---------|------|------|-------------|
| GET | `/v1/travel/hotels/by-city` | Oui | Recherche d'hotels par ville (Amadeus) |
| GET | `/v1/travel/hotels/offers` | Oui | Offres d'hotels avec prix (Amadeus) |

## AI (`/v1/ai`)

Fichiers : `api/src/api/ai/plan_trip_routes.py`, `post_trip_routes.py`

| Methode | Path | Auth | Guard | Description |
|---------|------|------|-------|-------------|
| POST | `/v1/ai/plan-trip/stream` | Oui | AI quota | Stream SSE du pipeline de planification multi-agent |
| POST | `/v1/ai/plan-trip/accept` | Oui | - | Creer un trip DRAFT depuis le plan IA |
| POST | `/v1/ai/post-trip-suggestion` | Oui | AI quota + Premium | Suggestion de prochain voyage basee sur les feedbacks |

## Admin (`/admin`)

Fichier : `api/src/api/admin/routes.py`

Toutes les routes admin requierent `require_admin` (plan = ADMIN).

| Methode | Path | Description |
|---------|------|-------------|
| GET | `/admin/health` | Health check admin |
| GET | `/admin/users` | Lister tous les utilisateurs (pagine) |
| GET | `/admin/trips` | Lister tous les trips (pagine) |
| GET | `/admin/travelers` | Lister tous les travelers (pagine) |
| GET | `/admin/flight-bookings` | Lister toutes les reservations de vol |
| GET | `/admin/traveler-profiles` | Lister tous les profils voyageurs |
| GET | `/admin/booking-intents` | Lister tous les booking intents |
| GET | `/admin/flight-searches` | Lister toutes les recherches de vol |
| GET | `/admin/accommodations` | Lister tous les hebergements |
| GET | `/admin/activities` | Lister toutes les activites |
| GET | `/admin/budget-items` | Lister tous les postes de budget |
| GET | `/admin/baggage-items` | Lister tous les bagages |
| GET | `/admin/trip-shares` | Lister tous les partages |
| GET | `/admin/feedbacks` | Lister tous les feedbacks |
| GET | `/admin/notifications` | Lister toutes les notifications |
| DELETE | `/admin/feedbacks/{feedbackId}` | Supprimer un feedback |
| PATCH | `/admin/users/{userId}/plan` | Changer le plan d'un utilisateur |
| GET | `/admin/users/export` | Exporter les utilisateurs en CSV |
| GET | `/admin/dashboard/metrics` | Metriques KPI du dashboard |
| GET | `/admin/dashboard/metrics/users-chart` | Graphique d'inscriptions (week/month/year) |
| GET | `/admin/dashboard/metrics/revenue-chart` | Graphique de revenus (week/month/year) |
| GET | `/admin/dashboard/metrics/feedbacks-chart` | Distribution des feedbacks par note |
| POST | `/admin/notifications/send` | Envoyer une notification a des utilisateurs |

## Routes depreciees (`/v1/booking`)

Fichier : `api/src/api/booking/routes.py`

| Methode | Path | Description | Remplacement |
|---------|------|-------------|-------------|
| POST | `/v1/booking/pricing` | Confirmer le prix d'un vol | `/v1/trips/{tripId}/flights/offers/{offerDbId}/price` |
| POST | `/v1/booking/create` | Creer une reservation | `/v1/booking-intents/{intentId}/book` |
| GET | `/v1/booking/list` | Lister les reservations | `/v1/trips` |

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Routes travel sans authentification | Les routes `/v1/travel/locations`, `/flight/offers`, etc. ne requierent pas d'authentification. Fichier : `api/src/api/travel/routes.py` | P1 |
| Pagination manquante | `accommodations`, `baggage`, `shares`, `feedback`, `manual_flights` retournent toutes les entites sans pagination. Fichiers : routes respectives | P2 |
| Validation de schemas incomplete | Certains champs de creation de trip ne sont pas valides (ex: format de date `startDate`, `endDate` pas de validation ISO). Fichier : `api/src/api/trips/schemas.py` | P2 |
| Pas de route PATCH pour manual flights | Les vols manuels ne peuvent pas etre mis a jour, seulement crees/supprimes. Fichier : `api/src/api/flights/manual/routes.py` | P2 |
| Suppression des routes depreciees | 3 endpoints `/v1/booking/*` sont marques deprecated mais toujours actifs. Fichier : `api/src/api/booking/routes.py` | P2 |
| Documentation OpenAPI incomplete | Certaines routes n'ont pas de `summary`/`description` (ex: budget_items, activities). Fichiers : routes respectives | P2 |
