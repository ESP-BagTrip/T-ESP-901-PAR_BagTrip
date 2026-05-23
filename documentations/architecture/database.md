# Base de donnees

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip persiste tout son etat metier dans **PostgreSQL 15**. L'ORM est **SQLAlchemy 2.0** en mode typed declarative (`Mapped[T]` + `mapped_column`), ce qui donne un typage mypy strict de bout en bout (plus aucun `Column[UUID]` legacy dans `src/models/`). Les migrations sont gerees par **Alembic** ; le schema n'est jamais cree via `Base.metadata.create_all()` au boot -- seul `alembic upgrade head` fait foi.

Stack DB cote API :

- Driver : `psycopg2-binary`
- ORM : SQLAlchemy 2.0 (`declarative_base()` expose par `src/config/database.py`)
- Migrations : Alembic, repertoire `api/alembic/versions/`
- Types Postgres natifs utilises : `UUID(as_uuid=True)`, `JSON`, `JSONB`, `Numeric(precision, scale)`, `DateTime(timezone=True)`, `Date`, `Time`
- Toutes les PK sont des UUID v4 (`default=uuid.uuid4`)
- `created_at` / `updated_at` partout : `server_default=func.now()` + `onupdate=func.now()` cote SQLAlchemy

Le fichier `src/config/database.py` expose `engine`, `SessionLocal`, `Base`, `check_database_connection()` et la dependency `get_db()` qui yield une session FastAPI. La fonction utilitaire `clean_database_url()` retire le parametre `?schema=` herite de Prisma avant de passer l'URL a psycopg2.

URL par defaut (settings `DATABASE_URL`) :

- Local : `postgresql://postgres:postgres@localhost:5432/postgres`
- Docker compose : `postgresql://postgres:postgres@db:5432/bagtrip`

## Schema

Les sections ci-dessous decrivent les 22 modeles ORM presents dans `src/models/`. Chaque colonne porte son type SQLAlchemy, ses contraintes principales et une note quand le contexte metier l'exige.

### User (`users`)

Compte utilisateur. Single source of truth pour l'auth, le plan tarifaire et les quotas IA.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK, default uuid4 | |
| email | String | UNIQUE, NOT NULL, INDEX | |
| password_hash | String | NOT NULL | bcrypt cost >= 12 |
| full_name | String | nullable | |
| phone | String | nullable | |
| stripe_customer_id | String | nullable, INDEX | cree au register |
| plan | String(10) | NOT NULL, default "FREE" | FREE / PREMIUM / ADMIN |
| stripe_subscription_id | String | nullable, INDEX | |
| plan_expires_at | DateTime(tz) | nullable | downgrade auto via `plan_expiration_job` |
| ai_generations_count | Integer | NOT NULL, default 0 | quota IA mois courant |
| ai_generations_reset_at | DateTime(tz) | nullable | rolling window 30j |
| password_reset_token | String | nullable | sha256 hashe, jamais le clair |
| password_reset_expires | DateTime(tz) | nullable | |
| banned_at | DateTime(tz) | nullable | soft-ban admin |
| ban_reason | String | nullable | |
| deleted_at | DateTime(tz) | nullable | soft-delete RGPD |
| created_at / updated_at | DateTime(tz) | server_default now() | |

### Trip (`trips`)

Voyage cree par un utilisateur. Hub central -- referencee par 11 tables filles.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | FK users.id, NOT NULL, INDEX | owner |
| title | String | nullable | |
| origin_iata | String(3) | nullable | code aeroport IATA |
| destination_iata | String(3) | nullable | |
| destination_name | String | nullable | libelle humain |
| destination_timezone | String | nullable | IANA tz, ajoute migr 0023 |
| start_date / end_date | Date | nullable | |
| status | String | NOT NULL, default "DRAFT" | DRAFT / PLANNED / ONGOING / COMPLETED |
| description | String | nullable | |
| budget_target | Numeric(12,2) | nullable | objectif utilisateur (migr 0029) |
| budget_estimated | Numeric(12,2) | nullable | sortie agent IA |
| budget_actual | Numeric(12,2) | nullable | reserve future |
| currency | String(3) | NOT NULL, default "EUR" | devise canonique (migr 0030) |
| origin | String | nullable, default "MANUAL" | AI / MANUAL |
| cover_image_url | String | nullable | Unsplash cache |
| nb_travelers | Integer | nullable, default 1 | |
| date_mode | String | NOT NULL, default "EXACT" | EXACT / MONTH / FLEXIBLE |
| flights_tracking | String | NOT NULL, default "TRACKED" | TRACKED / NOT_TRACKED |
| accommodations_tracking | String | NOT NULL, default "TRACKED" | idem |
| archived_at | DateTime(tz) | nullable | soft-delete trip |
| created_at / updated_at | DateTime(tz) | server_default now() | |

