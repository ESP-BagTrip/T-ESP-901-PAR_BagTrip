# Paiements et abonnements Stripe

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

BagTrip integre Stripe pour deux cas d'usage distincts : les **paiements transactionnels** (reservations de vols via PaymentIntent en capture manuelle) et les **abonnements Premium** (via Stripe Checkout + webhooks). L'architecture repose sur un client Stripe centralise cote API, un service de gestion des produits/prix, un service de webhooks pour la synchronisation asynchrone, et des pages de resultat cote mobile. Le plan utilisateur (FREE / PREMIUM / ADMIN) determine les limites fonctionnelles de l'application.

---

## Plans et limites

### Configuration des plans (`api/src/config/plans.py`)

Trois plans definis via l'enum `UserPlan` :

| Plan | Generations IA / mois | Viewers par trip | Notifications offline | Post-voyage IA |
|------|----------------------|------------------|-----------------------|----------------|
| FREE | 3 | 2 | Non | Non |
| PREMIUM | Illimite | 10 | Oui | Oui |
| ADMIN | Illimite | Illimite | Oui | Oui |

### PlanService (`api/src/services/plan_service.py`)

Service stateless qui fournit :
- `get_plan(user)` : retourne le `UserPlan` (fallback FREE si invalide)
- `get_limits(user)` : retourne le dictionnaire de limites pour le plan
- `check_ai_generation_quota(db, user)` : leve `AppError("AI_QUOTA_EXCEEDED", 402)` si le quota mensuel est atteint. Reset automatique du compteur au changement de mois.
- `increment_ai_generation(db, user)` : incremente le compteur
- `can_access_feature(user, feature)` : gate generique par feature
- `get_plan_info(db, user)` : retourne plan + limites + usage courant pour les reponses API

Le quota IA est stocke directement sur le modele User : `ai_generations_count` et `ai_generations_reset_at`.

---

## Cote Backend (API FastAPI)

### Client Stripe (`api/src/integrations/stripe/client.py`)

Wrapper statique autour du SDK Stripe Python :
- `create_customer(email, name?)` : creation client Stripe
- `create_payment_intent(amount, currency, metadata?, capture_method?, customer?, description?)` : creation PaymentIntent (defaut capture manuelle)
- `capture_payment_intent(payment_intent_id)` : capture
- `cancel_payment_intent(payment_intent_id)` : annulation
- `retrieve_payment_intent(payment_intent_id)` : recuperation

La cle API est initialisee au demarrage depuis `settings.STRIPE_SECRET_KEY`.

### Gestion des produits Stripe (`api/src/services/stripe_products_service.py`)

Le service `StripeProductsService` initialise les produits Stripe au demarrage de l'API :

| Produit | Type | Prix |
|---------|------|------|
| Flight Booking | one-time (PaymentIntent) | Variable selon l'offre |
| BagTrip Premium | subscription (recurring) | 9.99 EUR/mois |

Fonctionnement :
- `initialize_products()` : cherche les produits existants par metadata `type`, les cree si inexistants. Pour Premium, cree aussi un `Price` recurrent (mensuel, 999 centimes EUR).
- Les IDs sont caches dans le dictionnaire global `STRIPE_PRODUCT_IDS`.
- `get_product_id(product_type)` : lecture du cache.

### Endpoints paiements transactionnels

