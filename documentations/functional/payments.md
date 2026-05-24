# Paiements et abonnements Stripe

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip integre Stripe sur deux axes distincts mais branches sur le meme `User.stripe_customer_id` :

- **Abonnement Premium** mensuel a 9.99 EUR via PaymentSheet natif (deferred IntentConfiguration), avec cycle de vie complet : checkout, gestion du moyen de paiement, annulation a la fin de periode, reactivation, listing des factures.
- **Paiement transactionnel d'un vol** via PaymentIntent en capture manuelle. Le client autorise le montant a la reservation, l'API capture une fois le booking Amadeus confirme, et peut rembourser tout ou partie de la charge.

La synchronisation entre Stripe et la base BagTrip passe exclusivement par les webhooks (verifies HMAC en prod, idempotents via `stripe_event_id` unique). Le `User.plan` (FREE / PREMIUM / ADMIN) gere par `PlanService` est la source du gating (quotas IA, viewers, post-trip, notifications offline). Cote mobile, l'integralite des flux 3DS / SCA reste in-app via `flutter_stripe` -- plus aucun hop par Stripe Checkout / Billing Portal sur le chemin nominal.

---

## Cote Backend

### Plans et gating (`api/src/config/plans.py`, `api/src/api/auth/plan_guard.py`)

`UserPlan` (StrEnum) : `FREE` / `PREMIUM` / `ADMIN`. La table `PLAN_LIMITS` definit pour chaque plan :

| Plan    | IA / mois | Viewers / trip | Notifs offline | Post-voyage IA |
|---------|-----------|----------------|----------------|----------------|
| FREE    | 3         | 2              | Non            | Non            |
| PREMIUM | Illimite  | 10             | Oui            | Oui            |
| ADMIN   | Illimite  | Illimite       | Oui            | Oui            |

Dependencies FastAPI :

- `require_ai_quota` : appele sur les routes IA. Reconcilie le plan local avec Stripe avant de checker le quota -- un freshly-subscribed user dont le webhook tarde n'est pas bloque.
- `require_premium` : 402 `UPGRADE_REQUIRED` si le plan reconcilie est FREE.

### Abonnement Premium (`api/src/api/subscription/routes.py`, `api/src/services/subscription_service.py`)

Prefixe `/v1/subscription`. Le path principal est le PaymentSheet natif ; Checkout / Billing Portal restent comme fallback web.

| Methode | Route                       | Description                                                                                          |
|---------|-----------------------------|------------------------------------------------------------------------------------------------------|
| POST    | `/start`                    | Bootstrap PaymentSheet : retourne `{customer, ephemeral_key, amount, currency}`. Aucun write Stripe. |
| POST    | `/confirm`                  | Cree la Subscription avec le `paymentMethodId` choisi. Retourne le `client_secret` pour 3DS in-line. |
| POST    | `/payment-method/setup`     | SetupIntent + ephemeral key pour changer de carte sans quitter l'app.                                |
| POST    | `/payment-method/attach`    | Attache le PM confirme comme `default_payment_method` de la Subscription + du Customer.              |
| POST    | `/checkout`                 | [Legacy] Stripe Checkout Session -- fallback web seulement.                                           |
| POST    | `/portal`                   | [Fallback] Billing Portal -- ouvert en in-app browser pour les cas non couverts par les flux natifs.  |
| GET     | `/status`                   | Plan + `stripe_subscription_id` + `plan_expires_at`. Reconcilie avec Stripe.                         |
| GET     | `/me`                       | Detail complet : `cancel_at_period_end`, `current_period_end`, `payment_method` (brand/last4/exp).   |
| POST    | `/cancel`                   | `cancel_at_period_end=true`. Premium garde jusqu'a `current_period_end`.                             |
| POST    | `/reactivate`               | Annule la planification de cancellation tant que la periode courante n'est pas terminee.             |
| GET     | `/invoices?limit=12`        | Liste paginee : `id`, `number`, `status`, `amount_paid`, `hosted_invoice_url`, `invoice_pdf`.        |

Points cles :