Toutes les relations enfant utilisent `cascade="all, delete-orphan"` : suppression d'un trip = suppression des activites, hebergements, bagages, partages, vols manuels, budget items, feedbacks, etc.

### Activity (`activities`)

Activite planifiee dans un trip. Peut etre datee ou non (les recommandations IA MEAL / TRANSPORT n'ont pas de slot calendrier depuis SMP-324).

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| title | String | NOT NULL | |
| description | String | nullable | |
| date | Date | nullable | nullable depuis migr 0032 |
| start_time / end_time | Time | nullable | |
| location | String | nullable | |
| category | String | NOT NULL, default "OTHER" | CULTURE / NATURE / FOOD / SPORT / SHOPPING / NIGHTLIFE / RELAXATION / OTHER |
| estimated_cost | Numeric(12,2) | nullable | |
| is_booked | Boolean | NOT NULL, default false | |
| is_done | Boolean | NOT NULL, default false | check par l'utilisateur en cours de trip |
| validation_status | String | NOT NULL, default "MANUAL" | SUGGESTED / VALIDATED / MANUAL |
| created_at / updated_at | DateTime(tz) | server_default now() | |

### Accommodation (`accommodations`)

Hebergement reserve ou planifie. `check_in` / `check_out` sont passes de `Date` a `DateTime(tz)` en migration 0021 pour porter l'heure d'arrivee.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| name | String | NOT NULL | |
| address | String | nullable | |
| check_in / check_out | DateTime(tz) | nullable | |
| price_per_night | Numeric(12,2) | nullable | |
| currency | String(3) | nullable, default "EUR" | |
| booking_reference | String | nullable | |
| notes | String | nullable | |
| validation_status | String | NOT NULL, default "MANUAL" | meme enum que Activity |
| created_at / updated_at | DateTime(tz) | server_default now() | |

### BaggageItem (`baggage_items`)

Element de checklist bagages.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| name | String | NOT NULL | |
| quantity | Integer | NOT NULL, default 1 | |
| is_packed | Boolean | NOT NULL, default false | |
| category | String | NOT NULL, default "OTHER" | DOCUMENTS / CLOTHING / ELECTRONICS / TOILETRIES / HEALTH / ACCESSORIES / OTHER |
| notes | String | nullable | |
| created_at / updated_at | DateTime(tz) | server_default now() | |

### BudgetItem (`budget_items`)

Ligne de budget (plan ou depense reelle). Peut etre liee a une autre entite metier (hebergement, vol) via le couple `source_type` / `source_id`.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| label | String | NOT NULL | |
| amount | Numeric(12,2) | NOT NULL | dans `currency` |
| currency | String(3) | NOT NULL, default "EUR" | convertie a l'aggregation (migr 0030) |
| category | String | NOT NULL, default "OTHER" | FLIGHT / ACCOMMODATION / FOOD / ACTIVITY / TRANSPORT / OTHER |
| date | Date | nullable | |
| is_planned | Boolean | NOT NULL, default true | |
| source_type | String | nullable | "accommodation" / "flight_order" / null |
| source_id | UUID | nullable | id de l'entite source |
| validation_status | String | NOT NULL, default "MANUAL" | meme enum (migr 0033) |
| created_at / updated_at | DateTime(tz) | server_default now() | |

Index composite : `ix_budget_items_source (source_type, source_id)`.

### TripTraveler (`trip_travelers`)

Voyageur associe a un trip pour la reservation Amadeus (un passager = une ligne).

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| amadeus_traveler_ref | String | nullable | id renvoye par Amadeus apres pricing |
| traveler_type | String | NOT NULL | ADULT / CHILD / INFANT |
| first_name / last_name | String | NOT NULL | |
| date_of_birth | Date | nullable | requis pour CHILD/INFANT |
| gender | String | nullable | MALE / FEMALE / OTHER |
| documents | JSON | nullable | passeport, identite |
| contacts | JSON | nullable | tel, email |
| raw | JSON | nullable | payload Amadeus complet |
| created_at / updated_at | DateTime(tz) | server_default now() | |

### TripShare (`trip_shares`)

Partage d'un trip avec un autre utilisateur inscrit. Pour les invitations vers des emails non inscrits, voir `PendingInvite`.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| user_id | UUID | FK users.id, NOT NULL, INDEX | invite |
| role | String | NOT NULL, default "VIEWER" | seul VIEWER aujourd'hui |
| invited_at | DateTime(tz) | server_default now() | |

Contrainte unique : `uq_trip_shares_trip_user (trip_id, user_id)` -- pas de doublon.

### Notification (`notifications`)

Notification push persistee cote serveur (le client n'a qu'une copie en cache). `data` est en `JSONB` pour query indexable (migr 0036 -- payload i18n).

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | FK users.id, NOT NULL, INDEX | |
| trip_id | UUID | FK trips.id, nullable, INDEX | nullable pour ADMIN broadcast |
| type | String | NOT NULL | enum NotificationType |
| title | String | NOT NULL | titre localise serveur-side |
| body | String | NOT NULL | corps localise serveur-side |
| data | JSONB | nullable | i18n keys + placeholders + deeplink |
| is_read | Boolean | NOT NULL, default false | |
| sent_at | DateTime(tz) | nullable | timestamp FCM ack |
| created_at | DateTime(tz) | server_default now() | |

Types : DEPARTURE_REMINDER, FLIGHT_H4, FLIGHT_H1, MORNING_SUMMARY, ACTIVITY_H1, TRIP_STARTED, TRIP_ENDED, BUDGET_ALERT, TRIP_SHARED, ADMIN.

### RefreshToken (`refresh_tokens`)

JWT refresh tokens stockes server-side pour permettre la rotation et la detection de reuse.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | FK users.id, NOT NULL, INDEX | |
| token | String | UNIQUE, NOT NULL, INDEX | sha256 hashe, jamais le JWT raw |
| expires_at | DateTime(tz) | NOT NULL | |
| revoked | Boolean | NOT NULL, default false | flip a true sur rotation |
| created_at | DateTime(tz) | server_default now() | |

### Feedback (`feedbacks`)

Avis utilisateur post-trip. Un seul feedback par couple (trip, user).

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| user_id | UUID | FK users.id, NOT NULL, INDEX | |
| overall_rating | Integer | NOT NULL | 1-5 |
| highlights | Text | nullable | |
| lowlights | Text | nullable | |
| would_recommend | Boolean | NOT NULL | |
| ai_experience_rating | Integer | nullable | 1-5, ajoute migr 0020 |
| created_at | DateTime(tz) | server_default now() | |

Contrainte unique : `uq_feedbacks_trip_user (trip_id, user_id)`.

### FlightSearch (`flight_searches`)

Recherche de vols Amadeus persistee (cache + audit). Une ligne = un appel `GET /shopping/flight-offers`.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| origin_iata / destination_iata | String(3) | NOT NULL | |
| departure_date | Date | NOT NULL | |
| return_date | Date | nullable | one-way si null |
| adults | Integer | NOT NULL | |
| children / infants | Integer | nullable | |
| travel_class | String | nullable | ECONOMY / BUSINESS / FIRST |
| non_stop | Boolean | nullable | |
| currency | String(3) | nullable | |
| amadeus_request | JSON | NOT NULL | payload sortant |
| amadeus_response | JSON | nullable | payload entrant complet |
| amadeus_response_received_at | DateTime(tz) | nullable | |
| created_at | DateTime(tz) | server_default now() | |

### FlightOffer (`flight_offers`)

Offre individuelle issue d'une `FlightSearch`. Une recherche = N offres.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| flight_search_id | UUID | FK flight_searches.id, NOT NULL, INDEX | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | denormalise pour query rapide |
| amadeus_offer_id | String | nullable | id natif Amadeus |
| source | String | nullable | GDS / NDC |
| validating_airline_codes | String | nullable | CSV |
| last_ticketing_datetime | DateTime(tz) | nullable | deadline d'achat |
| currency | String(3) | nullable | |
| grand_total / base_total | Numeric(10,2) | nullable | TTC / HT |
| offer_json | JSON | NOT NULL | offre complete Amadeus |
| priced_offer_json | JSON | nullable | apres reprice avant booking |
| created_at | DateTime(tz) | server_default now() | |

### FlightOrder (`flight_orders`)

Commande de vol confirmee (booking Amadeus). Liee a une offer et eventuellement a un BookingIntent (paiement Stripe).

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| flight_offer_id | UUID | FK flight_offers.id, NOT NULL | non-indexe (TODO) |
| booking_intent_id | UUID | FK booking_intents.id, nullable, UNIQUE | 1:1 quand paye Stripe |
| amadeus_flight_order_id | String | nullable, UNIQUE | reference Amadeus |
| status | String | nullable | CONFIRMED / CANCELLED |
| booking_reference | String | nullable | PNR |
| payment_id | String | nullable | charge Stripe |
| ticket_url | String | nullable | URL e-ticket |
| amadeus_create_order_request | JSON | NOT NULL | request payload |
| amadeus_create_order_response | JSON | nullable | response payload |
| created_at / updated_at | DateTime(tz) | server_default now() | |

### ManualFlight (`manual_flights`)

Vol saisi a la main par l'utilisateur (hors Amadeus). Sert quand l'utilisateur a deja un billet ou un trajet interne (train, bus assimile).

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| flight_number | String | NOT NULL | |
| airline | String | nullable | |
| departure_airport / arrival_airport | String | nullable | IATA ou nom libre |
| departure_date / arrival_date | DateTime(tz) | nullable | |
| price | Numeric(12,2) | nullable | |
| currency | String | nullable, default "EUR" | |
| notes | String | nullable | |
| flight_type | String | NOT NULL, default "MAIN" | MAIN / INTERNAL |
| validation_status | String | NOT NULL, default "MANUAL" | meme enum |
| created_at / updated_at | DateTime(tz) | server_default now() | |

### BookingIntent (`booking_intents`)

Cle de voute de l'orchestration paiement Stripe + reservation Amadeus. La FSM est `INIT -> AUTHORIZED -> BOOKING_PENDING -> BOOKED -> CAPTURED` (chemin nominal) avec branches `FAILED / CANCELLED / PAYMENT_CAPTURE_FAILED`.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | FK users.id, NOT NULL, INDEX | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| type | String | NOT NULL | "flight" (seul type aujourd'hui) |
| status | String | NOT NULL, INDEX | enum BookingIntentStatus |
| amount | Numeric(10,2) | NOT NULL | total a debiter |
| currency | String(3) | NOT NULL | |
| selected_offer_type | String | nullable | "flight_offer" |
| selected_offer_id | UUID | nullable | flight_offers.id |
| selected_offer_payload_hash | String | nullable | detection drift offer |
| stripe_payment_intent_id | String | nullable | |
| stripe_charge_id | String | nullable | |
| amadeus_order_id | String | nullable | |
| last_error | JSON | nullable | dernier echec (Stripe ou Amadeus) |
| raw | JSON | nullable | metadata, idempotency keys |
| created_at / updated_at | DateTime(tz) | server_default now() | |