Prefixe `/v1/booking-intents` (fichier `api/src/api/payments/routes.py`).

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/{intentId}/payment/authorize` | Cree un PaymentIntent Stripe en capture manuelle. Retourne `clientSecret` pour le SDK mobile. |
| POST | `/{intentId}/payment/capture` | Capture un paiement autorise (statut BOOKED ou AUTHORIZED en POC). |
| POST | `/{intentId}/payment/cancel` | Annule un PaymentIntent. Refuse si deja capture. |
| POST | `/{intentId}/payment/confirm-test` | [TEST/POC] Confirme un paiement avec la carte test `pm_card_visa`. |

### Schemas paiements (`api/src/api/payments/schemas.py`)

- **PaymentAuthorizeRequest** : `returnUrl?`
- **PaymentAuthorizeResponse** : `stripePaymentIntentId`, `clientSecret`, `status`
- **PaymentCaptureResponse** : `bookingIntent` (dict), `stripe` (dict avec `paymentIntentId`)
- **PaymentCancelResponse** : `bookingIntent` (dict)

### StripePaymentsService (`api/src/services/stripe_payments_service.py`)

Service pour les operations de paiement :

**create_manual_capture_payment_intent** :
1. Verifie que le `BookingIntent` existe, appartient a l'utilisateur, et est en statut `INIT`
2. Verifie que l'utilisateur a un `stripe_customer_id`
3. Convertit le montant en centimes
4. Recupere le `product_id` Stripe via `StripeProductsService`
5. Enrichit les metadata avec les details de l'offre (vol: origin, destination, date, airline)
6. Cree le PaymentIntent avec `capture_method="manual"`
7. Stocke le `stripe_payment_intent_id` sur le BookingIntent

**capture_payment** :
1. Verifie le statut BOOKED ou AUTHORIZED (POC)
2. Appelle `StripeClient.capture_payment_intent`
3. Met a jour le statut en CAPTURED et stocke le `stripe_charge_id`

**cancel_payment** :
1. Refuse si le statut est CAPTURED
2. Appelle `StripeClient.cancel_payment_intent` (erreurs supprimees)
3. Met a jour le statut en CANCELLED

**confirm_payment_with_test_card** :
- Endpoint POC uniquement
- Confirme le PaymentIntent avec `pm_card_visa` et `return_url=bagtrip://payment/result`
- Met a jour en AUTHORIZED si le statut Stripe est `requires_capture`

### Endpoints abonnement

Prefixe `/v1/subscription` (fichier `api/src/api/subscription/routes.py`).

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/checkout` | Cree une Stripe Checkout Session pour l'abonnement Premium. |
| POST | `/portal` | Cree une session Stripe Billing Portal pour gerer l'abonnement. |
| GET | `/status` | Retourne le statut de l'abonnement courant. |

### SubscriptionService (`api/src/services/subscription_service.py`)

**create_checkout_session** :
1. Verifie que Stripe est configure
2. Verifie que l'utilisateur est en plan FREE (refuse si deja premium)
3. Verifie la presence du `stripe_customer_id`
4. Cree une `stripe.checkout.Session` en mode `subscription` avec le `premium_price_id`
5. URLs de redirection : `bagtrip://subscription/success?session-id={CHECKOUT_SESSION_ID}` et `bagtrip://subscription/cancel`
6. Retourne `{ url: session.url }`

**create_portal_session** :
- Cree une session Billing Portal avec `return_url=bagtrip://profile`
- Permet a l'utilisateur de gerer/annuler son abonnement

**get_status** :
- Retourne les infos de plan + `stripe_subscription_id` + `plan_expires_at`

### Webhooks Stripe (`api/src/api/stripe/webhooks/routes.py`)

Endpoint : `POST /v1/stripe/webhooks`

1. Recoit le body brut + header `stripe-signature`
2. Verifie la signature avec `STRIPE_WEBHOOK_SECRET` (bypass en dev si non configure)
3. Delegue au `StripeWebhooksService.process_event`

### StripeWebhooksService (`api/src/services/stripe_webhooks_service.py`)

**Idempotence** : chaque evenement est stocke dans la table `stripe_events` avec son `stripe_event_id` unique. Si l'evenement a deja ete traite, il est retourne directement sans re-traitement.

**Evenements traites** :

| Evenement Stripe | Action |
|------------------|--------|
| `payment_intent.amount_capturable_updated` | Met a jour le BookingIntent en AUTHORIZED si en INIT |
| `payment_intent.canceled` | Met a jour le BookingIntent en CANCELLED (sauf si CAPTURED) |
| `payment_intent.payment_failed` | Met a jour le BookingIntent en FAILED avec `last_error` |
| `customer.subscription.created` | Set `user.plan = "PREMIUM"`, stocke `subscription_id` et `period_end` |
| `customer.subscription.updated` | Met a jour `plan_expires_at`. Si statut canceled/unpaid/incomplete_expired -> plan FREE |
| `customer.subscription.deleted` | Set `user.plan = "FREE"`, clear `subscription_id` et `plan_expires_at` |
| `invoice.payment_succeeded` | Set `user.plan = "PREMIUM"` (sauf ADMIN), met a jour `plan_expires_at` depuis la periode de facturation |