- **Auto-heal du Customer** : `_resolve_customer_id` retrieve le customer avant chaque mutation. Si Stripe renvoie `resource_missing` (suppression dashboard, switch de workspace), un nouveau Customer est cree + persiste avec une idempotency key randomisee.
- **Idempotency keys stables** sur `confirm` (`sub-{user_id}-confirm-{pm_id}-v1`), `cancel` (`sub-{user_id}-cancel-v1`), `reactivate`, `attach`. Un retry reseau ne duplique pas la Subscription.
- **Self-heal sur `/me`** : si `customer.subscription.created` est en retard, `get_subscription_details` interroge Stripe directement via le `stripe_subscription_id` persiste cote API au moment du confirm.
- **Garde `ALREADY_PREMIUM`** : `/start`, `/confirm` et `/checkout` refusent si `PlanService.get_plan(user) != FREE`.

### Paiement transactionnel vol (`api/src/api/payments/routes.py`, `api/src/services/stripe_payments_service.py`)

Prefixe `/v1/booking-intents`. Le BookingIntent doit etre cree au prealable via `POST /v1/trips/{tripId}/booking-intents` (`api/src/api/booking_intents/routes.py`).

| Methode | Route                                  | Description                                                                                      |
|---------|----------------------------------------|--------------------------------------------------------------------------------------------------|
| POST    | `/{intentId}/payment/authorize`        | Cree un PaymentIntent `capture_method=manual`. Retourne `clientSecret` pour le SDK mobile.        |
| POST    | `/{intentId}/payment/capture`          | Capture le PaymentIntent. Exige `BOOKED` en prod, `BOOKED` ou `AUTHORIZED` hors prod.            |
| POST    | `/{intentId}/payment/cancel`           | Annule le PaymentIntent. Refuse si deja `CAPTURED`. Best-effort cote Stripe, source de verite local. |
| POST    | `/{intentId}/payment/refund`           | Refund total ou partiel. Valide `amount` contre `charge.amount_captured - amount_refunded`.      |
| POST    | `/{intentId}/payment/confirm-test`     | [ADMIN only, bloque en prod] Confirme avec `pm_card_visa` pour le QA.                            |

Garanties :

- **Idempotency keys** : `bi-{intent_id}-{authorize|capture|cancel|refund-...}-v1` sur chaque call mutant.
- **Validation refund authoritative** : le service retrieve la `Charge` cote Stripe et calcule `remaining = max(0, amount_captured - amount_refunded)` avant d'autoriser. Bloque les double-refunds meme si le refund a ete declenche depuis le dashboard.
- **Metadata enrichies** : `booking_intent_id`, `trip_id`, `type`, `product_id`, et pour les vols : `flight_origin`, `flight_destination`, `flight_departure`, `flight_offer_id`, `amadeus_offer_id`.
- **State machine** : `INIT -> AUTHORIZED -> BOOKING_PENDING -> BOOKED -> CAPTURED -> REFUNDED`. Le passage `BOOKED -> CAPTURED` est declenche apres la commande Amadeus reussie (`BookingOrchestratorService.book` cree atomiquement le `FlightOrder` + `BudgetItem` via `unit_of_work`).

### Webhooks Stripe (`api/src/api/stripe/webhooks/routes.py`, `api/src/services/stripe_webhooks/`)

Endpoint : `POST /v1/stripe/webhooks`. Signature HMAC verifiee via `STRIPE_WEBHOOK_SECRET` (obligatoire en prod, raise au boot si absent). Dev escape hatch sans secret si `NODE_ENV != production`, avec WARN une fois par process.

Dispatch table dans `stripe_webhooks/service.py` :

| Evenement                                     | Handler                                  | Action                                                                                       |
|-----------------------------------------------|------------------------------------------|----------------------------------------------------------------------------------------------|
| `payment_intent.amount_capturable_updated`    | `payment.handle_amount_capturable_updated` | INIT -> AUTHORIZED                                                                           |
| `payment_intent.succeeded`                    | `payment.handle_payment_intent_succeeded`  | Safety net : BOOKED/AUTHORIZED -> CAPTURED, backfill `stripe_charge_id`                       |
| `payment_intent.canceled`                     | `payment.handle_payment_intent_canceled`   | -> CANCELLED (sauf CAPTURED)                                                                  |
| `payment_intent.payment_failed`               | `payment.handle_payment_intent_failed`     | -> FAILED + `last_error`                                                                      |
| `charge.refunded`                             | `charge.handle_charge_refunded`            | CAPTURED -> REFUNDED si refund total (capte aussi les refunds dashboard)                      |
| `charge.dispute.created`                      | `charge.handle_charge_dispute_created`     | Log ERROR, pas de state change auto (review humaine)                                         |
| `customer.subscription.created`               | `subscription.handle_subscription_created` | user.plan = PREMIUM, stocke `subscription_id` + `plan_expires_at`                            |
| `customer.subscription.updated`               | `subscription.handle_subscription_updated` | Refresh `plan_expires_at`. Si status in (`canceled`, `unpaid`, `incomplete_expired`) -> FREE |
| `customer.subscription.deleted`               | `subscription.handle_subscription_deleted` | user.plan = FREE, clear `subscription_id` et `plan_expires_at`                               |
| `invoice.payment_succeeded`                   | `invoice.handle_invoice_payment_succeeded` | Refresh `plan_expires_at` depuis `lines.data[].period.end`, force PREMIUM                    |
| `invoice.payment_failed`                      | `invoice.handle_invoice_payment_failed`    | Log WARN seulement (Stripe gere les dunning retries)                                         |