### DeviceToken (`device_tokens`)

Token FCM (Firebase Cloud Messaging) d'un appareil utilisateur. Le champ `locale` permet aux jobs background d'envoyer des push localisees sans contexte de requete.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | FK users.id, NOT NULL, INDEX | |
| fcm_token | String | UNIQUE, NOT NULL | rotate cote client |
| platform | String | nullable | ios / android |
| locale | String | nullable | fr / en |
| created_at / updated_at | DateTime(tz) | server_default now() | |

### TravelerProfile (`traveler_profiles`)

Profil 1:1 avec l'utilisateur, rempli a l'onboarding ou en profil. Sert le LLM pour personnaliser les recommandations.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | FK users.id, UNIQUE, NOT NULL, INDEX | 1:1 |
| travel_types | JSON | nullable | liste de types (culture, nature, ...) |
| travel_style | String | nullable | RELAX / ADVENTURE / ... |
| budget | String | nullable | BACKPACKER / COMFORTABLE / PREMIUM / NO_LIMIT |
| companions | String | nullable | SOLO / COUPLE / FAMILY / FRIENDS |
| medical_constraints | String | nullable | ajoute migr 0016 |
| travel_frequency | String | nullable | ajoute migr 0022 |
| is_completed | Boolean | NOT NULL, default false | onboarding flag |
| created_at / updated_at | DateTime(tz) | server_default now() | |