La resolution de l'utilisateur se fait via `stripe_customer_id` sur le champ `customer` de l'evenement Stripe.

### Modele StripeEvent (`api/src/models/stripe_event.py`)

Table `stripe_events` : `id` (UUID), `stripe_event_id` (unique), `type`, `livemode`, `payload` (JSON), `received_at`, `booking_intent_id?` (FK), `processed_at?`, `processing_error?` (JSON).

---

## Cote Mobile (Flutter)

### Pages de resultat paiement

Trois pages statiques pour les retours de paiement 3DS (deep links) :

- **PaymentResultPage** (`bagtrip/lib/pages/payment/payment_result_page.dart`) : page generique de retour 3DS avec icone de paiement et bouton "Retour aux trips". Route vers `HomeRoute`.
- **PaymentSuccessPage** (`bagtrip/lib/pages/payment/payment_success_page.dart`) : page de succes avec icone check verte et message de confirmation.
- **PaymentCancelPage** (`bagtrip/lib/pages/payment/payment_cancel_page.dart`) : page d'annulation avec icone warning et bouton `context.pop()`.

Toutes utilisent le gradient `PersonalizationColors.backgroundGradient` et les textes l10n.

### Pages de resultat abonnement

- **SubscriptionSuccessPage** (`bagtrip/lib/pages/subscription/subscription_success_page.dart`) :
  - Recoit un `sessionId` optionnel
  - Poll le statut de l'abonnement jusqu'a 5 fois (toutes les 2 secondes) via `SubscriptionRepository.getStatus()`
  - Affiche un spinner pendant la verification, puis un message de succes (Premium confirme) ou un message "en attente" (webhook pas encore recu)
  - Bouton "Continuer" navigue vers `ProfileRoute`

- **SubscriptionCancelPage** (`bagtrip/lib/pages/subscription/subscription_cancel_page.dart`) :
  - Affiche un message d'annulation
  - Bouton "Reessayer" relance le flow checkout via `SubscriptionRepository.getCheckoutUrl()` puis `launchUrl` en mode externe
  - Bouton secondaire "Retour au profil" navigue vers `ProfileRoute`

### SubscriptionRepository (`bagtrip/lib/repositories/subscription_repository.dart`)

Interface abstraite :
- `getCheckoutUrl()` -> `Result<String>` : recupere l'URL de la session Checkout
- `getPortalUrl()` -> `Result<String>` : recupere l'URL du Billing Portal
- `getStatus()` -> `Result<Map<String, dynamic>>` : recupere le statut de l'abonnement

### Modele User cote mobile

Le modele `User` Freezed (`bagtrip/lib/models/user.dart`) inclut :
- `plan` (defaut: 'FREE')
- `aiGenerationsRemaining?`
- `planExpiresAt?`
- Proprietes calculees : `isFree`, `isPremium` (PREMIUM ou ADMIN), `isAdmin`

---

## Flux de paiement transactionnel (reservations)

```
Mobile                                        API                           Stripe
  |                                            |                              |
  |-- POST /{intentId}/payment/authorize ----->|                              |
  |                                            |-- create_payment_intent ---->|
  |                                            |<-- PaymentIntent (manual) ---|
  |<-- { clientSecret, status } --------------|                              |
  |                                            |                              |
  |-- Stripe SDK / 3DS confirmation ---------->|                              |
  |                                            |<-- webhook: amount_capt... --|
  |                                            |   -> BookingIntent AUTHORIZED|
  |                                            |                              |
  |-- POST /{intentId}/payment/capture ------>|                              |
  |                                            |-- capture_payment_intent --->|
  |                                            |<-- PaymentIntent captured ---|
  |                                            |   -> BookingIntent CAPTURED  |
  |<-- { bookingIntent, stripe } -------------|                              |
```

### Machine a etats BookingIntent

```
INIT -> AUTHORIZED -> BOOKED -> CAPTURED
  |        |                       ^
  |        +---- (POC shortcut) ---+
  |        |
  +--------+-> CANCELLED
  |
  +-> FAILED
```

---

## Flux d'abonnement Premium