Idempotence : chaque evenement est insere dans `stripe_events` avec contrainte unique sur `stripe_event_id`. Les retries Stripe (replays dashboard, 5xx) court-circuitent en retournant la ligne existante. Les handlers qui throw sont catches : `processing_error` est persiste mais la requete renvoie 200 pour ne pas declencher de retry infini sur un bug applicatif. Les events `payment_intent.*` linkent automatiquement le `booking_intent_id` extrait des metadata.

Le plan ADMIN n'est jamais ecrase par un webhook : tous les handlers gardent `if user.plan != "ADMIN"`.

### Produits Stripe (`api/src/services/stripe_products_service.py`)

`StripeProductsService.initialize_products()` est appele au boot. Cherche par metadata `type` :

- `flight` : Product one-shot, prix variable (montant fourni au PaymentIntent).
- `premium_subscription` : Product + Price recurrent 999 cents EUR / mois. Le Price.id est le `premium_price_id` utilise par `/start` et `/confirm`.

Cache global `STRIPE_PRODUCT_IDS` lu via `get_product_id(type)`. Le mobile lit `amount` et `currency` depuis `/start` (Stripe Price.retrieve cote serveur), donc un changement de tarif backend se propage sans update app.

---

## Cote Mobile

### Subscription page (`bagtrip/lib/subscription/view/subscription_settings_page.dart`)

Page "Manage subscription" inspiree d'iOS Settings : un seul ecran qui change de body selon `details.isPremium`.