### StripeEvent (`stripe_events`)

Idempotence des webhooks Stripe : on stocke chaque event recu (unicite sur `stripe_event_id`) avant traitement pour rejouer si besoin.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| stripe_event_id | String | UNIQUE, NOT NULL | de-dup webhook |
| type | String | NOT NULL | "payment_intent.succeeded" etc. |
| livemode | Boolean | nullable | test vs prod |
| payload | JSON | NOT NULL | event complet Stripe |
| received_at | DateTime(tz) | server_default now() | |
| booking_intent_id | UUID | FK booking_intents.id, nullable | si rattachable |
| processed_at | DateTime(tz) | nullable | success timestamp |
| processing_error | JSON | nullable | erreur si echec |

### AmadeusApiLog (`amadeus_api_logs`)

Audit trail des appels API Amadeus. Tres verbose, candidat naturel a une politique de retention (cf. "Ce qu'il manque").

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, nullable, INDEX | |
| booking_intent_id | UUID | FK booking_intents.id, nullable, INDEX | |
| api_name | String | NOT NULL, INDEX | "flight_search" / "flight_create_order" etc. |
| http_method | String | NOT NULL | |
| path | String | NOT NULL | |
| request_headers / request_body | JSON | nullable | |
| response_status | Integer | nullable | |
| response_headers / response_body | JSON | nullable | |
| duration_ms | Integer | nullable | latence observee |
| created_at | DateTime(tz) | server_default now() | |