```
Mobile                                        API                           Stripe
  |                                            |                              |
  |-- POST /subscription/checkout ----------->|                              |
  |                                            |-- checkout.Session.create -->|
  |                                            |<-- { url } -----------------|
  |<-- { url } -------------------------------|                              |
  |                                            |                              |
  |-- launchUrl(url) --> navigateur externe -->|                              |
  |                                            |                              |
  |   (utilisateur complete le paiement)       |                              |
  |                                            |<-- webhook: sub.created -----|
  |                                            |   -> user.plan = PREMIUM     |
  |                                            |                              |
  |<-- deep link: bagtrip://subscription/success                              |
  |                                            |                              |
  |-- GET /subscription/status (poll x5) ---->|                              |
  |<-- { plan: "PREMIUM" } -------------------|                              |
  |                                            |                              |
  |   Affiche "Bienvenue Premium!"            |                              |
```

### URLs de redirection Stripe

Configurees dans `api/src/config/env.py` :
- **Succes** : `bagtrip://subscription/success?session-id={CHECKOUT_SESSION_ID}`
- **Annulation** : `bagtrip://subscription/cancel`
- **Retour portal** : `bagtrip://profile`

---

## Creation du client Stripe a l'inscription

A l'inscription (email ou OAuth), l'API cree automatiquement un client Stripe :
- `StripeClient.create_customer(email, name?)` est appele dans les routes `/register`, `/google`, `/apple` (`api/src/api/auth/routes.py`)
- Le `stripe_customer_id` est stocke sur le modele User
- En cas d'echec de creation Stripe, l'inscription continue (best effort, erreur loguee)

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Pas de BLoC pour les paiements transactionnels | Les pages de paiement (`payment_result_page.dart`, `payment_success_page.dart`, `payment_cancel_page.dart`) sont des pages statiques sans BLoC. Aucune logique de verification du statut du paiement apres retour 3DS, contrairement a la `SubscriptionSuccessPage` qui fait du polling. | P0 |
| Pas de Stripe SDK cote mobile | Aucune integration du SDK Stripe Flutter (stripe_flutter) n'est visible dans le code explore. Le `clientSecret` retourne par `/authorize` n'est pas utilise dans un PaymentSheet ou CardField. Le flow 3DS semble reposer sur des deep links sans gestion native. | P0 |
| Endpoint confirm-test en production | L'endpoint `/payment/confirm-test` utilise `pm_card_visa` en dur et n'a aucun guard pour empecher son utilisation en production (`stripe_payments_service.py` ligne 221). | P0 |
| Pas de refund | Aucun endpoint ni service pour les remboursements Stripe. | P1 |
| Pas de gestion des erreurs de paiement cote mobile | Les pages de resultat sont des vues statiques sans retry ni affichage d'erreur detaillee. | P1 |
| Webhook `checkout.session.completed` non traite | Le `StripeWebhooksService` ne traite pas `checkout.session.completed`. La mise a jour du plan depend uniquement des evenements `customer.subscription.*` et `invoice.payment_succeeded`. En theorie suffisant, mais le checkout session ID passe dans l'URL de retour n'est jamais verifie. | P2 |
| Tests backend paiements/subscriptions absents | Aucun fichier de test dans `api/tests/` pour les routes de paiement, subscription ou webhooks. | P1 |
| Tests Flutter subscription partiels | `bagtrip/test/service/subscription_service_test.dart` et `bagtrip/test/models/payment_card_test.dart` existent mais pas de test d'integration pour le flow complet. Aucun test pour les pages de resultat. | P1 |
| Pas d'essai gratuit (trial) | Le checkout Stripe ne configure pas de `trial_period_days`. Pas de notion de periode d'essai dans le code. | P2 |
| Pas de gestion multi-devise | Le prix Premium est fixe en EUR (999 centimes). Les paiements transactionnels utilisent la devise du `BookingIntent`, mais le Premium est EUR uniquement. | P2 |
| Pas de receipts / factures | Aucune fonctionnalite d'historique de paiement ou d'affichage de factures Stripe cote mobile. | P2 |
| Resilience du polling subscription | Le polling dans `SubscriptionSuccessPage` fait 5 tentatives avec 2s d'intervalle. Si le webhook Stripe est en retard (>10s), l'utilisateur voit "en attente" sans possibilite de retry. | P2 |
| Pas de plan annuel | Seul un prix mensuel (9.99 EUR/mois) est configure. Pas d'option annuelle avec remise. | P2 |