- **Body FREE** : PageView swipeable de 4 cards (IA, viewers, notifs offline, post-trip), prix, CTA unique qui lance `PremiumCheckout.run(context)`. Plus de paywall intermediaire.
- **Body PREMIUM** : badge statut, `_PaymentMethodCard` (brand + last4 + expiry), `_RenewalSummary` (renews on / expires on selon `cancelAtPeriodEnd`), trois `_ActionTile` : Update payment method (sheet native SetupIntent), View invoices, Cancel / Reactivate (ton destructive / primary selon l'etat).

Le `RefreshIndicator.adaptive` dispatche `RefreshSubscription` qui re-fetch `/subscription/me`.

### SubscriptionBloc (`bagtrip/lib/subscription/bloc/subscription_bloc.dart`)

App-level Bloc (`MultiBlocProvider` racine, a cote de `AuthBloc` et `HomeBloc`). Events :

- `LoadSubscription` / `RefreshSubscription` : fetch `/subscription/me`. Garde de regression : ne reflip pas un PREMIUM optimiste vers FREE si la reponse est en retard sur le webhook.
- `LoadInvoices(limit)` : populate `state.invoices` pour `InvoicesPage`.
- `CancelSubscription` / `ReactivateSubscription` : action + reload + `AuthBloc.add(UserRefreshRequested())` pour propager au gating.
- `OptimisticSubscriptionActivated` + `ConfirmSubscriptionActivation` : flip immediat vers PREMIUM apres PaymentSheet, puis poll `/subscription/me` a 500ms / 2s / 5s pour remplacer le stub par les vraies donnees Stripe (renewal date, payment method).

### PremiumCheckout (`bagtrip/lib/subscription/premium_checkout.dart`)

Fonction stateless `PremiumCheckout.run(context) -> Future<bool>`. Capture `messenger`, `authBloc`, `subscriptionBloc` AVANT le await pour survivre a la disposition du parent.

1. `repository.start()` -> `{customer, ephemeralKey, amount, currency}`.
2. `Stripe.instance.initPaymentSheet(IntentConfiguration(mode: paymentMode, ..., confirmHandler))`. Apple Pay conditionne par `AppConfig.appleMerchantIdentifier`, Google Pay sur EUR/FR.
3. `Stripe.instance.presentPaymentSheet()` (3DS / SCA in-line). Le `confirmHandler` appelle `_handleConfirm` qui POST `/subscription/confirm` et renvoie le `client_secret` via `Stripe.instance.intentCreationCallback`.
4. Sur succes : `OptimisticPremiumActivated` + `ConfirmPremiumActivation` sur AuthBloc, idem sur SubscriptionBloc, snackbar `premiumActivated`.
5. Sur `FailureCode.Canceled` : retourne `false` silencieusement. Sur autre erreur Stripe : snackbar rouge avec `localizedMessage`.

### Booking flow (`bagtrip/lib/booking/bloc/booking_bloc.dart`)

States : `BookingInitial`, `BookingLoading`, `PaymentAuthorizing`, `PaymentSheetReady(clientSecret, intentId)`, `PaymentSuccess`, `PaymentFailed`, `PaymentCancelled`, `RefundInProgress`, `RefundSucceeded`.

Sequence nominale :

1. `CreateBookingIntent(tripId, flightOfferId)` -> `POST /v1/trips/{tripId}/booking-intents` -> dispatch `AuthorizePayment(intentId)`.
2. `AuthorizePayment` -> `POST /payment/authorize` -> emit `PaymentSheetReady(clientSecret)`.
3. `PresentPaymentSheet(clientSecret, intentId)` -> `Stripe.instance.initPaymentSheet({paymentIntentClientSecret, returnURL: 'bagtrip://payment/result?intentId=<id>'})` + `presentPaymentSheet()`. Sur succes dispatch `CapturePayment`.
4. `CapturePayment` -> `POST /payment/capture` -> `PaymentSuccess` + `AuthBloc.add(UserRefreshRequested())`.
5. Retour 3DS deep-link `bagtrip://payment/result?intentId=<id>` -> `PaymentResultPage` dispatch `ConfirmPaymentFromDeepLink`. Le bloc valide que l'`intentId` matche le payment en cours pour eviter de capturer une reservation tierce.

Garde offline : `_offlineFailure()` renvoie un `PaymentFailed(NetworkError("connection_required"))` avant toute requete si `ConnectivityService.isOnline` est false.

`RefundPayment(intentId, amount?, reason?)` route vers `POST /payment/refund` avec un enum `RefundReason` (`duplicate`, `fraudulent`, `requestedByCustomer`) qui matche les valeurs autorisees backend.

---

## Flux

### Checkout abonnement (PaymentSheet natif)

```
Mobile                                        API                           Stripe
  |                                            |                              |
  |-- POST /subscription/start --------------->|                              |
  |                                            |-- Customer.retrieve -------->|
  |                                            |-- Price.retrieve ----------->|
  |                                            |-- EphemeralKey.create ------>|
  |<-- {customer, ephemeralKey, amount, currency}                             |
  |                                            |                              |
  |-- initPaymentSheet(IntentConfig deferred)  |                              |
  |-- presentPaymentSheet() -----[user taps Pay]-------                       |
  |   confirmHandler(paymentMethod)            |                              |
  |-- POST /subscription/confirm {pmId} ------>|                              |
  |                                            |-- PM.attach (idem key) ----->|
  |                                            |-- Subscription.create ------>|
  |                                            |    default_incomplete +      |
  |                                            |    default_payment_method    |
  |                                            |<-- sub + latest_invoice.PI --|
  |<-- {subscription_id, client_secret}--------|                              |
  |   intentCreationCallback(clientSecret)     |                              |
  |   SDK finalise paiement (3DS in-sheet)     |                              |
  |                                            |<-- webhook sub.created ------|
  |                                            |    user.plan = PREMIUM       |
  |                                            |<-- webhook invoice.paid -----|
  |                                            |    plan_expires_at refresh   |
  |   OptimisticSubscriptionActivated          |                              |
  |   + ConfirmSubscriptionActivation poll x3  |                              |
  |-- GET /subscription/me ------------------->|                              |
  |<-- payload reel (renewal, PM) -------------|                              |
```

### Achat vol avec 3DS

```
Mobile                                        API                  Stripe   Amadeus
  |                                            |                     |        |
  |-- POST /trips/{id}/booking-intents ------->|                     |        |
  |<-- BookingIntent(INIT) --------------------|                     |        |
  |-- POST /booking-intents/{id}/payment/authorize ------------------>        |
  |                                            |-- PI.create manual->|        |
  |<-- {clientSecret, status} -----------------|                     |        |
  |                                            |                     |        |
  |   initPaymentSheet(clientSecret, returnURL=bagtrip://payment/result?id)  |
  |   presentPaymentSheet() -> 3DS challenge bank                            |
  |                                            |<-- webhook amount_capturable |
  |                                            |    BookingIntent AUTHORIZED  |
  |   redirect bagtrip://payment/result?intentId=...                         |
  |   PaymentResultPage -> ConfirmPaymentFromDeepLink                       |
  |                                            |                     |        |
  |   (apres BOOKED par /book Amadeus)         |                     |        |
  |-- POST /booking-intents/{id}/book --------->|                     |        |
  |                                            |-- create_flight_order ------>|
  |                                            |<-- order_id --------|--------|
  |                                            |    unit_of_work : FlightOrder + BudgetItem |
  |<-- BookingIntent(BOOKED) ------------------|                     |        |
  |-- POST /payment/capture ------------------->|                     |        |
  |                                            |-- PI.capture ------>|        |
  |<-- BookingIntent(CAPTURED) ----------------|                     |        |
  |                                            |<-- webhook PI.succeeded (safety) |
```

### Reactivation apres cancel

```
Mobile                                        API                           Stripe
  |-- POST /subscription/cancel -------------->|                              |
  |                                            |-- Sub.modify cancel_at_period_end=true |
  |<-- {scheduled_for_cancellation, period_end}|                              |
  |                                            |<-- webhook sub.updated ------|
  |                                            |    plan_expires_at = period_end |
  |   ... user change d'avis avant period_end                                 |
  |-- POST /subscription/reactivate ---------->|                              |
  |                                            |-- Sub.modify cancel_at_period_end=false |
  |<-- {status=active, period_end} ------------|                              |
  |                                            |<-- webhook sub.updated ------|
```

---

## Ce qu'il manque

| Element                                                                                                                                                                              | Priorite |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| Pas de trial period sur Premium. `subscription.create` ne passe pas `trial_period_days` -- toute conversion FREE -> PREMIUM debite immediatement.                                     | P1       |
| Pas de plan annuel. Seul un Price mensuel EUR 999 est initialise. Pas d'upgrade / downgrade entre tiers.                                                                              | P2       |
| Pas de promo codes / coupons. `checkout.Session.create` n'expose pas `allow_promotion_codes`, et `/start` ne passe aucun coupon.                                                      | P2       |
| Multi-devise Premium absente. Le prix Premium est fixe en EUR ; les vols suivent la devise du `BookingIntent` mais l'abonnement non.                                                  | P2       |
| Pas de gestion explicite des disputes (`charge.dispute.created` log mais ne suspend pas l'utilisateur). Une chargeback frauduleuse laisse le compte en PREMIUM.                       | P1       |
| Tests backend payments / webhooks partiels. `tests/services/stripe_webhooks/` couvre les handlers principaux, mais pas tous les chemins refund (over-refund, dashboard refund).      | P1       |
| Tests Flutter PaymentSheet absents. Pas d'integration test sur `PremiumCheckout.run` (flutter_stripe mocke mal). Couverture limitee a `subscription_bloc_test.dart`.                  | P1       |
| Resilience polling `ConfirmSubscriptionActivation` limitee. Si le webhook depasse 7.5s (500ms + 2s + 5s), le stub optimiste reste sans refresh ulterieur -- l'utilisateur doit pull-to-refresh. | P2       |
| Pas de receipt / facture telechargeable cote mobile au-dela des liens Stripe (`hosted_invoice_url`, `invoice_pdf`). Pas de cache local.                                              | P2       |
| Pas de regeneration automatique du Customer lors d'un changement de cle Stripe en prod -- `_resolve_customer_id` couvre le cas, mais aucune metric / alerting si ca se declenche.    | P2       |
| Webhook `checkout.session.completed` non traite. Le flow legacy `/checkout` repose donc uniquement sur les events `customer.subscription.*` pour activer le plan.                     | P2       |