### PendingInvite (`pending_invites`)

Invitation de partage vers un email non encore inscrit (migr 0025). Claimee a l'inscription par `UserCreationService.create_and_setup_user()`.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX | |
| email | String | NOT NULL, INDEX | |
| role | String | NOT NULL, default "VIEWER" | |
| token | String | UNIQUE, NOT NULL, INDEX | secret claim url |
| message | String | nullable | message libre de l'inviteur |
| invited_by | UUID | FK users.id, NOT NULL | |
| created_at | DateTime(tz) | server_default now() | |
| expires_at | DateTime(tz) | NOT NULL | typiquement 14 jours |

Contrainte unique : `uq_pending_invites_trip_email (trip_id, email)`.

### AuditLog (`audit_logs`)

Trace des mutations admin (back-office) pour la conformite. Couvre USER, TRIP, FEATURE_FLAG. Ajoute migr 0027.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| actor_id | UUID | FK users.id, NOT NULL | admin auteur |
| action | String(50) | NOT NULL | CREATE / UPDATE / DELETE / BAN / ... |
| entity_type | String(50) | NOT NULL | USER / TRIP / ... |
| entity_id | UUID | NOT NULL | id de l'entite touchee |
| diff_json | JSON | nullable | { field: { old, new } } |
| metadata_ | JSON | nullable | IP, user agent (mappe colonne `metadata`) |
| created_at | DateTime(tz) | server_default now() | |

Index : `idx_audit_logs_entity (entity_type, entity_id)`, `idx_audit_logs_actor`, `idx_audit_logs_created`.

### DestinationCatalog (`destination_catalog`)

Catalogue canonique des destinations grounding le RAG post-trip W3. Stocke un embedding 1024 floats en JSONB pour eviter de dependre de `pgvector` a notre echelle.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK, server_default `gen_random_uuid()` | |
| iata | String(3) | UNIQUE, NOT NULL | cle metier |
| city / country | String | NOT NULL | |
| country_code | String(2) | NOT NULL | ISO 3166-1 alpha-2 |
| region | String | NOT NULL | Europe / Asia / ... |
| types_tags | String | NOT NULL | CSV (culture, nature, ...) |
| summary | String | NOT NULL | text grounding LLM |
| avg_summer_temp_c / avg_winter_temp_c | Integer | NOT NULL | bandes climatiques |
| daily_budget_eur | Integer | NOT NULL | repere indicatif |
| typical_duration_days | Integer | NOT NULL | |
| embedding | JSONB | NOT NULL | 1024 floats BGE-M3 |
| embedding_model | String | NOT NULL | versionning embedding |
| created_at / updated_at | DateTime(tz) | server_default now() | |

Index : `ix_destination_catalog_iata`.

### Booking (`bookings`) -- DEPRECATED

Ancien modele de reservation, remplace par le couple `BookingIntent` + `FlightOrder`. Les colonnes timestamps sont mappees vers `createdAt` / `updatedAt` (camelCase, heritage Prisma) -- divergence intentionnellement conservee pour ne pas casser les lignes existantes.

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | FK users.id, NOT NULL | non-indexe |
| amadeus_order_id | String | NOT NULL | |
| flight_offers | JSON | NOT NULL | snapshot offer |
| status | String | NOT NULL, default "CONFIRMED" | PENDING / CONFIRMED / CANCELLED |
| price_total | Float | NOT NULL | Float -- legacy |
| currency | String | NOT NULL | |
| createdAt | DateTime(tz) | server_default now() | mappe `created_at` cote Python |
| updatedAt | DateTime(tz) | onupdate now() | idem |

## Relations

```
users (1) ----< trips (1) ----< activities
  |                |
  |                |----< accommodations
  |                |----< baggage_items
  |                |----< budget_items (source_id polymorphique)
  |                |----< trip_travelers
  |                |----< manual_flights
  |                |----< feedbacks                (UNIQUE trip_id+user_id)
  |                |----< trip_shares              (UNIQUE trip_id+user_id)
  |                |----< pending_invites          (UNIQUE trip_id+email)
  |                |----< flight_searches (1) ----< flight_offers (1) ----< flight_orders
  |                |----< booking_intents (1) ----- flight_orders (1:1 via UNIQUE FK)
  |                |                       (1) ----< stripe_events
  |                |----< notifications (FK nullable)
  |                |----< amadeus_api_logs (FK nullable)
  |
  |----< refresh_tokens
  |----< device_tokens
  |---- traveler_profiles (1:1 via UNIQUE user_id)
  |----< booking_intents
  |----< notifications
  |----< feedbacks
  |----< trip_shares (en tant qu'invite)
  |----< pending_invites (en tant qu'invited_by)
  |----< audit_logs (en tant qu'actor_id)
  |----< bookings (DEPRECATED)

destination_catalog (autonome -- RAG W3)
```

Cascades :

- Toutes les FK depuis `trips` vers ses enfants utilisent `cascade="all, delete-orphan"` cote ORM. Suppression d'un trip = hard delete cascadant.
- `trip_shares.user`, `notifications.user`, `feedbacks.user` ne portent pas de cascade -- on garde la trace si l'utilisateur invite est supprime (a anonymiser cote service).
- `stripe_events` et `flight_orders` peuvent referencer un `booking_intent` nullable (on garde l'event meme si le BI n'a pas pu etre cree).

## Indexes

Index declares explicitement (au-dela des PK et des UNIQUE constraints qui en creent automatiquement) :

| Table | Index | Type |
|---|---|---|
| users | email | UNIQUE + INDEX |
| users | stripe_customer_id | INDEX |
| users | stripe_subscription_id | INDEX |
| trips | user_id | INDEX |
| activities | trip_id | INDEX |
| accommodations | trip_id | INDEX |
| baggage_items | trip_id | INDEX |
| budget_items | trip_id | INDEX |
| budget_items | (source_type, source_id) | INDEX composite `ix_budget_items_source` |
| trip_travelers | trip_id | INDEX |
| trip_shares | trip_id | INDEX |
| trip_shares | user_id | INDEX |
| trip_shares | (trip_id, user_id) | UNIQUE `uq_trip_shares_trip_user` |
| pending_invites | trip_id | INDEX |
| pending_invites | email | INDEX |
| pending_invites | token | UNIQUE + INDEX |
| pending_invites | (trip_id, email) | UNIQUE `uq_pending_invites_trip_email` |
| flight_searches | trip_id | INDEX |
| flight_offers | flight_search_id | INDEX |
| flight_offers | trip_id | INDEX |
| flight_orders | booking_intent_id | UNIQUE |
| flight_orders | amadeus_flight_order_id | UNIQUE |
| booking_intents | user_id | INDEX |
| booking_intents | trip_id | INDEX |
| booking_intents | status | INDEX |
| notifications | user_id | INDEX |
| notifications | trip_id | INDEX |
| device_tokens | fcm_token | UNIQUE |
| device_tokens | user_id | INDEX |
| refresh_tokens | user_id | INDEX |
| refresh_tokens | token | UNIQUE + INDEX |
| feedbacks | trip_id | INDEX |
| feedbacks | user_id | INDEX |
| feedbacks | (trip_id, user_id) | UNIQUE `uq_feedbacks_trip_user` |
| traveler_profiles | user_id | UNIQUE + INDEX |
| amadeus_api_logs | trip_id | INDEX |
| amadeus_api_logs | booking_intent_id | INDEX |
| amadeus_api_logs | api_name | INDEX |
| stripe_events | stripe_event_id | UNIQUE |
| destination_catalog | iata | UNIQUE + INDEX `ix_destination_catalog_iata` |
| audit_logs | (entity_type, entity_id) | INDEX `idx_audit_logs_entity` |
| audit_logs | actor_id | INDEX `idx_audit_logs_actor` |
| audit_logs | created_at | INDEX `idx_audit_logs_created` |

Indexes manquants identifies : `flight_orders.flight_offer_id`, `bookings.user_id` (table deprecated).

## Pool tuning

Configure dans `src/config/database.py` au `create_engine()` :

```python
engine = create_engine(
    database_url,
    pool_size=20,
    max_overflow=10,
    pool_timeout=30,
    pool_recycle=1800,
    pool_pre_ping=True,
    echo=False,
)
```

Justification de chaque parametre :

- **`pool_size=20`** -- 20 connexions persistantes par worker. Le defaut SQLAlchemy (5) est trop bas pour le fan-out qu'on fait sur les endpoints `/home` et `/trips/{id}` (chaque page agrege 5 a 10 requetes en parallele).
- **`max_overflow=10`** -- jusqu'a 10 connexions supplementaires en burst avant de bloquer. Couvre les pics SSE et les jobs schedules concurrents.
- **`pool_timeout=30`** -- bloque au maximum 30s en attente d'une connexion libre. Au-dela on prefere lever une 503 que de laisser un client poireauter indefiniment.
- **`pool_recycle=1800`** -- recycle les connexions toutes les 30 minutes pour eviter de servir une connexion tuee par un idle-timeout amont (NAT, PGBouncer, RDS).
- **`pool_pre_ping=True`** -- `SELECT 1` avant chaque checkout pour fail fast sur sockets cassees plutot que de servir des 500 mysterieuses.
- **`echo=False`** -- pas de log SQL en prod (passer a `True` ponctuellement en dev pour debugger).

La session est exposee via `sessionmaker(autocommit=False, autoflush=False, bind=engine)` et la dependency FastAPI `get_db()` fait `try / yield / finally db.close()`.

## Migrations Alembic

### Configuration

- INI : `api/alembic.ini` -- URL par defaut `postgresql://localhost/bagtrip`, surchargee par `env.py`.
- Env : `api/alembic/env.py` -- importe tous les modeles via `import src.models`, surcharge `sqlalchemy.url` avec `settings.DATABASE_URL` (apres `clean_database_url()`).
- Mode online par defaut, `NullPool` (Alembic n'a pas besoin de pool partage).

### Workflow

```bash
# Nouvelle revision (toujours via make, jamais autogenerate)
make db-revision MSG="add foo to trips"

# Apply jusqu'au dernier head
uv run alembic upgrade head            # local
# ou dans le container :
make db-reset                          # drop + upgrade + seeds

# Rollback d'une revision
uv run alembic downgrade -1
```

Important :

- **Pas d'autogenerate** -- les migrations sont ecrites a la main. SQLAlchemy 2.0 + types Postgres natifs (UUID, JSONB) generent souvent des diffs faussement positifs avec `--autogenerate`.
- **Pas de f-string SQL** -- toujours `op.add_column` / `op.execute(text(...))` avec bind params. Le linter bandit bloque les f-strings dans les revisions.
- **L'upgrade est lance au boot** depuis le `Dockerfile` (`alembic upgrade head` dans l'entrypoint) avant le `uvicorn`. Le commentaire dans `main.py` lifespan rappelle "Schema managed by: alembic upgrade head".

### Revisions recentes

Tete actuelle : `0036_notification_i18n_jsonb`. Historique des migrations sprint 4+5 :

| Revision | Description |
|---|---|
| 0008 | Add feedbacks table |
| 0009 | Add budget_item source tracking (source_type, source_id) |
| 0010 | Add notifications and device_tokens |
| 0011 | Add user plan and quotas |
| 0012 | Cleanup data models |
| 0013 | Add flight_order payment_id + ticket_url |
| 0014 | Create manual_flights |
| 0015 | Add activity validation_status |
| 0016 | Add medical_constraints to traveler_profiles |
| 0017 | Unify activity and baggage categories |
| 0018 | Add notification type TRIP_STARTED |
| 0019 | Add trip date_mode |
| 0020 | Add ai_experience_rating to feedbacks |
| 0021 | Accommodation check_in/check_out to DateTime |
| 0022 | Add travel_frequency to traveler_profiles |
| 0023 | Add destination_timezone to trips |
| 0024 | Add is_done to activities |
| 0025 | Create pending_invites |
| 0026 | Add user ban_at / ban_reason / deleted_at |
| 0027 | Create audit_logs |
| 0028 | Add tracking + validation_status (accommodations / manual_flights) |
| 0029 | Split trip.budget_total -> budget_target / budget_estimated / budget_actual |
| 0030 | Add currency to trips + budget_items |
| 0031 | Backfill budget_item.source_type |
| 0032 | activities.date nullable |
| 0033 | Add budget_item.validation_status |
| 0034 | Create destination_catalog (RAG W3) |
| 0035 | Drop activity/budget_item duplication |
| 0036 | notification.data en JSONB pour i18n |

Migration speciale : `1fb93ffa52b4_add_password_reset_fields` (avant la numerotation `0008+`).

## Seeds

Seuls deux seeds tournent au boot, declenches dans le lifespan FastAPI (`src/main.py`) :

- **Admins dev** -- `src/seeds/create_admin.py::create_default_admin()` cree (ou upgrade) cinq comptes admin en environnement `NODE_ENV=development` :
  - `yanis@bagtrip.fr`, `mickael@bagtrip.fr`, `jean@bagtrip.fr`, `aurelien@bagtrip.fr`, `adrien@bagtrip.fr`.
  - Idempotent : si l'utilisateur existe deja, on le promote au plan `ADMIN`, sinon on le cree avec bcrypt.
  - En prod, lit `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_FULL_NAME` depuis l'env. Si `ADMIN_PASSWORD` est absent, le seed est skip silencieusement.
- **Produits Stripe** -- `StripeProductsService.initialize_products()` synchronise les SKU premium au boot (cf. `documentations/architecture/data-flow-rgpd.md`).

Le seed du catalogue de destinations RAG est externe au boot (responsabilite de `src/services/destination_catalog_bootstrap.py` -- cf. commentaire en tete de migration 0034).

Il n'y a pas de seed metier (pas de trip / activite / hotel de demonstration).

## Eager loading

Les modeles ne declarent **aucun `lazy=`** sur les relations -- defaut SQLAlchemy = lazy load = N+1 si on n'opt-in pas explicitement. La regle est donc :

> Tout endpoint qui itere sur une relation doit `selectinload` ou `joinedload` explicitement au site de la query.

Patterns utilises en pratique (cf. `src/jobs/notification_job.py`) :

```python
from sqlalchemy.orm import joinedload, selectinload

# Trip + ses collections enfants
trips = (
    db.query(Trip)
    .options(
        selectinload(Trip.activities),
        selectinload(Trip.baggage_items),
        selectinload(Trip.shares),
    )
    .filter(Trip.status == TripStatus.ONGOING)
    .all()
)

# FlightOrder -> FlightOffer (many-to-one, joinedload)
orders = (
    db.query(FlightOrder)
    .options(joinedload(FlightOrder.flight_offer))
    .all()
)

# Chainage : Activity -> Trip -> Shares (pour les notifs aux co-voyageurs)
activities = (
    db.query(Activity)
    .options(selectinload(Activity.trip).selectinload(Trip.shares))
    .all()
)
```

Regle de selection :

- **`selectinload`** : collections (one-to-many, many-to-many). Une seule requete IN supplementaire, scale bien.
- **`joinedload`** : associations many-to-one ou one-to-one. Pas de requete supplementaire, mais cartesien si combine a une autre collection (eviter `joinedload(Trip.activities) + joinedload(Trip.shares)`).

Endpoints "hot" qui doivent imperativement eager-load :

- `GET /home` -- liste des trips avec activites du jour, completion, partages.
- `GET /trips/{id}` -- hub trip detail (8+ collections aggregees).
- `GET /trips/{id}/budget/summary` -- budget items + flight_orders + accommodations pour calcul total.
- Schedulers `notification_job`, `trip_status_job`, `plan_expiration_job` -- iterent sur tous les trips actifs.

Un endpoint qui itere sur `trip.activities` sans eager loading = N+1 a corriger systematiquement.

## Ce qu'il manque

| Element | Description | Priorite |
|---|---|---|
| Soft delete non uniforme | `trips.archived_at`, `users.deleted_at`, `users.banned_at` existent mais les sous-entites (activities, accommodations, ...) sont en hard delete cascadant. Pas de moyen de "annuler" la suppression d'un trip. | P1 |
| Index FK manquants | `flight_orders.flight_offer_id` n'a pas d'INDEX explicite (juste FK). `bookings.user_id` non plus (table deprecated mais encore lue). | P1 |
| Table `bookings` deprecated | Modele `Booking` toujours mappe, colonnes camelCase `createdAt` / `updatedAt` heritage Prisma. A purger une fois les routes consommatrices migrees. | P2 |
| Pas de purge `refresh_tokens` | Aucun job ne nettoie les tokens expires (`expires_at < now()` OR `revoked = true`). Table grossit indefiniment. | P2 |
| Pas de purge `amadeus_api_logs` | Audit verbose stocke a vie. Politique 30-90 jours souhaitable. | P2 |
| Pas de purge `stripe_events` | Idempotence Stripe = OK pour le rejeu court terme, mais payload complet conserve eternellement. | P3 |
| Autogenerate Alembic non utilise | Migrations ecrites a la main (pas de Postgres local automatique). Sujet a oublis de schema drift -- compense par les tests CI mais fragile. | P2 |
| Pas de migrations testees en CI | Pas de pipeline qui fait `upgrade head` puis `downgrade -1` puis `upgrade head` pour valider la reversibilite. | P2 |
| `pgvector` non installe | Embedding RAG en JSONB -- OK a notre echelle (~40 destinations) mais ne scale pas au-dela de quelques milliers de rows. Migration vers `pgvector` necessaire pour V2. | P3 |
| Pas de partition par date | `amadeus_api_logs` et `notifications` profiteraient d'une partition mensuelle pour purger plus facilement. | P3 |
